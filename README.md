cgminer-keep-alive
==================

Powershell script (with accompanying batch file) that parses cgminer's log and restarts the application when it hangs/crashes. It will try to kill all cgminer processes and spawn a new instance whenever it detects a bad word (customizable, see <a href="#configuration">Configuration</a>). If it fails to do so within 10 attempts it can optionally restart the server.

Support to handle multiple instances of cgminer is planned.

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

Before you start you have to set Powershell's execution policy, otherwise it will refuse to run the script. Execute the following command in an administrative Powershell shell.

```powershell
Set-ExecutionPolic Unrestricted
```

Close all open Powershell shells and open them again so the new execution policy is loaded.

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

<b>Restart server if cgminer process can not be killed</b>
Sometimes cgminer hangs and can not be killed other than by restarting the computer. Just uncomment  ```Restart-Computer``` in the following section:

```powershell
If(killcgminer) { #if killcgminer was successful then start cgminer again
    $logfile = startcgminer
        log "New cgminer process started, changing to new logfile $logfile"
    } else {
        log "Could not restart cgminer. Server in need of reboot..."
        #Restart-Computer -Force #the zombie processes could not be killed, restarting server
}
```

<b>Configure "bad" words </b>
```powershell
$badwords = @('SICK!','DEAD','killing');
```

Just add more words to the array. Example

```powershell
$badwords = @('SICK!','DEAD','killing','Failure','Error','AnotherWord');
```

Run cgminer-keep-alive
==================

Running cgminer-keep-alive is as simple as running:

```powershell
.\cgminer-keep-alive.ps1
````

cgminer-keep-alive will check for existing cgminer instances when it starts and spawn a new instance if it can't find any. Make sure that you have <b>closed all instances of cgminer before starting cgminer-keep-alive</b>, otherwise the script will exit.

If you already have an instance of cgminer running just point cgminer-keep-alive to cgminer's logfile and it will start monitoring.

```powershell
.\cgminer-keep-alive.ps1 -logfile C:\cgminer\logs\cgminer.log
```

If you omit the ```-logfile C:\path\to\cgminer.log``` parameter cgminer-keep-alive will try to spawn a new instance of cgminer if no existing cgminer processes are running.

<b>Start cgminer-keep-alive on system startup</b>

The easiest way to start cgminer-keep-alive with Windows is just to create a shortcut to cgminer-keep-alive.ps1 and place it in your Startup folder which is located at: C:\Users\%username%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup

Known issues
==================
Double output when a new cgminer instance is spawned and the scripts switches to the new log file


Planned features
==================

* Support for multiple cgminer instances
* Ability to an send email when cgminer crasches.
