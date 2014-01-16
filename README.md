cgminer-keep-alive
==================

Powershell script (with accompanying batch file) that parses cgminer's log and restarts the application when it hangs/crashes. It will try to kill all cgminer processes and spawn a new instance whenever it detects a "bad" word (customizable, see <a href="#configuration">Configuration</a>). If it fails to do so within 10 attempts it can optionally restart the server (also configurable).

Support to handle multiple instances of cgminer is planned but as of now it can only handle 1 process at a time.

Output
==================

cgminer-keep-alive produces very little output. The default settings only output a start message and whenever cgminer crashes in the form of changing log file.

`New cgminer process started, changing to new logfile C:\cgminer\logs\2014-01-08_07-37.log`

If you're having trouble getting it to work you could try the debug mode to see what the problem is. Enable the debug mode by adding `-debug $true` as a parameter to cgminer-keep-alive.ps1.

cgminer-keep-alive creates new logfiles with a datetime format (yyyy-MM-dd_HH-mm)

Installation
==================

Prerequisites: Powershell 2.0+<br>
Windows XP+<br>
cgminer (Testing various versions, but anything above 3.5 should generally work)<br>

Download the master.zip file and extract the contents to where cgminer.exe is located (in my case it's c:\cgminer). If you want to keep the files somewhere you have to edit cgminer-keep-alive.ps1 as described in <a href="#configuration">configuration</a>.

Configuration
==================

Before you start you have to set Powershell's execution policy, otherwise it will refuse to run the script.

Option 1 - Administrative permissions required
------------------
Execute the following command in an administrative Powershell shell.

```powershell
Set-ExecutionPolicy Unrestricted
```

Close all open Powershell shells and open them again so the new execution policy is loaded.

Option 2 - Administrative permissions NOT required
------------------

If you can't set the execution policy or simply don't want to you can set it at runtime if you launch powershell with ```-ExecutionPolicy Bypass```

You can create a shortcut which does this:

```
Target: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy ByPass -File C:\cgminer\cgminer-keep-alive.ps1
Start in: C:\cgminer
```

Then all you have to do is launch that shortcut!

<b>Using startmine.bat</b>

Add your pool's configuration and other cgminer parameters. Make sure to leave `>2>%logoutput%` in, otherwise no log is created and cgminer-keep-alive won't work. If you don't want to keep the files together with you cgminer files you can change `cd %~dp0` to `cd (wherever cgminer.exe is)` (e.g. C:\some\other\path).

<b>cgminer-keep-alive.ps1</b>

If you didn't want to keep cgminer-keep-alive in C:\cgminer you have to edit the path manually.

```powershell
Function startcgminer() {
    $process = "C:\cgminer\startmine.bat"
    $basepath = "C:\cgminer\logs"
    
    ...
}
```

The $process variable is the path to startmine.bat and $basepath is to the directory where the logs will be placed.

<b>Run without batch file</b><br>
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
    $arguments = "--config C:\path\to\cgminer.conf 2>$basepath\$datetime.log"
    ...
}
```

Although can be problematic if cgminer-keep-alive.ps1 isn't in the same folder as cgminer.exe.

<b>Restart server if cgminer process can not be killed</b>
Sometimes cgminer hangs and can not be killed other than by restarting the computer. Just uncomment  ```Restart-Computer``` in the following section:

```powershell
If(killcgminer) { #if killcgminer was successful then start cgminer again
    $logfile = startcgminer
        log "New cgminer process started, changing to new logfile $logfile"
    } else {
        log "Could not restart cgminer. Server in need of reboot..."
        #Restart-Computer -Force #the processes could not be killed, restarting server
}
```

<b>Configure "bad" words </b>
```powershell
$badwords = @('SICK!','DEAD','killing');
```

Just add more words to the array. The log checking is caps insensitive. Note that the word can not be a string (contain spaces) as the script reads the log one word at a time (and a word can not contain a space). So for example if you want to check for "HW error" I suggest you just use "error". Support for strings is a planned feature.

Example

```powershell
$badwords = @('SICK!','DEAD','killing','Failure','Error','Another','Set','Of','Words');
```

Run cgminer-keep-alive
==================

Running cgminer-keep-alive is as simple as running:

```
.\cgminer-keep-alive.ps1
```

cgminer-keep-alive will check for existing cgminer instances when it starts and spawn a new instance if it can't find one. Make sure that you have <b>closed all instances of cgminer before starting cgminer-keep-alive</b>, otherwise the script will exit.

If you already have an instance of cgminer running just point cgminer-keep-alive to cgminer's logfile and it will start monitoring.

```
.\cgminer-keep-alive.ps1 -logfile C:\cgminer\logs\cgminer.log
```

<b>Start cgminer-keep-alive on system startup</b>

The easiest way to start cgminer-keep-alive with Windows is just to create a shortcut to cgminer-keep-alive.ps1 and place it in your Startup folder which is located at: C:\Users\%username%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup

Known issues
==================
* The debug mode's log outputs to the current directory, it must be writeable or multiple error messages will be thrown.
* WerFault.exe and cmd.exe sometimes don't close when cgminer is killed (or close too quickly and an error that the process couldn't be found is thrown) - This can be ignored as the script will catch them next time around.

Planned features
==================
* Support for multiple cgminer instances
* Support for checking against strings instead of words
* Optionally send an email when cgminer crasches.
* Save program log to a file with configurable path (normal and debug mode)
* Better-looking output
* Fully support having cgminer-keep-alive and cgminer in different folders when running without a batch file
