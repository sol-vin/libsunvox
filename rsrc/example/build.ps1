$env:LIB = "${env:LIB};C:\sunvox"
$env:PATH = "${env:PATH};C:\sunvox"

Remove-Item "lib" -Recurse -Force
mkdir lib
mkdir lib\libsunvox
Copy-Item -Path (Get-Item -Path "..\..\*" -Exclude ('rsrc')).FullName -Destination "lib/libsunvox" -Recurse -Force

crystal build --error-trace -o bin\example.exe src\example2.cr 