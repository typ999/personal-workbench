@echo off
chcp 65001 >nul
echo ========================================
echo   个人工作台 - 本地服务启动器
echo ========================================
echo.

:: 尝试 Python
where python >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo 检测到 Python，正在启动服务...
    echo 服务地址: http://localhost:8080/
    echo.
    start "" "http://localhost:8080/workbench-mobile.html"
    python -m http.server 8080
    pause
    exit /b
)

:: 尝试 Node.js
where node >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo 检测到 Node.js，正在启动服务...
    echo 服务地址: http://localhost:8080/
    echo.
    start "" "http://localhost:8080/workbench-mobile.html"
    node -e "const h=require('http'),f=require('fs'),p=require('path');const s=h.createServer((req,res)=>{let u=decodeURIComponent(req.url.split('?')[0]);u==='/'&&(u='/index.html');let fp=p.join(process.cwd(),u);f.stat(fp,(e,st)=>{if(e||!st.isFile()){res.writeHead(404);res.end('Not Found');return;}const ct={'html':'text/html','css':'text/css','js':'application/javascript','jpg':'image/jpeg','png':'image/png','svg':'image/svg+xml','json':'application/json','manifest':'application/json'}[p.extname(fp).slice(1).toLowerCase()]||'application/octet-stream';res.writeHead(200,{'Content-Type':ct});f.createReadStream(fp).pipe(res);});});s.listen(8080,()=>console.log('HTTP server on http://localhost:8080'));"
    pause
    exit /b
)

:: 都没有，提示安装
echo.
echo 本机没有检测到 Python 或 Node.js。
echo.
echo 方案 1（推荐）：双击 workbench-mobile.html 直接用浏览器打开
echo 方案 2：安装 Python https://www.python.org/downloads/（安装时记得勾 "Add to PATH"）
echo 方案 3：安装 Node.js https://nodejs.org/
echo 方案 4：上传到任意静态托管（GitHub Pages / Vercel / Netlify / 阿里云 OSS / 腾讯云 COS）
echo.
pause
