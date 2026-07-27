@echo off
cd %~dp0
cls

SRBMiner-MULTI.exe --algorithm-cpu randomepic --algorithm-cpu randomx --pool stratum.xdagreef.org:3344 --pool randomxmonero.auto.nicehash.com:443 --wallet platinum4 --wallet 32YL1SYLixS2eGmL6qdFgtRBgVuAoMaTGx.1x5070Ti-7950X3D --password epiccash --password x --nicehash false;true --tls false;true
pause