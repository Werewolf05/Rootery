# PowerShell script to start both backend and frontend

Write-Host "Starting Rootery Application..." -ForegroundColor Green

# Start backend in a new PowerShell window
Write-Host "Starting backend server..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd backend; npm install; node src/index.js"

# Wait a few seconds for backend to start
Start-Sleep -Seconds 3

# Start Flutter app in the current window
Write-Host "Starting Flutter app..." -ForegroundColor Yellow
flutter pub get
flutter run

Write-Host "Application started successfully!" -ForegroundColor Green

