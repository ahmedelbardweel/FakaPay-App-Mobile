$token = '32|vu3iqNKUyKHXFqdr0Qn9IyBIvpkBvu0BFpmertTJ282d588f'
$headers = @{
    'Accept' = 'application/json'
    'Authorization' = "Bearer $token"
}
$url = 'https://faka-pay.onrender.com/api/wallet/data'

try {
    $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
    Write-Output "--- API Response ---"
    $response | ConvertTo-Json -Depth 10
} catch {
    Write-Error $_
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Output "Error Body: $($reader.ReadToEnd())"
    }
}
