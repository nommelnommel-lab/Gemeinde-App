$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$act = $null
$ref = $null
$login = $null

$baseUrl = if ($env:API_BASE_URL) { $env:API_BASE_URL } else { "http://localhost:3000" }
$tenantId = if ($env:TENANT_ID) { $env:TENANT_ID } else { "hilders" }
$siteKey = if ($env:SITE_KEY) { $env:SITE_KEY } else { "HD-2026-9f3c1a2b-KEY" }
$adminKey = if ($env:ADMIN_KEY) { $env:ADMIN_KEY } else { "ADMIN-KEY-1" }

$adminHeaders = @{
  "Content-Type" = "application/json"
  "X-TENANT" = $tenantId
  "X-SITE-KEY" = $siteKey
  "X-ADMIN-KEY" = $adminKey
}

$publicHeaders = @{
  "Content-Type" = "application/json"
  "X-TENANT" = $tenantId
  "X-SITE-KEY" = $siteKey
}

$unique = Get-Random -Minimum 1000 -Maximum 9999
$firstName = "Test$unique"
$lastName = "Resident"
$postalCode = "36115"
$houseNumber = "12A"
$email = "test$unique@example.com"
$password = "Test-Password-$unique"

Write-Host "Creating resident..."
$residentResponse = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/admin/residents" \
  -Headers $adminHeaders \
  -Body (@{
    firstName = $firstName
    lastName = $lastName
    postalCode = $postalCode
    houseNumber = $houseNumber
  } | ConvertTo-Json) \
  -ErrorAction Stop

$residentId = $residentResponse.residentId
if (-not $residentId) {
  throw "residentId fehlt in der Antwort"
}

Write-Host "Creating activation code..."
$act = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/admin/activation-codes" \
  -Headers $adminHeaders \
  -Body (@{
    residentId = $residentId
    expiresInDays = 14
  } | ConvertTo-Json) \
  -ErrorAction Stop

$activationCode = $act.code
if (-not $activationCode) {
  throw "activation code fehlt in der Antwort"
}

Write-Host "Activating resident..."
$login = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/auth/activate" \
  -Headers $publicHeaders \
  -Body (@{
    activationCode = $activationCode
    email = $email
    password = $password
    postalCode = $postalCode
    houseNumber = $houseNumber
  } | ConvertTo-Json) \
  -ErrorAction Stop

$refreshToken = $login.refreshToken
if (-not $refreshToken) {
  throw "refreshToken fehlt nach Aktivierung"
}

Write-Host "Refreshing token..."
$ref = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/auth/refresh" \
  -Headers $publicHeaders \
  -Body (@{
    refreshToken = $refreshToken
  } | ConvertTo-Json) \
  -ErrorAction Stop

if (-not $ref.refreshToken) {
  throw "refreshToken fehlt nach Refresh"
}

Write-Host "Logging out..."
$logout = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/auth/logout" \
  -Headers $publicHeaders \
  -Body (@{
    refreshToken = $ref.refreshToken
  } | ConvertTo-Json) \
  -ErrorAction Stop

if (-not $logout.ok) {
  throw "Logout nicht ok"
}

Write-Host "Refreshing after logout (should be 401)..."
$refreshAfterLogout = Invoke-WebRequest -Method Post -Uri "$baseUrl/api/auth/refresh" \
  -Headers $publicHeaders \
  -Body (@{
    refreshToken = $ref.refreshToken
  } | ConvertTo-Json) \
  -SkipHttpErrorCheck

if ($refreshAfterLogout.StatusCode -ne 401) {
  throw "Refresh nach Logout sollte 401 liefern, bekam $($refreshAfterLogout.StatusCode)"
}

Write-Host "Auth flow test completed."
