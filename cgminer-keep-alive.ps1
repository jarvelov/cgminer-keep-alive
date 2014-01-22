<#
.SYNOPSIS
    A watchdog-ish script for cgminer.
.DESCRIPTION
    Catch when cgminer hangs and quickly restart it to get your mining back on.
    Get updated info at the project github: https://github.com/dbsnurr/cgminer-keep-alive/
.PARAMETER logfile
    The path to cgminers logfile. Only use this parameter when cgminer is already running.
    If you omit the parameter cgminer-keep-alive will start cgminer for you.
.PARAMETER debug
    Enabled debug output. Note: debug also writes all cgminer-keep-alive output to a file in the current directory.
.EXAMPLE
    C:\PS> .\cgminer-keep-alive.ps1
    Running the script without the logfile parameter will make cgminer-keep-alive start cgminer,
    given that there are no other instances of the program currently running.

    C:\PS> .\cgminer-keep-alive.ps1 -logfile C:\cgminer\logs\log.txt
    Passing the -logfile parameter will set cgminer-keep-alive to parse the given file.
    With this option cgminer-keep-alive expects the cgminer process to be running already.
.NOTES
    Author: dbsnurr
    Date:   2014-01-08
    URL: https://github.com/dbsnurr/cgminer-keep-alive
#>
param (
    [string]$logfile,
    [string]$debug = $false
)

Function log($output) {
    $timestamp = (Get-Date -Format "yyyy-MM-dd_HH:mm:ss") 
    Write-Host "$timestamp $output"
    Add-Content -Path ".\cgminer-keep-alive.log" -Value "$timestamp $output"
}

Function logdebug($output) {
    If($debug -eq $true){
        $timestamp = (Get-Date -Format "yyyy-MM-dd_HH:mm:ss") 
        Write-Host "$timestamp $output"
        Add-Content -Path ".\cgminer-keep-alive-debug.log" -Value "$timestamp $output"
    }
}

Function processinstances($process) {
    [int]$numinst = (Get-Process $process -ErrorAction SilentlyContinue | Group-Object -Property $process).count
    logdebug "$numinst instance(s) of process $process is running"
    return $numinst
}

Function killprocess($process) {
    $status = $false

    logdebug "Attempting to kill process $process"
    Try { 
        Stop-Process -Name $process -Force -Confirm:$false -ErrorAction Stop
        $status = $true
    } Catch {
        logdebug "Could not terminate process $process"+$_.Exception
        $status = $false
    }
    return $status
}

Function killcgminer($attempt = 0) {
    $max = 5
    $wait = 3
    $status = $false #we don't want to give false hope!
    $processes = @('cgminer') #processes will be killed in order from left to right

    #only retry if less than $max attempts to kill the process have been made 
    If($attempt -lt $max) {
        #count the number of process instances

        Foreach($process in $processes) {
            If((processinstances $process) -ge 1) {#cgminer processes found, killing it            
                $attempt+=1
                
                Try { 
                    Sleep $wait #sleeping between killing processes is optional but recommended
                    logdebug "Attempt $attempt of $max to kill cgminer"
                    $status = killprocess $process
                     
                } Catch {
                    logdebug "Could not terminate process $process. Attempt $attempt of $max"
                    killcgminer $attempt
                }
            } else {
                logdebug "No cgminer processes are currently running. Nothing to kill"
                $status = $true
            }
        } 
    } else {
        logdebug "Unable to kill all processes. Discontinuing further attempts to kill the processes"
        $status = $false
    }
    return $status
}

Function restartcomputer {
    if ($restartallowed) {
        log "Server in need of reboot! Going down!"
        Restart-Computer -Force
    } else {
        log "Restart not permitted! Change restartallowed variable to true to allow it"
    }
}

Function restartcgminer() {
    $status = killcgminer
    If($status) { #if killcgminer was successful then start cgminer again
        $loglength = $null
        $logfile = startcgminer
        log "New cgminer process started, changing to new logfile $logfile"
        return $logfile
    } else {
        log "Could not restart cgminer. Server in need of reboot..." #the processes could not be killed, restarting server
        restartcomputer
    }
}

Function startcgminer() {
    $process = "C:\cgminer\startmine.bat"
    $logpath = "C:\cgminer\logs"

    $datetime = (Get-Date -Format "yyyy-MM-dd_HH-mm")
    $logfile = "$logpath\$datetime.log"
    $arguments = $logfile

    If(!(Test-Path $logpath)) {
        logdebug "Directory $logpath does not exist, will create it now"
        Try {
            New-Item -ItemType Directory -Path $logpath
        } Catch {
            log "Could not create new directory with path $logpath"
        }
    }

    Try {
        logdebug "Starting new process $process with arguments $arguments"
        Start-Process -FilePath $process -ArgumentList $arguments
        return $logfile #return the new logfile's location to start parsing that file
    } Catch {
        logdebug "Could not start new instance of cgminer."
    }
}

#check if cgminer is already running
Function cgmineralive() { 
    $numcgminer = processinstances "cgminer"
    If($numcgminer -ge 1) {
        logdebug "Looks like cgminer is running"
        return $true
    } else { 
        logdebug "Looks like cgminer isn't running"
        return $false
    }
}

#is it allowed to restart the server if application hangs and cannot be killed
$restartallowed = $false

#add more words if you want!
$badwords = @('SICK!','DEAD','killing'); #give kill signal to cgminer and then attempt to restart it
$naughtywords = @('hang.','hard') #restart server without any attempt to restart cgminer

$wait = 30 #changes the speed of the cycle:
#changing to lower or higher values will affect the overall speed of the script, not just the log checking frequency.
#how much time cgminer has to write new log output before killing it/restart server
#how much time cgminer has to die before server reboots to prevent a hard hang/freeze of the server
#lower values will consume more processing power and might even make your server freeze if set too low

$maxcount = 5 #how many cycles of idle log is allowed
$count = 0 #

#do not change the values below unless you know what you're doing
$loglength = $null
$action = $null
$j = 0
$i = 0

$status = cgmineralive
If(($logfile) -And ($status)) {
    logdebug "Path to an existing log was passed as an argument and a cgminer process was found."
} elseif (!($logfile) -And (!($status))) {
    $logfile = startcgminer
    logdebug "cgminer was not running but is now started since no logfile argument was passed to script (possibly because the user omitted it or the program crashed)"
} elseif (!($logfile) -And ($status)) {
    log "No logfile was passed to the script and cgminer is currently running. To let the script auto start cgminer please exit all instances of it first."
}

log "Starting up cgminer keep alive 0.1.1"
log "Checking for cgminer process and parsing the logfile $logfile every $wait seconds."
if(!($debug)) { log "Add the argument `"-debug $true`" if you want to show debug output." }

while ($j -eq 0) { #initializing the infinite loop
    $i+=1
    $bad = $null
    $naughty = $null
    logdebug "$i cycles since start"
    logdebug "Parsing log $logfile"
    Sleep $wait #wait between each cycle

    Try {
        $content = Get-Content $logfile
        [int]$rows = $content.count
    } Catch {
        log "Can not read contents of file $logfile! Check the path and permissions!"
        Break
    } Finally {
        $isalive = cgmineralive
        if($isalive) {
            logdebug "cgminer is currently running"
            if($loglength -ne $null) {
                if ($loglength -lt $rows) {
                    logdebug "Log is larger $rows than last time $loglength. All seems well."
                    $loglength = $rows
                } else {
                    $count+=1
                    logdebug "Log is smaller $rows or equal to last round $loglength. $count of $maxcount"
                    if($count -ge $maxcount) {
                        logdebug "Log has been smaller than or equal to last cycle $count times. Restarting cgminer."
                        $logfile = restartcgminer
                        $loglength = $null
                        $count = 0
                    }
                }
            } else {
                $loglength = $rows
                logdebug "log length is null, program probably just started, assigning new value."
            }
        } else {
            logdebug "No instances of cgminer was found. Starting up cgminer now."
            $loglength = $null
            $logfile = startcgminer
        }
    }
    
    #Read the logfile and parse the content
    Foreach ($row in $content) {
        $rowwords = $row -Split "\s+"
        Foreach ($badword in $rowwords) { #checking if a word in the log matches one in the $badwords array
            If($naughtywords -contains $badword) { 
                logdebug "Detected a naughty word in log $logfile. The naughty word is: $badword"
                $naughty = $true
            } else {
                #logdebug "$badword is not a naughty word" #do not uncomment this line as it might make your computer bluescreen
            }
            If($badwords -contains $badword) { 
                logdebug "Detected a bad word in log $logfile. The bad word is: $badword"
                $bad = $true
            } else {
                #logdebug "$badword is not a bad word" #do not uncomment this line as it might make your computer bluescreen
            }
        }
    }

    If(($bad) -And (!($naughty))) {
    $action = 1
    } elseif ($naughty) {
        $action = 0
    } else {
        $action = $null
    }
        switch ($action) {
            0 { restartcomputer }
            1 { $action = $null; $logfile = restartcgminer; $loglength = $null;  }
            $null { logdebug "No bad or naughty words detected" }       
        }
    }

