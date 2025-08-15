# Test script to verify the fixes
Write-Host "Testing PowerShell Doctor with NonInteractive flag..." -ForegroundColor Cyan
pwsh -File .\scripts\bootstrap\doctor.ps1 -NonInteractive
Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor Yellow

Write-Host "`nTesting Python Doctor..." -ForegroundColor Cyan
python .\scripts\bootstrap\doctor.py --non-interactive
Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor Yellow

Write-Host "`nTesting PowerShell Exporter Bootstrap flag..." -ForegroundColor Cyan
pwsh -File .\scripts\azure\powershell\Export-RbacRolesAndAssignments.ps1 -Bootstrap -NonInteractive
Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor Yellow

Write-Host "`nTesting Python Exporter Bootstrap flag..." -ForegroundColor Cyan
python .\scripts\azure\python\export_rbac_roles_and_assignments.py --bootstrap
Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor Yellow
