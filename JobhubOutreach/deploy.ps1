# ---------------------------
# Firebase Deploy Script
# For project: jobhub-lead-emails
# ---------------------------

Write-Host "=== JobHub Lead Email System Deployment ===" -ForegroundColor Cyan
Write-Host "Checking Firebase project alias..." -ForegroundColor Yellow

# Check if .firebaserc exists
if (!(Test-Path ".firebaserc")) {
    Write-Host "`nERROR: .firebaserc not found in this directory!" -ForegroundColor Red
    Write-Host "Make sure you are in the project root." -ForegroundColor Red
    exit 1
}

# Read .firebaserc
$firebaserc = Get-Content ".firebaserc" -Raw | ConvertFrom-Json

if (-not $firebaserc.projects.default -or $firebaserc.projects.default -ne "jobhub-lead-emails") {
    Write-Host "`nERROR: Firebase project alias 'jobhub-lead-emails' is NOT set as default in this directory." -ForegroundColor Red

    Write-Host "`nFix this by running:" -ForegroundColor Yellow
    Write-Host "firebase use --add" -ForegroundColor Green
    Write-Host "Then choose your Firebase project: jobhub-lead-emails" -ForegroundColor Green
    Write-Host "And when asked for an alias, type: jobhub-lead-emails" -ForegroundColor Green

    exit 1
}

Write-Host "✔ Alias found: jobhub-lead-emails" -ForegroundColor Green
Write-Host "`nSetting Firebase project..." -ForegroundColor Yellow

firebase use jobhub-lead-emails
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nERROR: Failed to switch Firebase project." -ForegroundColor Red
    exit 1
}

Write-Host "`nDeploying Hosting + Firestore Rules..." -ForegroundColor Yellow

firebase deploy --only hosting,firestore:rules

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nERROR: Deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n✔ Deployment complete!" -ForegroundColor Green
Write-Host "Your site should now be live at:"
Write-Host "https://jobhub-lead-emails.web.app" -ForegroundColor Cyan
