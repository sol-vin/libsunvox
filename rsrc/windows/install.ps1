$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:LIB = "${env:LIB};C:\sunvox"
$env:PATH = "${env:PATH};C:\sunvox"

if (Test-Path "C:\sunvox") {
  Remove-Item "C:\sunvox" -Recurse -Force
}
New-Item -ItemType Directory -Force -Path "C:\sunvox" | Out-Null
Copy-Item -Path (Join-Path $ScriptDir "lib_x86_64\sunvox.dll") -Destination "C:\sunvox\sunvox.dll" -Force
Copy-Item -Path (Join-Path $ScriptDir "lib_x86_64\sunvox.lib") -Destination "C:\sunvox\sunvox.lib" -Force
