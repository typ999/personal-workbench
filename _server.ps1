$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://localhost:8080/')
$listener.Start()
Write-Output 'Server running at http://localhost:8080/'

while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $url = $ctx.Request.Url.LocalPath
    if ($url -eq '/') { $url = '/workbench.html' }
    $filePath = Join-Path $PSScriptRoot $url.TrimStart('/')
    
    if (Test-Path $filePath -PathType Leaf) {
        $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
        $ct = switch ($ext) {
            '.html' { 'text/html; charset=utf-8' }
            '.css'  { 'text/css; charset=utf-8' }
            '.js'   { 'application/javascript; charset=utf-8' }
            '.json' { 'application/json; charset=utf-8' }
            '.jpg'  { 'image/jpeg' }
            '.png'  { 'image/png' }
            '.svg'  { 'image/svg+xml' }
            '.gif'  { 'image/gif' }
            default { 'application/octet-stream' }
        }
        $buf = [System.IO.File]::ReadAllBytes($filePath)
        $ctx.Response.ContentType = $ct
        $ctx.Response.ContentLength64 = $buf.Length
        $ctx.Response.OutputStream.Write($buf, 0, $buf.Length)
    } else {
        $ctx.Response.StatusCode = 404
        $sw = [System.IO.StreamWriter]::new($ctx.Response.OutputStream)
        $sw.Write('Not Found: ' + $url)
        $sw.Close()
    }
    $ctx.Response.Close()
}
