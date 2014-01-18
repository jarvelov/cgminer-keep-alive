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

    C:\PS> .\cgminer-keep-alive.ps1 -logfile C:\cgminer\logs\
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
    $numinst = (Get-Process $process -ErrorAction SilentlyContinue | Group-Object -Property $process).count
    logdebug "$numinst instance(s) of process $process is running"
    return $numinst
}

Function killprocess($process) {
    Try {
        logdebug "Attempting to kill process $process"
        Stop-Process -Name $process -Force -Confirm:$false
        return $true
    } Catch {
        logdebug "Could not terminate process $process"
    }
}

Function killcgminer($attempt = 0) {
    $max = 10
    $wait = 3
    $status = $false #we don't want to give false hope!
    $processes = @('cgminer','WerFault') #processes will be killed in order from left to right

    #only retry if less than $max attempts to kill the process have been made 
    If($attempt -lt $max) {
        #count the number of process instances

        Foreach($process in $processes) {
            If((processinstances $process) -ge 1) {#cgminer processes found, killing it            
                $attempt+=1
                
                Try { 
                    killprocess $process
                    Sleep $wait #sleeping between killing processes is optional but recommended
                    logdebug "Attempt $attempt of $max to kill cgminer"
                } Catch {
                    logdebug "Could not terminate process $process. Attempt $attempt of $max"
                    killcgminer $attempt
                }
            } else {
                logdebug "No cgminer processes are currently running. Nothing to kill"
                $status = $true #no processes were running in the first place
            }
        } 
    } else {
        logdebug "Unable to kill all processes. Discontinuing further attempts to kill the processes"
        $status = $false
    }

    return $status
}


Function startcgminer() {
    $process = "C:\cgminer\startmine.bat"
    $basepath = "C:\cgminer\logs"

    $datetime = (Get-Date -Format "yyyy-MM-dd_HH-mm")
    $arguments = "$basepath\$datetime.log"

    Try {
        logdebug "Starting new process $process with arguments $arguments"
        Start-Process -FilePath $process -ArgumentList $arguments
        return $arguments #return the new logfile's location to start parsing that file
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

$loglength = $null
$badwords = @('SICK!','DEAD','killing'); #add more words if you want!
$wait = 30
$j = 0
$i = 0

$status = cgmineralive
If(($logfile) -And ($status)) {
    logdebug "Path to an existing log was passed as an argument and a cgminer process was found."
} elseif (!($logfile) -And (!($status))) {
    $logfile = startcgminer
    logdebug "cgminer was not running but is now started since no logfile argument was passed to script (possibly because the user omitted it or the program crashed)"
} else {
    log "No logfile was passed to the script and cgminer is currently running. To let the script auto start cgminer please exit all instances of it first."
}

log "Starting up cgminer keep alive 0.1!"
log "Checking for cgminer process and parsing the logfile $logfile every $wait seconds."
if(!($debug)) { log "Add the argument `"-debug $true`" if you want to show debug output." }

while ($j -eq 0) { #initializing the infinite loop
    $i+=1
    logdebug "$i cycles since start"
    logdebug "Parsing log $logfile"
    Sleep $wait #wait between each cycle

    Try {
        $content = Get-Content $logfile
    } Catch {
        log "Can not read contents of file $logfile! Check the path and permissions!"
        Break
    } Finally {
        $isalive = cgmineralive
        if($isalive) {
            logdebug "cgminer is currently running"
            if($loglength -ne $null) {
                if ($loglength -lt $content.count) {
                    logdebug "Log is larger $($content.count) than last time $loglength. All seems well."
                    $loglength = $content.count
                } else {
                    logdebug "Log is smaller $($content.count) or equal to last round $loglength. Trying to restart cgminer."
                    If(killcgminer) { #if killcgminer was successful then start cgminer again
                        $loglength = $null
                        $logfile = startcgminer
                        log "New cgminer process started, changing to new logfile $logfile"
                    } else {
                        log "Could not restart cgminer. Restarting server..."
                        Restart-Computer -Force #the processes could not be killed, restarting server
                    }
                }
            } else {
                $loglength = $content.count
                logdebug "log length is 0, program probably just started, assigning new value."
            }
        } else {
            logdebug "No instances of cgminer was found. Starting up cgminer now."
            $loglength = $null
            $logfile = startcgminer
            log "New cgminer process started, changing to new logfile $logfile"
        }
    }
    
    #Read the logfile and parse the content
    Foreach ($row in $content) {
        $rowwords = $row -Split "\s+"
        Foreach ($badword in $rowwords) {#checking if a word in the log matches one in the $badwords array
            If($badwords -contains $badword) { 
                logdebug "Detected a bad word in log $logfile. The bad word is: $badword"
                If(killcgminer) { #if killcgminer was successful then start cgminer again
                    $loglength = $null
                    $logfile = startcgminer
                    log "New cgminer process started, changing to new logfile $logfile"
                } else {
                    log "Could not restart cgminer. Restarting server..."
                    Restart-Computer -Force #the processes could not be killed, restarting server
                }
            }
        }
    }
}
