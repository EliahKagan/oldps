New-Item -ItemType File -Path file
New-Item -ItemType Directory -Path dir
New-Item -ItemType SymbolicLink -Path symlink -Target file
New-Item -ItemType SymbolicLink -Path symlinkd -Target dir
Get-ChildItem
cmd.exe /c dir
