:: This is an example you can edit and use
:: There are numerous parameters you can set, please check Help and Examples folder

@echo off
cd %~dp0
cls

SRBMiner-MULTI.exe --algorithm yespowerinterchained --pool us-tx01.miningrigrentals.com:50511 --wallet platinumstephen.322258 --disable-gpu --disable-worker-watchdog --retry-time 5 --nicehash false 
pause