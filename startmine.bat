set logoutput=%1
cd %~dp0
setx GPU_MAX_ALLOC_PERCENT 100
cgminer.exe --scrypt --no-submit-stale -o stratum+tcp://pool:3333 -u myusername.1 -p x -I 19 -g 1 -w 256 --thread-concurrency 15232 2>%logoutput%
