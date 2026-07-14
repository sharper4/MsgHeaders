param(
    [int]$Port = 8000
)

$ProjectPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Listener = New-Object System.Net.HttpListener
$Listener.Prefixes.Add("http://localhost:$Port/")

try {
    $Listener.Start()
} catch {
    Write-Error "Unable to start listener on port $Port. Try a different port: .\\serve-local.ps1 -Port 8080"
    exit 1
}

Write-Host "Server running at http://localhost:$Port/"
Write-Host "Serving: $ProjectPath"
Write-Host "Press Ctrl+C to stop"

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".css" = "text/css; charset=utf-8"
    ".js" = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".png" = "image/png"
    ".jpg" = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".svg" = "image/svg+xml"
    ".ico" = "image/x-icon"
    ".txt" = "text/plain; charset=utf-8"
}

while ($true) {
    $Context = $Listener.GetContext()
    $Request = $Context.Request
    $Response = $Context.Response
    $Path = $Request.Url.LocalPath

    if ($Path -eq "/") { $Path = "/index.html" }

    $FullPath = Join-Path $ProjectPath $Path.TrimStart("/")
    $FullPath = $FullPath -replace '/', '\\'

    if (Test-Path $FullPath -PathType Leaf) {
        $bytes = [System.IO.File]::ReadAllBytes($FullPath)
        $extension = [System.IO.Path]::GetExtension($FullPath).ToLowerInvariant()
        if ($mimeTypes.ContainsKey($extension)) {
            $Response.ContentType = $mimeTypes[$extension]
        }

        $Response.StatusCode = 200
        $Response.ContentLength64 = $bytes.Length
        $Response.OutputStream.Write($bytes, 0, $bytes.Length)
        Write-Host "[200] $Path"
    } else {
        $Response.StatusCode = 404
        Write-Host "[404] $Path"
    }

    $Response.Close()
}
