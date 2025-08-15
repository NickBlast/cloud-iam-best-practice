#!/usr/bin/env python3
"""
Azure RBAC Roles and Assignments Exporter

Exports Azure role definitions and assignments across Management Groups, Subscriptions, 
and Resource Groups with inherited flag detection, principal resolution, and structured logging.

Supports large tenant safety rails, redaction, and various output formats.
"""

import argparse
import csv
import json
import sys
import time
import logging
import subprocess
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Dict, Any, Optional, Set, Tuple
import re

# Azure SDK imports (use dynamic import to avoid static analyzer "could not be resolved" errors)
try:
    import importlib

    _mod = importlib.import_module('azure.identity')
    DefaultAzureCredential = getattr(_mod, 'DefaultAzureCredential')
    AzureCliCredential = getattr(_mod, 'AzureCliCredential')

    _mod = importlib.import_module('azure.mgmt.authorization')
    AuthorizationManagementClient = getattr(_mod, 'AuthorizationManagementClient')

    _mod = importlib.import_module('azure.mgmt.resource')
    ResourceManagementClient = getattr(_mod, 'ResourceManagementClient')

    _mod = importlib.import_module('azure.mgmt.managementgroups')
    ManagementGroupsAPI = getattr(_mod, 'ManagementGroupsAPI')

    _mod = importlib.import_module('azure.core.exceptions')
    ClientAuthenticationError = getattr(_mod, 'ClientAuthenticationError')
    HttpResponseError = getattr(_mod, 'HttpResponseError')

    _mod = importlib.import_module('azure.core.pipeline.policies')
    RetryPolicy = getattr(_mod, 'RetryPolicy')

except Exception as e:
    print(f"Missing required Azure SDK packages: {e}")
    print("Install with: pip install -r requirements.txt")
    sys.exit(1)

# Optional imports
try:
    import openpyxl
    HAS_OPENPYXL = True
except ImportError:
    # Ensure openpyxl is always defined to avoid "possibly unbound" errors in static analysis
    openpyxl = None
    HAS_OPENPYXL = False

try:
    import importlib
    _mg = importlib.import_module('msgraph')
    GraphServiceClient = getattr(_mg, 'GraphServiceClient')
    try:
        _mg_gen = importlib.import_module('msgraph.generated.users.users_request_builder')
        UsersRequestBuilder = getattr(_mg_gen, 'UsersRequestBuilder')
    except Exception:
        UsersRequestBuilder = None
    HAS_GRAPH = True
except Exception:
    HAS_GRAPH = False

# Import shared logging utilities
try:
    from scripts.common.python.logging_utils import init_logging, write_summary, new_output_paths, now_utc_iso
except ImportError:
    # Fallback if running from script directory
    import sys
    import os
    sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
    from common.python.logging_utils import init_logging, write_summary, new_output_paths, now_utc_iso

# Constants
DEFAULT_MAX_CONCURRENCY = 4
DEFAULT_MARKDOWN_TOP = 200
DEFAULT_GROUP_MEMBERS_TOP = 500
LARGE_SUBSCRIPTION_THRESHOLD = 25
LARGE_RESOURCE_GROUP_THRESHOLD = 200

# Global cache for principal lookups
principal_cache = {}


def setup_argument_parser():
    """Setup command line argument parser."""
    parser = argparse.ArgumentParser(
        description="Export Azure RBAC roles and assignments",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --subscriptions sub1,sub2 --redact
  %(prog)s --discover-subscriptions --confirm-large-scan
  %(prog)s --traverse-management-groups --no-resolve-principals
        """
    )
    
    # Core parameters
    parser.add_argument('--subscriptions', nargs='+', 
                       help='Target subscription IDs (comma-separated or repeatable)')
    parser.add_argument('--include-resources', action='store_true',
                       help='Include resource-level assignments (off by default)')
    parser.add_argument('--expand-group-members', action='store_true',
                       help='Expand group members (extreme fan-out, use with caution)')
    parser.add_argument('--redact', action='store_true',
                       help='Mask UPNs/AppIds (incl. expanded members)')
    parser.add_argument('--markdown-top', type=int, default=DEFAULT_MARKDOWN_TOP,
                       help=f'Max rows for Markdown export (default: {DEFAULT_MARKDOWN_TOP})')
    parser.add_argument('--no-resolve-principals', action='store_true',
                       help='Skip principal name resolution (speeds up large runs)')
    parser.add_argument('--confirm-large-scan', action='store_true',
                       help='Required when large tenant thresholds are hit')
    parser.add_argument('--output-path', 
                       help='Output directory path (default: deterministic timestamped path)')
    parser.add_argument('--safe-mode', action='store_true', default=True,
                       help='Read-only mode (default: true)')
    parser.add_argument('--max-concurrency', type=int, default=DEFAULT_MAX_CONCURRENCY,
                       help=f'Max parallel calls (default: {DEFAULT_MAX_CONCURRENCY})')
    parser.add_argument('--limit', type=int,
                       help='Process first N scopes/assignments for smoke tests')
    
    # Discovery parameters
    parser.add_argument('--discover-subscriptions', action='store_true',
                       help='Discover subscriptions (off by default)')
    parser.add_argument('--traverse-management-groups', action='store_true',
                       help='Traverse management groups (off by default)')
    
    # Group expansion parameters
    parser.add_argument('--group-members-top', type=int, default=DEFAULT_GROUP_MEMBERS_TOP,
                       help=f'Hard cap per group members (default: {DEFAULT_GROUP_MEMBERS_TOP})')
    parser.add_argument('--group-membership-mode', choices=['direct', 'transitive'], 
                       default='direct',
                       help='Group membership mode (default: direct)')
    
    # Output format
    parser.add_argument('--json', action='store_true',
                       help='Emit JSON exports (newline-delimited or array)')
    
    parser.add_argument('--bootstrap', action='store_true',
                       help='Run bootstrap prerequisites check before execution')
    
    return parser


def validate_arguments(args):
    """Validate command line arguments and check for conflicts."""
    # Check if discovery is required but not enabled
    if not args.subscriptions and not args.discover_subscriptions and not args.traverse_management_groups:
        print("ERROR: Must specify --subscriptions, --discover-subscriptions, or --traverse-management-groups")
        print("       This prevents accidental tenant-wide enumeration.")
        sys.exit(1)
    
    # Check transitive mode requires confirmation
    if args.group_membership_mode == 'transitive' and not args.confirm_large_scan:
        print("ERROR: --group-membership-mode transitive requires --confirm-large-scan")
        sys.exit(1)
    
    # Parse comma-separated subscriptions
    if args.subscriptions:
        expanded_subs = []
        for sub in args.subscriptions:
            expanded_subs.extend(sub.split(','))
        args.subscriptions = [sub.strip() for sub in expanded_subs if sub.strip()]
    
    return args


def preflight_check(logger):
    """Perform preflight checks for Azure authentication and required modules."""
    logger.info("Performing preflight checks...")
    
    # Test credential acquisition
    credential = None
    credential_type = None
    
    try:
        # Try DefaultAzureCredential first
        credential = DefaultAzureCredential()
        # Test token acquisition
        token = credential.get_token("https://management.azure.com/.default")
        credential_type = "DefaultAzureCredential"
        logger.info("Authentication successful with DefaultAzureCredential")
    except Exception as e1:
        logger.warning(f"DefaultAzureCredential failed: {e1}")
        try:
            # Fallback to AzureCliCredential
            credential = AzureCliCredential()
            token = credential.get_token("https://management.azure.com/.default")
            credential_type = "AzureCliCredential"
            logger.info("Authentication successful with AzureCliCredential")
        except Exception as e2:
            logger.error(f"AzureCliCredential failed: {e2}")
            logger.error("Authentication failed. Please run 'az login' or ensure SSO is configured.")
            return None, None
    
    # Detect proxy settings
    import os
    https_proxy = os.environ.get('HTTPS_PROXY') or os.environ.get('https_proxy')
    http_proxy = os.environ.get('HTTP_PROXY') or os.environ.get('http_proxy')
    if https_proxy or http_proxy:
        logger.info(f"Proxy detected: HTTPS_PROXY={https_proxy}, HTTP_PROXY={http_proxy}")
    
    return credential, credential_type


def get_management_groups(credential, logger) -> List[Dict[str, Any]]:
    """Get management groups with error handling."""
    try:
        mg_client = ManagementGroupsAPI(credential)
        mg_list = []
        
        # List management groups
        for mg in mg_client.management_groups.list():
            mg_list.append({
                'id': mg.id,
                'name': mg.name,
                'display_name': mg.display_name,
                'type': mg.type
            })
        
        logger.info(f"Found {len(mg_list)} management groups")
        return mg_list
    except Exception as e:
        logger.warning(f"Failed to list management groups: {e}")
        return []


def get_subscriptions(credential, logger, subscription_ids: Optional[List[str]] = None) -> List[Dict[str, Any]]:
    """Get subscriptions with optional filtering."""
    try:
        resource_client = ResourceManagementClient(credential, subscription_id=None)
        sub_list = []
        
        # List subscriptions
        for sub in resource_client.subscriptions.list():
            if subscription_ids and sub.subscription_id not in subscription_ids:
                continue
                
            sub_list.append({
                'id': sub.id,
                'subscription_id': sub.subscription_id,
                'display_name': sub.display_name,
                'state': sub.state.value if hasattr(sub.state, 'value') else str(sub.state)
            })
        
        logger.info(f"Found {len(sub_list)} subscriptions")
        return sub_list
    except Exception as e:
        logger.warning(f"Failed to list subscriptions: {e}")
        return []


def get_resource_groups(credential, subscription_id: str, logger) -> List[Dict[str, Any]]:
    """Get resource groups for a subscription."""
    try:
        resource_client = ResourceManagementClient(credential, subscription_id=subscription_id)
        rg_list = []
        
        for rg in resource_client.resource_groups.list():
            rg_list.append({
                'id': rg.id,
                'name': rg.name,
                'location': rg.location,
                'subscription_id': subscription_id
            })
        
        logger.debug(f"Found {len(rg_list)} resource groups in subscription {subscription_id}")
        return rg_list
    except Exception as e:
        logger.warning(f"Failed to list resource groups for {subscription_id}: {e}")
        return []


def get_role_definitions(credential, scope: str, logger) -> List[Dict[str, Any]]:
    """Get role definitions for a scope."""
    try:
        auth_client = AuthorizationManagementClient(credential, scope)
        role_defs = []
        
        for role_def in auth_client.role_definitions.list(scope=scope):
            role_defs.append({
                'roleDefinitionName': role_def.role_name,
                'roleDefinitionId': role_def.id,
                'isCustom': not role_def.role_type,
                'description': role_def.description or '',
                'permissionsCount': len(role_def.permissions) if role_def.permissions else 0,
                'assignableScopes': ';'.join(role_def.assignable_scopes) if role_def.assignable_scopes else ''
            })
        
        logger.debug(f"Found {len(role_defs)} role definitions at scope {scope}")
        return role_defs
    except Exception as e:
        logger.warning(f"Failed to list role definitions at {scope}: {e}")
        return []


def get_role_assignments(credential, scope: str, logger, include_inherited: bool = True) -> List[Dict[str, Any]]:
    """Get role assignments for a scope."""
    try:
        auth_client = AuthorizationManagementClient(credential, scope)
        assignments = []
        
        # List role assignments
        for assignment in auth_client.role_assignments.list_for_scope(
            scope=scope, 
            filter=None,
            include_inherited=include_inherited
        ):
            # Determine scope type
            scope_type = 'Unknown'
            subscription_id = ''
            resource_group = ''
            
            if '/providers/Microsoft.Management/managementGroups/' in scope:
                scope_type = 'ManagementGroup'
            elif '/subscriptions/' in scope and '/resourceGroups/' in scope:
                scope_type = 'ResourceGroup'
                # Extract subscription ID and RG name
                parts = scope.split('/subscriptions/')
                if len(parts) > 1:
                    sub_part = parts[1].split('/resourceGroups/')
                    subscription_id = sub_part[0]
                    resource_group = sub_part[1] if len(sub_part) > 1 else ''
            elif '/subscriptions/' in scope:
                scope_type = 'Subscription'
                parts = scope.split('/subscriptions/')
                if len(parts) > 1:
                    subscription_id = parts[1].split('/')[0]
            
            assignments.append({
                'scope': scope,
                'scopeType': scope_type,
                'subscriptionId': subscription_id,
                'resourceGroup': resource_group,
                'roleDefinitionId': assignment.role_definition_id,
                'roleDefinitionName': '',  # Will be filled later
                'assignmentId': assignment.id,
                'principalId': assignment.principal_id,
                'principalType': str(assignment.principal_type) if assignment.principal_type else 'Unknown',
                'principalDisplayName': '',  # Will be filled later
                'principalUPNOrAppId': '',   # Will be filled later
                'inherited': assignment.additional_properties.get('inherited', False) if assignment.additional_properties else False,
                'condition': assignment.condition or '',
                'conditionVersion': assignment.condition_version or '',
                'createdOn': assignment.created_on.isoformat() if assignment.created_on else ''
            })
        
        logger.debug(f"Found {len(assignments)} role assignments at scope {scope}")
        return assignments
    except Exception as e:
        logger.warning(f"Failed to list role assignments at {scope}: {e}")
        return []


def resolve_principal(credential, principal_id: str, principal_type: str, logger, 
                     no_resolve: bool = False, redact: bool = False) -> Tuple[str, str]:
    """Resolve principal display name and UPN/AppId."""
    global principal_cache
    
    # Check cache first
    if principal_id in principal_cache:
        return principal_cache[principal_id]
    
    # If no resolution requested, return IDs only
    if no_resolve:
        display_name = principal_id
        upn_or_app_id = principal_id
        if redact:
            display_name = '[REDACTED]'
            upn_or_app_id = '[REDACTED]'
        result = (display_name, upn_or_app_id)
        principal_cache[principal_id] = result
        return result
    
    display_name = principal_id
    upn_or_app_id = principal_id
    
    try:
        if HAS_GRAPH and principal_type in ['User', 'ServicePrincipal']:
            # Try to resolve using Microsoft Graph
            graph_client = GraphServiceClient(credential)
            
            if principal_type == 'User':
                user = graph_client.users.by_user_id(principal_id).get()
                display_name = user.display_name or principal_id
                upn_or_app_id = user.user_principal_name or principal_id
            elif principal_type == 'ServicePrincipal':
                app = graph_client.applications.by_application_id(principal_id).get()
                display_name = app.display_name or principal_id
                upn_or_app_id = app.app_id or principal_id
    except Exception as e:
        logger.debug(f"Failed to resolve principal {principal_id}: {e}")
        # Keep IDs as fallback
    
    # Apply redaction if requested
    if redact:
        display_name = '[REDACTED]'
        upn_or_app_id = '[REDACTED]'
    
    result = (display_name, upn_or_app_id)
    principal_cache[principal_id] = result
    return result


def expand_group_members(credential, group_id: str, logger, top: int = 500, 
                        mode: str = 'direct') -> List[Dict[str, Any]]:
    """Expand group members with optional transitive expansion."""
    members = []
    
    if not HAS_GRAPH:
        logger.warning("Microsoft Graph SDK not available for group expansion")
        return members
    
    try:
        graph_client = GraphServiceClient(credential)
        
        if mode == 'direct':
            # Get direct members
            response = graph_client.groups.by_group_id(group_id).members.get()
            if response and hasattr(response, 'value'):
                for member in response.value[:top]:
                    members.append({
                        'memberPrincipalId': member.id,
                        'memberType': str(member.additional_data.get('@odata.type', 'Unknown')).replace('#microsoft.graph.', ''),
                        'memberDisplayName': member.display_name or member.id,
                        'memberUPN': member.user_principal_name if hasattr(member, 'user_principal_name') else ''
                    })
        elif mode == 'transitive':
            # Get transitive members (requires additional permissions)
            response = graph_client.groups.by_group_id(group_id).transitive_members.get()
            if response and hasattr(response, 'value'):
                for member in response.value[:top]:
                    members.append({
                        'memberPrincipalId': member.id,
                        'memberType': str(member.additional_data.get('@odata.type', 'Unknown')).replace('#microsoft.graph.', ''),
                        'memberDisplayName': member.display_name or member.id,
                        'memberUPN': member.user_principal_name if hasattr(member, 'user_principal_name') else ''
                    })
    except Exception as e:
        logger.warning(f"Failed to expand group {group_id}: {e}")
    
    return members


def check_large_tenant_thresholds(subscriptions: List[Dict], resource_groups_per_sub: Dict[str, List], 
                                 args, logger) -> bool:
    """Check if large tenant thresholds are exceeded and require confirmation."""
    sub_count = len(subscriptions)
    total_rg_count = sum(len(rgs) for rgs in resource_groups_per_sub.values())
    
    logger.info(f"Tenant size: {sub_count} subscriptions, {total_rg_count} resource groups")
    
    # Check thresholds
    if (sub_count > LARGE_SUBSCRIPTION_THRESHOLD or 
        total_rg_count > LARGE_RESOURCE_GROUP_THRESHOLD or
        (args.include_resources and not args.subscriptions)):
        
        if not args.confirm_large_scan:
            logger.warning("LARGE TENANT DETECTED - Safety rail triggered!")
            logger.warning(f"  Subscriptions: {sub_count} (threshold: {LARGE_SUBSCRIPTION_THRESHOLD})")
            logger.warning(f"  Resource Groups: {total_rg_count} (threshold: {LARGE_RESOURCE_GROUP_THRESHOLD})")
            logger.warning("  Use --confirm-large-scan to proceed with large tenant enumeration")
            return False
        else:
            logger.info("Large tenant scan confirmed by user")
    
    return True


def write_csv(data: List[Dict], filename: str, logger, redact: bool = False):
    """Write data to CSV file with UTF-8 BOM for Excel compatibility."""
    if not data:
        logger.warning(f"No data to write to {filename}")
        return
    
    try:
        # Apply redaction if requested
        if redact:
            redacted_data = []
            for row in data:
                redacted_row = row.copy()
                for key in ['principalUPNOrAppId', 'memberUPN']:
                    if key in redacted_row:
                        redacted_row[key] = '[REDACTED]'
                redacted_data.append(redacted_row)
            data = redacted_data
        
        # Write CSV with UTF-8 BOM for Excel compatibility
        with open(filename, 'w', newline='', encoding='utf-8-sig') as csvfile:
            if data:
                fieldnames = data[0].keys()
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames, quoting=csv.QUOTE_ALL)
                writer.writeheader()
                writer.writerows(data)
        
        logger.info(f"Wrote {len(data)} rows to {filename}")
    except Exception as e:
        logger.error(f"Failed to write CSV {filename}: {e}")


def write_xlsx(data: List[Dict], filename: str, logger, redact: bool = False):
    """Write data to XLSX file if openpyxl is available."""
    if not HAS_OPENPYXL:
        logger.debug("openpyxl not available, skipping XLSX export")
        return
    
    if not data:
        logger.warning(f"No data to write to {filename}")
        return
    
    try:
        # Apply redaction if requested
        if redact:
            redacted_data = []
            for row in data:
                redacted_row = row.copy()
                for key in ['principalUPNOrAppId', 'memberUPN']:
                    if key in redacted_row:
                        redacted_row[key] = '[REDACTED]'
                redacted_data.append(redacted_row)
            data = redacted_data
        
        # Ensure openpyxl has a Workbook attribute before calling it (guards static analyzers / runtime surprises)
        workbook_cls = getattr(openpyxl, 'Workbook', None)
        if workbook_cls is None:
            logger.error("openpyxl does not provide Workbook, skipping XLSX export")
            return
        
        wb = workbook_cls()
        ws = wb.active
        ws.title = "Data"
        
        if data:
            # Write headers
            headers = list(data[0].keys())
            ws.append(headers)
            
            # Write data rows
            for row in data:
                ws.append([row.get(header, '') for header in headers])
        
        wb.save(filename)
        logger.info(f"Wrote {len(data)} rows to {filename}")
    except Exception as e:
        logger.error(f"Failed to write XLSX {filename}: {e}")


def write_markdown(data: List[Dict], filename: str, logger, top: int = 200, redact: bool = False):
    """Write data to Markdown table."""
    if not data:
        logger.warning(f"No data to write to {filename}")
        return
    
    try:
        # Limit rows for Markdown
        limited_data = data[:top]
        
        # Apply redaction if requested
        if redact:
            redacted_data = []
            for row in limited_data:
                redacted_row = row.copy()
                for key in ['principalUPNOrAppId', 'memberUPN']:
                    if key in redacted_row:
                        redacted_row[key] = '[REDACTED]'
                redacted_data.append(redacted_row)
            limited_data = redacted_data
        
        with open(filename, 'w', encoding='utf-8') as mdfile:
            if limited_data:
                # Write headers
                headers = list(limited_data[0].keys())
                mdfile.write('| ' + ' | '.join(headers) + ' |\n')
                mdfile.write('|' + '|'.join(['---' for _ in headers]) + '|\n')
                
                # Write data rows
                for row in limited_data:
                    mdfile.write('| ' + ' | '.join([str(row.get(header, '')) for header in headers]) + ' |\n')
            
            mdfile.write(f'\n*Showing first {len(limited_data)} rows of {len(data)} total*\n')
        
        logger.info(f"Wrote {len(limited_data)} rows to {filename}")
    except Exception as e:
        logger.error(f"Failed to write Markdown {filename}: {e}")


def write_json(data: List[Dict], filename: str, logger, redact: bool = False):
    """Write data to JSON file (array format)."""
    if not data:
        logger.warning(f"No data to write to {filename}")
        return
    
    try:
        # Apply redaction if requested
        if redact:
            redacted_data = []
            for row in data:
                redacted_row = row.copy()
                for key in ['principalUPNOrAppId', 'memberUPN']:
                    if key in redacted_row:
                        redacted_row[key] = '[REDACTED]'
                redacted_data.append(redacted_row)
            data = redacted_data
        
        with open(filename, 'w', encoding='utf-8') as jsonfile:
            json.dump(data, jsonfile, indent=2, default=str)
        
        logger.info(f"Wrote {len(data)} rows to {filename}")
    except Exception as e:
        logger.error(f"Failed to write JSON {filename}: {e}")


def write_index_file(index_data: Dict, filename: str, logger):
    """Write index.json file with artifact information."""
    try:
        with open(filename, 'w', encoding='utf-8') as indexfile:
            json.dump(index_data, indexfile, indent=2, default=str)
        logger.info(f"Wrote index file to {filename}")
    except Exception as e:
        logger.error(f"Failed to write index file {filename}: {e}")


def main():
    """Main function."""
    start_time = time.time()
    
    # Setup argument parser
    parser = setup_argument_parser()
    args = parser.parse_args()
    args = validate_arguments(args)
    
    # Check if bootstrap is requested
    if args.bootstrap:
        from shutil import which
        pwsh = which("pwsh") or which("powershell")
        if not pwsh:
            print("Bootstrap: PowerShell 7+ (pwsh) not found. Install it or run Install-Prereqs.ps1 manually.", file=sys.stderr)
            sys.exit(1)
        bootstrap_ps1 = Path(__file__).resolve().parents[2] / "bootstrap" / "Install-Prereqs.ps1"
        cmd = [pwsh, "-NoLogo", "-NoProfile", "-File", str(bootstrap_ps1), "-NonInteractive"]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print("Bootstrap failed. See logs/bootstrap for details.\n---- stdout ----\n"
                  f"{result.stdout}\n---- stderr ----\n{result.stderr}", file=sys.stderr)
            sys.exit(1)
        print("Bootstrap completed successfully")
    
    # Initialize logging
    logger, run_id, log_paths = init_logging("azure/export_rbac_roles_and_assignments")
    logger.info(f"Starting Azure RBAC export run {run_id}")
    logger.info(f"Arguments: {vars(args)}")
    
    # Preflight check
    credential, credential_type = preflight_check(logger)
    if not credential:
        sys.exit(1)
    
    logger.info(f"Using credential type: {credential_type}")
    
    # Get management groups if requested
    management_groups = []
    if args.traverse_management_groups:
        management_groups = get_management_groups(credential, logger)
        if not management_groups:
            logger.warning("No management groups found or access denied")
    
    # Get subscriptions
    subscriptions = []
    if args.subscriptions:
        subscriptions = get_subscriptions(credential, logger, args.subscriptions)
    elif args.discover_subscriptions or args.traverse_management_groups:
        subscriptions = get_subscriptions(credential, logger)
    
    if not subscriptions:
        logger.error("No subscriptions found or accessible")
        sys.exit(1)
    
    # Get resource groups per subscription
    resource_groups_per_sub = {}
    if args.include_resources or args.limit:
        logger.info("Enumerating resource groups...")
        for sub in subscriptions:
            sub_id = sub['subscription_id']
            rgs = get_resource_groups(credential, sub_id, logger)
            resource_groups_per_sub[sub_id] = rgs
            if args.limit and len(resource_groups_per_sub) >= args.limit:
                break
    
    # Check large tenant thresholds
    if not check_large_tenant_thresholds(subscriptions, resource_groups_per_sub, args, logger):
        logger.error("Large tenant safety rail triggered - exiting")
        sys.exit(2)
    
    # Generate output paths
    output_paths = new_output_paths(args.output_path)
    logger.info(f"Output directory: {output_paths['base']}")
    
    # Collect all data
    all_role_definitions = []
    all_role_assignments = []
    scopes_processed = {'managementGroups': 0, 'subscriptions': 0, 'resourceGroups': 0}
    scopes_skipped = []
    errors = []
    warnings = []
    
    # Process management groups
    if args.traverse_management_groups and management_groups:
        logger.info("Processing management groups...")
        for mg in management_groups:
            try:
                mg_id = mg['name']  # Management group name is used in scope
                scope = f"/providers/Microsoft.Management/managementGroups/{mg_id}"
                
                # Get role definitions
                role_defs = get_role_definitions(credential, scope, logger)
                all_role_definitions.extend(role_defs)
                
                # Get role assignments
                assignments = get_role_assignments(credential, scope, logger)
                
                # Mark inherited assignments
                for assignment in assignments:
                    if assignment['scope'] != scope:
                        assignment['inherited'] = True
                
                all_role_assignments.extend(assignments)
                scopes_processed['managementGroups'] += 1
                
                if args.limit and scopes_processed['managementGroups'] >= args.limit:
                    break
                    
            except Exception as e:
                error_msg = f"Failed to process management group {mg.get('name', 'unknown')}: {e}"
                logger.error(error_msg)
                errors.append(error_msg)
                scopes_skipped.append(f"MG:{mg.get('name', 'unknown')}")
    
    # Process subscriptions
    logger.info("Processing subscriptions...")
    for sub in subscriptions:
        try:
            sub_id = sub['subscription_id']
            scope = f"/subscriptions/{sub_id}"
            
            # Get role definitions
            role_defs = get_role_definitions(credential, scope, logger)
            all_role_definitions.extend(role_defs)
            
            # Get role assignments
            assignments = get_role_assignments(credential, scope, logger)
            
            # Mark inherited assignments
            for assignment in assignments:
                if assignment['scope'] != scope:
                    assignment['inherited'] = True
            
            all_role_assignments.extend(assignments)
            scopes_processed['subscriptions'] += 1
            
            # Process resource groups if requested
            if args.include_resources and sub_id in resource_groups_per_sub:
                rgs = resource_groups_per_sub[sub_id]
                for rg in rgs:
                    try:
                        rg_scope = f"/subscriptions/{sub_id}/resourceGroups/{rg['name']}"
                        
                        # Get role assignments at RG level
                        rg_assignments = get_role_assignments(credential, rg_scope, logger)
                        
                        # Mark inherited assignments
                        for assignment in rg_assignments:
                            if assignment['scope'] != rg_scope:
                                assignment['inherited'] = True
                        
                        all_role_assignments.extend(rg_assignments)
                        scopes_processed['resourceGroups'] += 1
                        
                        if args.limit and scopes_processed['resourceGroups'] >= args.limit:
                            break
                    except Exception as e:
                        error_msg = f"Failed to process resource group {rg.get('name', 'unknown')} in {sub_id}: {e}"
                        logger.error(error_msg)
                        errors.append(error_msg)
                        scopes_skipped.append(f"RG:{rg.get('name', 'unknown')}:{sub_id}")
            
            if args.limit and scopes_processed['subscriptions'] >= args.limit:
                break
                
        except Exception as e:
            error_msg = f"Failed to process subscription {sub.get('subscription_id', 'unknown')}: {e}"
            logger.error(error_msg)
            errors.append(error_msg)
            scopes_skipped.append(f"SUB:{sub.get('subscription_id', 'unknown')}")
    
    # Resolve principal names if not disabled
    if not args.no_resolve_principals and all_role_assignments:
        logger.info(f"Resolving {len(all_role_assignments)} principal names...")
        resolved_count = 0
        
        for assignment in all_role_assignments:
            try:
                display_name, upn_or_app_id = resolve_principal(
                    credential, 
                    assignment['principalId'], 
                    assignment['principalType'], 
                    logger,
                    args.no_resolve_principals,
                    args.redact
                )
                assignment['principalDisplayName'] = display_name
                assignment['principalUPNOrAppId'] = upn_or_app_id
                resolved_count += 1
                
                if resolved_count % 100 == 0:
                    logger.debug(f"Resolved {resolved_count}/{len(all_role_assignments)} principals")
                    
            except Exception as e:
                logger.debug(f"Failed to resolve principal {assignment['principalId']}: {e}")
                # Keep IDs as fallback
        
        logger.info(f"Resolved {resolved_count} principal names")
    
    # Expand group members if requested
    if args.expand_group_members and all_role_assignments:
        logger.info("Expanding group members...")
        expanded_count = 0
        
        for assignment in all_role_assignments:
            if assignment['principalType'] == 'Group':
                try:
                    members = expand_group_members(
                        credential,
                        assignment['principalId'],
                        logger,
                        args.group_members_top,
                        args.group_membership_mode
                    )
                    
                    # Add member information to assignment
                    if members:
                        assignment['memberCount'] = len(members)
                        # For simplicity, we'll add the first member's info
                        if members:
                            first_member = members[0]
                            assignment.update({
                                'memberPrincipalId': first_member['memberPrincipalId'],
                                'memberType': first_member['memberType'],
                                'memberDisplayName': first_member['memberDisplayName'],
                                'memberUPN': first_member['memberUPN'] if not args.redact else '[REDACTED]'
                            })
                        
                        expanded_count += 1
                        
                except Exception as e:
                    logger.warning(f"Failed to expand group {assignment['principalId']}: {e}")
        
        logger.info(f"Expanded {expanded_count} groups")
    
    # Write outputs
    logger.info("Writing outputs...")
    
    # Write role definitions
    write_csv(all_role_definitions, output_paths['role_definitions'], logger, args.redact)
    
    # Write role assignments (merged)
    write_csv(all_role_assignments, output_paths['role_assignments'], logger, args.redact)
    
    if HAS_OPENPYXL:
        write_xlsx(all_role_assignments, output_paths['role_assignments_xlsx'], logger, args.redact)
    
    if args.markdown_top > 0:
        write_markdown(all_role_assignments, output_paths['role_assignments_md'], logger, args.markdown_top, args.redact)
    
    if args.json:
        write_json(all_role_definitions, output_paths['role_definitions'].replace('.csv', '.json'), logger, args.redact)
        write_json(all_role_assignments, output_paths['role_assignments'].replace('.csv', '.json'), logger, args.redact)
    
    # Write per-subscription files
    sub_assignments = {}
    for assignment in all_role_assignments:
        sub_id = assignment.get('subscriptionId', '')
        if sub_id:
            if sub_id not in sub_assignments:
                sub_assignments[sub_id] = []
            sub_assignments[sub_id].append(assignment)
    
    for sub_id, assignments in sub_assignments.items():
        sub_file = output_paths['role_assignments'].replace('.csv', f'_{sub_id}.csv')
        write_csv(assignments, sub_file, logger, args.redact)
        
        if HAS_OPENPYXL:
            sub_xlsx = sub_file.replace('.csv', '.xlsx')
            write_xlsx(assignments, sub_xlsx, logger, args.redact)
    
    # Create index file
    index_data = {
        'artifacts': {
            'role_definitions_csv': output_paths['role_definitions'],
            'role_assignments_csv': output_paths['role_assignments'],
            'role_assignments_xlsx': output_paths['role_assignments_xlsx'] if HAS_OPENPYXL else None,
            'role_assignments_md': output_paths['role_assignments_md'] if args.markdown_top > 0 else None
        },
        'row_counts': {
            'role_definitions': len(all_role_definitions),
            'role_assignments': len(all_role_assignments)
        },
        'per_subscription': {
            sub_id: len(assignments) for sub_id, assignments in sub_assignments.items()
        }
    }
    write_index_file(index_data, output_paths['index'], logger)
    
    # Write summary
    duration = time.time() - start_time
    summary_data = {
        'run_id': run_id,
        'start_time': datetime.utcfromtimestamp(start_time).isoformat() + 'Z',
        'end_time': datetime.utcfromtimestamp(time.time()).isoformat() + 'Z',
        'duration_seconds': duration,
        'scopes_processed': scopes_processed,
        'scopes_skipped': scopes_skipped,
        'roles_count': len(all_role_definitions),
        'assignments_count': len(all_role_assignments),
        'warnings': warnings,
        'errors': errors,
        'success': len(errors) == 0,
        'credential_type': credential_type,
        'arguments': vars(args)
    }
    
    write_summary(summary_data, log_paths['summary'], logger)
    
    # Determine exit code
    if len(errors) > 0:
        logger.error(f"Run completed with {len(errors)} errors")
        sys.exit(1)
    elif len(warnings) > 0 or scopes_skipped:
        logger.warning(f"Run completed with {len(warnings)} warnings")
        sys.exit(2)
    else:
        logger.info("Run completed successfully")
        sys.exit(0)


if __name__ == "__main__":
    main()
