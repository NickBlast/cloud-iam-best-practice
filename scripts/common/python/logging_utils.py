"""
Shared logging utilities for Azure RBAC export scripts.
"""
import logging
import json
import os
import uuid
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Tuple, Optional

# Constants
DEFAULT_LOG_FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'


def now_utc_iso() -> str:
    """Get current UTC time in ISO format."""
    return datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")



def init_logging(script_name: str) -> Tuple[logging.Logger, str, Dict[str, str]]:
    """
    Initialize structured logging for the script.
    
    Args:
        script_name: Name of the script (e.g., 'azure/export_rbac_roles_and_assignments')
        
    Returns:
        Tuple of (logger, run_id, paths_dict)
    """
    run_id = str(uuid.uuid4())
    
    # Create logs directory with date structure
    date_str = datetime.utcnow().strftime("%Y%m%d")
    logs_dir = Path("logs") / date_str
    logs_dir.mkdir(parents=True, exist_ok=True)
    
    # Define log paths
    log_paths = {
        "text": str(logs_dir / f"{script_name.replace('/', '_')}_{run_id}.log"),
        "jsonl": str(logs_dir / f"{script_name.replace('/', '_')}_{run_id}.jsonl"),
        "summary": str(logs_dir / f"{script_name.replace('/', '_')}_{run_id}_summary.json")
    }
    
    # Create logger
    logger = logging.getLogger(script_name)
    logger.setLevel(logging.INFO)
    
    # Clear any existing handlers
    logger.handlers.clear()
    
    # Text file handler
    text_handler = logging.FileHandler(log_paths["text"], encoding='utf-8')
    text_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    text_handler.setFormatter(text_formatter)
    logger.addHandler(text_handler)
    
    # JSONL file handler
    jsonl_handler = logging.FileHandler(log_paths["jsonl"], encoding='utf-8')
    
    class JsonFormatter(logging.Formatter):
        def format(self, record):
            log_entry = {
                "ts": now_utc_iso(),
                "run_id": run_id,
                "script": script_name,
                "level": record.levelname,
                "event": record.getMessage(),
                "detail": getattr(record, 'detail', {})
            }
            return json.dumps(log_entry, separators=(',', ':'))
    
    jsonl_handler.setFormatter(JsonFormatter())
    logger.addHandler(jsonl_handler)
    
    # Console handler for immediate feedback
    console_handler = logging.StreamHandler()
    console_formatter = logging.Formatter('%(levelname)s: %(message)s')
    console_handler.setFormatter(console_formatter)
    logger.addHandler(console_handler)
    
    logger.info(f"Logging initialized for run {run_id}")
    
    return logger, run_id, log_paths


def write_summary(summary_data: Dict[str, Any], summary_path: str, logger: Optional[logging.Logger] = None):
    """
    Write summary JSON file.
    
    Args:
        summary_data: Dictionary containing summary information
        summary_path: Path to write the summary file
        logger: Optional logger for logging the operation
    """
    try:
        # Ensure the directory exists
        Path(summary_path).parent.mkdir(parents=True, exist_ok=True)
        
        with open(summary_path, 'w', encoding='utf-8') as f:
            json.dump(summary_data, f, indent=2, default=str)
            
        if logger:
            logger.info(f"Summary written to {summary_path}")
    except Exception as e:
        if logger:
            logger.error(f"Failed to write summary: {e}")


def new_output_paths(base_path: Optional[str] = None) -> Dict[str, str]:
    """
    Generate deterministic output paths.
    
    Args:
        base_path: Optional base path. If None, generates timestamped path.
        
    Returns:
        Dictionary with output paths
    """
    if base_path is None:
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        base_path = f"output/azure/export_rbac_roles_and_assignments_{timestamp}"
    
    output_dir = Path(base_path)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    return {
        "base": str(output_dir),
        "role_definitions": str(output_dir / "role_definitions.csv"),
        "role_assignments": str(output_dir / "role_assignments.csv"),
        "role_assignments_xlsx": str(output_dir / "role_assignments.xlsx"),
        "role_assignments_md": str(output_dir / "role_assignments.md"),
        "index": str(output_dir / "index.json")
    }
