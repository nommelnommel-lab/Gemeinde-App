$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$BASE = "http://localhost:3000"
$TENANT = "hilders"
$SITE_KEY = "HD-2026-9f3c1a2b-KEY"
$ADMIN_KEY = "HD-ADMIN-TEST-KEY"

function Preview-Key {
  param([string]$Key)

  if ([string]::IsNullOrWhiteSpace($Key)) {
    return "<missing>"
  }

  $trimmed = $Key.Trim()
  if ($trimmed.Length -le 4) {
    return "$trimmed***"
  }

  return "{0}***" -f $trimmed.Substring(0, 4)
}

function New-Headers {
  param(
    [Parameter(Mandatory = $true)][string]$Tenant,
    [Parameter(Mandatory = $true)][string]$SiteKey,
    [string]$AdminKey
  )

  $headers = @{
    "Content-Type" = "application/json"
    "X-TENANT" = $Tenant.Trim()
    "X-SITE-KEY" = $SiteKey.Trim()
  }

  if (-not [string]::IsNullOrWhiteSpace($AdminKey)) {
    $headers["X-ADMIN-KEY"] = $AdminKey.Trim()
  }

  return $headers
}

function Write-Header-Debug {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Headers
  )

  foreach ($name in @("X-TENANT", "X-SITE-KEY", "X-ADMIN-KEY")) {
    $value = $Headers[$name]
    $isSet = -not [string]::IsNullOrWhiteSpace($value)
    $length = 0
    if ($isSet) {
      $length = $value.Trim().Length
    }
    $preview = Preview-Key $value
    Write-Host ("Header {0}: set={1} len={2} preview={3}" -f $name, $isSet, $length, $preview) -ForegroundColor DarkGray
  }
}

function Invoke-Json {
  param(
    [Parameter(Mandatory = $true)][string]$Method,
    [Parameter(Mandatory = $true)][string]$Uri,
    [Parameter(Mandatory = $true)][hashtable]$Headers,
    $BodyObj = $null
  )

  Write-Host ("Request: {0} {1}" -f $Method.ToUpper(), $Uri)
  Write-Header-Debug -Headers $Headers

  $jsonBody = $null
  if ($null -ne $BodyObj) {
    $jsonBody = $BodyObj | ConvertTo-Json -Depth 10
  }

  try {
    if ($null -ne $jsonBody) {
      return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $Headers -ContentType "application/json" -Body $jsonBody
    }

    return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $Headers
  } catch {
    $serverMessage = $null

    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
      $serverMessage = $_.ErrorDetails.Message
    } elseif ($_.Exception -and $_.Exception.Message) {
      $serverMessage = $_.Exception.Message
    }

    Write-Host "" 
    Write-Host ("Request failed: {0} {1}" -f $Method.ToUpper(), $Uri) -ForegroundColor Red
    if ($null -ne $jsonBody) {
      Write-Host ("Request body: {0}" -f $jsonBody) -ForegroundColor DarkGray
    }
    if ($serverMessage) {
      Write-Host ("Server error: {0}" -f $serverMessage) -ForegroundColor Yellow
    }
    throw
  }
}

$adminHeaders = New-Headers -Tenant $TENANT -SiteKey $SITE_KEY -AdminKey $ADMIN_KEY
$publicHeaders = New-Headers -Tenant $TENANT -SiteKey $SITE_KEY

$unique = Get-Random -Minimum 1000 -Maximum 9999
$firstName = "Test$unique"
$lastName = "Resident"
$postalCode = "36115"
$houseNumber = "HN-$unique"
$email = "test$unique@example.com"
$password = "Test-Password-$unique"

Write-Host "Creating resident..."
$residentResponse = Invoke-Json -Method "Post" -Uri "$BASE/api/admin/residents" -Headers $adminHeaders -BodyObj @{
  firstName = $firstName
  lastName = $lastName
  postalCode = $postalCode
  houseNumber = $houseNumber
}

$residentId = $residentResponse.residentId
if (-not $residentId) {
  throw "residentId fehlt in der Antwort"
}

Write-Host "Creating activation code..."
$activationResponse = Invoke-Json -Method "Post" -Uri "$BASE/api/admin/activation-codes" -Headers $adminHeaders -BodyObj @{
  residentId = $residentId
  expiresInDays = 14
}

$activationCode = $activationResponse.code
if (-not $activationCode) {
  throw "activation code fehlt in der Antwort"
}

Write-Host "Activating resident..."
$activateResponse = Invoke-Json -Method "Post" -Uri "$BASE/api/auth/activate" -Headers $publicHeaders -BodyObj @{
  activationCode = $activationCode
  email = $email
  password = $password
  postalCode = $postalCode
  houseNumber = $houseNumber
}

$activationRefreshToken = $activateResponse.refreshToken
if (-not $activationRefreshToken) {
  throw "refreshToken fehlt nach Aktivierung"
}
Write-Host "Activation refresh token erhalten."

Write-Host "Logging in..."
$loginResponse = Invoke-Json -Method "Post" -Uri "$BASE/api/auth/login" -Headers $publicHeaders -BodyObj @{
  email = $email
  password = $password
}

$loginRefreshToken = $loginResponse.refreshToken
if (-not $loginRefreshToken) {
  throw "refreshToken fehlt nach Login"
}
Write-Host "Login refresh token erhalten."

Write-Host "Refreshing token..."
$refreshResponse = Invoke-Json -Method "Post" -Uri "$BASE/api/auth/refresh" -Headers $publicHeaders -BodyObj @{
  refreshToken = $loginRefreshToken
}

if (-not $refreshResponse.refreshToken) {
  throw "refreshToken fehlt nach Refresh"
}
$rotatedRefreshToken = $refreshResponse.refreshToken
Write-Host "Refresh token rotiert."

Write-Host "Refreshing with old token (should be 401)..."
try {
  Invoke-Json -Method "Post" -Uri "$BASE/api/auth/refresh" -Headers $publicHeaders -BodyObj @{
    refreshToken = $loginRefreshToken
  }
  throw "Refresh mit altem Token sollte 401 liefern, bekam 200"
} catch {
  if ($_.Exception.Message -match "401") {
    Write-Host "401 erwartete Antwort erhalten."
  } else {
    throw
  }
}

Write-Host "Logging out..."
$logoutResponse = Invoke-Json -Method "Post" -Uri "$BASE/api/auth/logout" -Headers $publicHeaders -BodyObj @{
  refreshToken = $rotatedRefreshToken
}

if (-not $logoutResponse.ok) {
  throw "Logout nicht ok"
}

Write-Host "Refreshing after logout (should be 401)..."
try {
  Invoke-Json -Method "Post" -Uri "$BASE/api/auth/refresh" -Headers $publicHeaders -BodyObj @{
    refreshToken = $rotatedRefreshToken
  }
  throw "Refresh nach Logout sollte 401 liefern, bekam 200"
} catch {
  if ($_.Exception.Message -match "401") {
    Write-Host "401 erwartete Antwort erhalten."
  } else {
    throw
  }
}

Write-Host "DONE ✅"
