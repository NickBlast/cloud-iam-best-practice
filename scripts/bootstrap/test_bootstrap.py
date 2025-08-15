#!/usr/bin/env python3
"""
Test script to verify bootstrap functionality
"""

import sys
from pathlib import Path

def main():
    print("Bootstrap test script running...")
    print(f"Python version: {sys.version}")
    print(f"Script location: {Path(__file__).resolve()}")
    
    # Test importing required modules
    try:
        import azure
        print("✓ Azure SDK available")
    except ImportError:
        print("✗ Azure SDK not available")
        return 1
    
    try:
        import importlib
        importlib.import_module("msgraph.core")
        print("✓ Microsoft Graph SDK available")
    except ImportError:
        print("⚠ Microsoft Graph SDK not available (optional)")
    
    try:
        import openpyxl
        print("✓ openpyxl available")
    except ImportError:
        print("⚠ openpyxl not available (optional)")
    
    print("Bootstrap test completed successfully")
    return 0

if __name__ == "__main__":
    sys.exit(main())
