#!/usr/bin/env python3
"""
Python doctor script for Azure RBAC export environment.
"""

import sys
import os
import json
import subprocess
from datetime import datetime
from pathlib import Path

def main():
    """Main function to check Python environment."""
    print("Python Doctor Check")
    print("=" * 50)
    
    # Check Python version
    print(f"Python version: {sys.version}")
    
    # Check required packages
    required_packages = [
        'azure-identity',
        'azure-mgmt-authorization', 
        'azure-mgmt-resource',
        'azure-mgmt-managementgroups'
    ]
    
    optional_packages = [
        'msgraph-sdk',
        'openpyxl'
    ]
    
    print("\nRequired packages:")
    missing_required = []
    for package in required_packages:
        try:
            __import__(package.replace('-', '_').split('.')[0])
            print(f"  ✓ {package}")
        except ImportError:
            print(f"  ✗ {package} (MISSING)")
            missing_required.append(package)
    
    print("\nOptional packages:")
    for package in optional_packages:
        try:
            __import__(package.replace('-', '_').split('.')[0])
            print(f"  ✓ {package}")
        except ImportError:
            print(f"  ○ {package} (optional)")
    
    # Check if running in virtual environment
    in_venv = (
        hasattr(sys, 'real_prefix') or 
        (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix)
    )
    print(f"\nVirtual environment: {'Yes' if in_venv else 'No'}")
    
    # Check for requirements.txt
    requirements_file = Path(__file__).parent.parent / "azure" / "python" / "requirements.txt"
    if requirements_file.exists():
        print(f"Requirements file: {requirements_file}")
    else:
        print("Requirements file: Not found")
    
    # Summary
    print("\n" + "=" * 50)
    if missing_required:
        print(f"Status: FAILED - {len(missing_required)} required packages missing")
        print("Missing packages:")
        for package in missing_required:
            print(f"  - {package}")
        return 1
    else:
        print("Status: OK - All required packages found")
        return 0

if __name__ == "__main__":
    sys.exit(main())
