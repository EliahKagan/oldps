# oldps - Show non-elevated PowerShell symlink creation behavior

Running the `demo-symlinks.ps1` script as a limited user or as an non-elevated
administrator with UAC enabled, on a Windows 10 system with developer mode
enabled to allow non-privileged symlink creation, shows whether a version of
PowerShell is able to perform non-privileged symlink creation when allowed:

- With the currently maintained PowerShell (PowerShell Core, `pwsh.exe`), this
  works: the symlinks are created.

- With the older  Windows PowerShell (`powershell.exe`), this does not work:
  the symlinks are not created, due to permission errors.

The cause seems to be that the old Windows PowerShell does not set the
`SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE` in the `dwFlags` argument to
[`CreateSymbolicLinkW`](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-createsymboliclinkw).

Since Windows PowerShell is kept for backward compatibility, it may be that it
has intentionally not been updated to allow scripts that use
`New-Item -ItemType SymbolicLink`, when run with it, to take advantage of
non-privileged symlink creation.

(This is even though `mklink` builtin of `cmd.exe`
[was updated](https://blogs.windows.com/windowsdeveloper/2016/12/02/symlinks-windows-10/).
I think that makes sense, though. `cmd.exe` is what `%ComSpec%` runs, and while
it is an older shell than any PowerShell, there is no replacement for it for
scripts one does not wish to substantially rewrite.)

## Scripts

### `demo-symlinks.ps1`

The `demo-symlinks.ps1` script runs the experiment. `file`, `dir`, `symlink`,
and `symlinkd` should be absent when it runs. To run it in Windows Powershell:

```powershell
powershell.exe .\demo-symlinks.ps1
```

To run it in the newer PowerShell \[Core\]:

```pwsh
pwsh.exe .\demo-symlinks.ps1
```

Or, just:

```pwsh
pwsh.exe demo-symlinks.ps1
```

(The `.exe` suffixes in all the above commands can be omitted. They are shown
above to emphasize that this way of running the script is really running a new
interpreter instance, with its own environment.)

### `clean.ps1`

The `clean.ps1` script deletes `file`, `dir`, `symlink`, and `symlinkd`,
resetting the current directory another experiment.

## Results

This is the output of the experiment, showing each run of `demo-symlinks.ps1`
with `powershell.exe` and then with `pwsh.exe`.

In between, the `clean.ps1` script was run (though that is not shown).

### In current PowerShell \[Core\]

```text
> pwsh.exe -c '$PSVersionTable'

Name                           Value
----                           -----
PSVersion                      7.4.6
PSEdition                      Core
GitCommitId                    7.4.6
OS                             Microsoft Windows 10.0.19045
Platform                       Win32NT
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0…}
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
WSManStackVersion              3.0

> pwsh.exe .\demo-symlinks.ps1

    Directory: C:\Users\ek\tmp\oldps

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---          12/29/2024 12:19 AM              0 file
d----          12/29/2024 12:19 AM                dir
la---          12/29/2024 12:19 AM              0 symlink -> file
l----          12/29/2024 12:19 AM                symlinkd -> dir
d----          12/29/2024 12:19 AM                dir
l----          12/29/2024 12:19 AM                symlinkd -> dir
-a---          12/28/2024 11:54 PM             78 clean.ps1
-a---          12/28/2024 11:48 PM            227 demo-symlinks.ps1
-a---          12/29/2024 12:19 AM              0 file
-a---          12/29/2024 12:18 AM           2342 README.md
la---          12/29/2024 12:19 AM              0 symlink -> file
 Volume in drive C is OS
 Volume Serial Number is B203-10FB

 Directory of C:\Users\ek\tmp\oldps

12/29/2024  12:19 AM    <DIR>          .
12/29/2024  12:19 AM    <DIR>          ..
12/28/2024  11:54 PM                78 clean.ps1
12/28/2024  11:48 PM               227 demo-symlinks.ps1
12/29/2024  12:19 AM    <DIR>          dir
12/29/2024  12:19 AM                 0 file
12/29/2024  12:18 AM             2,342 README.md
12/29/2024  12:19 AM    <SYMLINK>      symlink [file]
12/29/2024  12:19 AM    <SYMLINKD>     symlinkd [dir]
               5 File(s)          2,647 bytes
               4 Dir(s)  46,942,826,496 bytes free
```

### In Windows PowerShell

```text
C:\Users\ek\tmp\oldps [main +3 ~0 -0 ~]> powershell.exe -c '$PSVersionTable'

Name                           Value
----                           -----
PSVersion                      5.1.19041.5247
PSEdition                      Desktop
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0...}
BuildVersion                   10.0.19041.5247
CLRVersion                     4.0.30319.42000
WSManStackVersion              3.0
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1


C:\Users\ek\tmp\oldps [main +3 ~0 -0 ~]> powershell.exe .\demo-symlinks.ps1


    Directory: C:\Users\ek\tmp\oldps


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        12/29/2024  12:21 AM              0 file
d-----        12/29/2024  12:21 AM                dir
New-Item : Administrator privilege required for this operation.
At C:\Users\ek\tmp\oldps\demo-symlinks.ps1:3 char:1
+ New-Item -ItemType SymbolicLink -Path symlink -Target file
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : PermissionDenied: (C:\Users\ek\tmp\oldps\file:String) [New-Item], UnauthorizedAccessExce
   ption
    + FullyQualifiedErrorId : NewItemSymbolicLinkElevationRequired,Microsoft.PowerShell.Commands.NewItemCommand

New-Item : Administrator privilege required for this operation.
At C:\Users\ek\tmp\oldps\demo-symlinks.ps1:4 char:1
+ New-Item -ItemType SymbolicLink -Path symlinkd -Target dir
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : PermissionDenied: (C:\Users\ek\tmp\oldps\dir:String) [New-Item], UnauthorizedAccessExcep
   tion
    + FullyQualifiedErrorId : NewItemSymbolicLinkElevationRequired,Microsoft.PowerShell.Commands.NewItemCommand

d-----        12/29/2024  12:21 AM                dir
-a----        12/28/2024  11:54 PM             78 clean.ps1
-a----        12/28/2024  11:48 PM            227 demo-symlinks.ps1
-a----        12/29/2024  12:21 AM              0 file
-a----        12/29/2024  12:20 AM           4360 README.md
 Volume in drive C is OS
 Volume Serial Number is B203-10FB

 Directory of C:\Users\ek\tmp\oldps

12/29/2024  12:21 AM    <DIR>          .
12/29/2024  12:21 AM    <DIR>          ..
12/28/2024  11:54 PM                78 clean.ps1
12/28/2024  11:48 PM               227 demo-symlinks.ps1
12/29/2024  12:21 AM    <DIR>          dir
12/29/2024  12:21 AM                 0 file
12/29/2024  12:20 AM             4,360 README.md
               4 File(s)          4,665 bytes
               3 Dir(s)  46,944,288,768 bytes free
```

## License

[0BSD](LICENSE)

## Further reading

On the need for the `SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE` flag, see
the above links, as well as
[this experiment](https://github.com/EliahKagan/symlink) and
[this discussion](https://github.com/GitoxideLabs/gitoxide/pull/1374#issuecomment-2558260224).
