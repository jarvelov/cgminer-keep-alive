cgminer-keep-alive
==================

Powershell script (with accompanying batch file) that parses cgminer's log and restarts the application when it hangs/crashes.

Output
==================

cgminer-keep-alive produces very little output. The default settings only output a start message and whenever cgminer crashes in the form of changing log file.

`New cgminer process started, changing to new logfile C:\cgminer\logs\2014-01-08_07-37.log`

If you're having trouble getting it to work you could try the debug mode to see what the problem is. Enable the debug mode by adding `-debug $true` as a parameter to cgminer-keep-alive.ps1.

Installation
==================

Prerequisites: Powershell 2.0+<br>
Windows XP+<br>
cgminer (Testing various versions, but anything above 3.5 should generally work)<br>

Download the master.zip file and extract the contents to where cgminer.exe is located (in my case it's c:\cgminer). If you want to keep the files somewhere you have to edit cgminer-keep-alive.ps1 as described in <b><a href="#configuration">Configuration</a><b>.

Configuration
==================

<b>startmine.bat</b>

Add your pool's configuration and other cgminer parameters. Make sure to leave `>2>%logoutput%` in, otherwise no log is created and cgminer-keep-alive won't work. If you don't want to keep the files together with you cgminer files you can change `cd %~dp0` to `cd (wherever cgminer.exe is)` (e.g. C:\some\other\path).

<b>cgminer-keep-alive.ps1</b>

If you didn't keep the cgminer-keep-alive files within the same folder as cgminer.exe you have to edit the path manually.

```powershell
Function startcgminer() {
    $process = "C:\cgminer\startmine.bat"
    $basepath = "C:\cgminer\logs"
    
    ...
}
```

The $process variable is the path to startmine.bat and $basepath is to the directory where the logs will be placed.
You can completely omit the batch file if you want, for example:

```powershell
Function startcgminer() {
    $process = "C:\path\to\cgminer.exe"
    ...
    $arguments = "-o mypoolsettings -u myworker.1 -p myworkerpassword 2>$basepath\$datetime.log"
    ...
}
```
or if you have configured a cgminer.conf you could just run 

```powershell
Function startcgminer() {
    $process = "C:\path\to\cgminer.exe"
    ...
    $arguments = "2>$basepath\$datetime.log"
    ...
}
```

Although this requires for cgminer-keep-alive.ps1 to be in the same folder as cgminer.exe and cgminer.conf, or that they are available in your PATH.
