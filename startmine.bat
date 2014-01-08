set logoutput=%1
cd %~dp0
setx GPU_MAX_ALLOC_PERCENT 100
cgminer.exe --scrypt --no-submit-stale -o stratum+tcp://pool:3333 -u myusername.1 -p x 2>%logoutput%
