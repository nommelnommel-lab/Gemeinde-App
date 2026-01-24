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

function Invoke-Json {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Method,
    [Parameter(Mandatory = $true)]
    [string]$Uri,
    [hashtable]$Headers,
    $BodyObj
  )

  try {
    if ($null -ne $BodyObj) {
      $jsonBody = $BodyObj | ConvertTo-Json -Depth 10
      return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $Headers -ContentType "application/json" -Body $jsonBody
    }

    return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $Headers
  } catch {
    $response = $_.Exception.Response
    if ($response -and $response.GetResponseStream()) {
      $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
      $body = $reader.ReadToEnd()
      $status = [int]$response.StatusCode
      Write-Host "Request failed ($status): $body"
    }
    throw
  }
}

$unique = Get-Random -Minimum 1000 -Maximum 9999
$firstName = "Test$unique"
$lastName = "Resident"
$postalCode = "36115"
$houseNumber = "12A"
$email = "test$unique@example.com"
$password = "Test-Password-$unique"

Write-Host "Creating resident..."
$residentResponse = (Invoke-Json -Method "Post" -Uri "$baseUrl/api/admin/residents" -Headers $adminHeaders -BodyObj @{
  firstName = $firstName
  lastName = $lastName
  postalCode = $postalCode
  houseNumber = $houseNumber
})

$residentId = $residentResponse.residentId
if (-not $residentId) {
  throw "residentId fehlt in der Antwort"
}

Write-Host "Creating activation code..."
$act = (Invoke-Json -Method "Post" -Uri "$baseUrl/api/admin/activation-codes" -Headers $adminHeaders -BodyObj @{
  residentId = $residentId
  expiresInDays = 14
})

$activationCode = $act.code
if (-not $activationCode) {
  throw "activation code fehlt in der Antwort"
}

Write-Host "Activating resident..."
$login = (Invoke-Json -Method "Post" -Uri "$baseUrl/api/auth/activate" -Headers $publicHeaders -BodyObj @{
  activationCode = $activationCode
  email = $email
  password = $password
  postalCode = $postalCode
  houseNumber = $houseNumber
})

$refreshToken = $login.refreshToken
if (-not $refreshToken) {
  throw "refreshToken fehlt nach Aktivierung"
}

Write-Host "Logging in..."
$login = (Invoke-Json -Method "Post" -Uri "$baseUrl/api/auth/login" -Headers $publicHeaders -BodyObj @{
  email = $email
  password = $password
})

$refreshToken = $login.refreshToken
if (-not $refreshToken) {
  throw "refreshToken fehlt nach Login"
}

Write-Host "Refreshing token..."
$ref = (Invoke-Json -Method "Post" -Uri "$baseUrl/api/auth/refresh" -Headers $publicHeaders -BodyObj @{
  refreshToken = $refreshToken
})

if (-not $ref.refreshToken) {
  throw "refreshToken fehlt nach Refresh"
}

Write-Host "Refreshing with old token (should be 401)..."
$oldRefreshResponse = Invoke-WebRequest -Method Post -Uri "$baseUrl/api/auth/refresh" -Headers $publicHeaders -ContentType "application/json" -Body (@{
  refreshToken = $refreshToken
} | ConvertTo-Json -Depth 10) -SkipHttpErrorCheck

if ($oldRefreshResponse.StatusCode -ne 401) {
  throw "Refresh mit altem Token sollte 401 liefern, bekam $($oldRefreshResponse.StatusCode)"
}

Write-Host "Logging out..."
$logout = (Invoke-Json -Method "Post" -Uri "$baseUrl/api/auth/logout" -Headers $publicHeaders -BodyObj @{
  refreshToken = $ref.refreshToken
})

if (-not $logout.ok) {
  throw "Logout nicht ok"
}

Write-Host "Refreshing after logout (should be 401)..."
$refreshAfterLogout = Invoke-WebRequest -Method Post -Uri "$baseUrl/api/auth/refresh" -Headers $publicHeaders -ContentType "application/json" -Body (@{
  refreshToken = $ref.refreshToken
} | ConvertTo-Json -Depth 10) -SkipHttpErrorCheck

if ($refreshAfterLogout.StatusCode -ne 401) {
  throw "Refresh nach Logout sollte 401 liefern, bekam $($refreshAfterLogout.StatusCode)"
}

Write-Host "Auth flow test completed."
