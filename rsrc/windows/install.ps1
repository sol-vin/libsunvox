$env:LIB = "${env:LIB};C:\sunvox"
$env:PATH = "${env:PATH};C:\sunvox"

Remove-Item "C:\sunvox" -Force
mkdir C:\sunvox
Copy-Item -Path "lib_x86_64\sunvox.dll" -Destination "C:\sunvox\sunvox.dll"
Copy-Item -Path "lib_x86_64\sunvox.lib" -Destination "C:\sunvox\sunvox.lib"
