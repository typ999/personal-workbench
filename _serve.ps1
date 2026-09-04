$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path
$port = 5173
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$($port)/")
try {
  $listener.Start()
} catch {
  Write-Output "FAILED to start listener on port $port : $($_.Exception.Message)"
  exit 1
}
Write-Output "OK HTTP server on http://localhost:$port/  root=$PSScriptRoot"
$mime = @{
  ".html"="text/html; charset=utf-8"; ".htm"="text/html; charset=utf-8"
  ".css"="text/css; charset=utf-8"; ".js"="application/javascript; charset=utf-8"
  ".json"="application/json; charset=utf-8"; ".svg"="image/svg+xml"
  ".jpg"="image/jpeg"; ".jpeg"="image/jpeg"; ".png"="image/png"; ".webp"="image/webp"
  ".ico"="image/x-icon"; ".map"="application/json"; ".woff2"="font/woff2"; ".txt"="text/plain"
}
while($listener.IsListening){
  try {
    $ctx = $listener.GetContext()
    $req = $ctx.Request; $res = $ctx.Response
    $path = [System.Uri]::UnescapeDataString($req.Url.AbsolutePath)
    if([string]::IsNullOrEmpty($path) -or $path -eq "/") { $path = "/workbench.html" }
    $full = Join-Path $PSScriptRoot $path.TrimStart("/\")
    if((Test-Path $full -PathType Leaf) -and $full.StartsWith($PSScriptRoot)){
      $ext = [System.IO.Path]::GetExtension($full).ToLowerInvariant()
      $res.ContentType = if($mime.ContainsKey($ext)){$mime[$ext]}else{"application/octet-stream"}
      $bytes = [System.IO.File]::ReadAllBytes($full)
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes,0,$bytes.Length)
    } else {
      $res.StatusCode = 404
      $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $path")
      $res.OutputStream.Write($msg,0,$msg.Length)
    }
    $res.OutputStream.Close()
    $res.Close()
  } catch {
    try { $ctx.Response.StatusCode=500; $ctx.Response.Close() } catch {}
  }
}
