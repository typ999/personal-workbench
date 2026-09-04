$port = 9754
$root = $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Serving $root at http://localhost:$port/ (Ctrl+C to stop)"

while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $res = $ctx.Response
    $path = $req.Url.AbsolutePath
    if ($path -eq "/") { $path = "/workbench.html" }
    $file = Join-Path $root ($path -replace "^/","" -replace "/","\")
    if (Test-Path $file -PathType Leaf) {
      $bytes = [System.IO.File]::ReadAllBytes($file)
      $ext = [System.IO.Path]::GetExtension($file).ToLower()
      $ct = "application/octet-stream"
      switch ($ext) {
        ".html" { $ct = "text/html; charset=utf-8" }
        ".js"   { $ct = "application/javascript; charset=utf-8" }
        ".css"  { $ct = "text/css; charset=utf-8" }
        ".json" { $ct = "application/json; charset=utf-8" }
        ".png"  { $ct = "image/png" }
        ".jpg"  { $ct = "image/jpeg" }
        ".svg"  { $ct = "image/svg+xml" }
      }
      $res.ContentType = $ct
      $res.ContentLength64 = $bytes.LongLength
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $res.StatusCode = 404
      $body = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $path")
      $res.OutputStream.Write($body, 0, $body.Length)
    }
    $res.Close()
  } catch {
    Write-Host "Err: $_"
  }
}
