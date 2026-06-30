@echo off
cd %~dp0
cls

SRBMiner-MULTI.exe -ag pearlhash -o us3.pearl.herominers.com:1200,us2.pearl.herominers.com:1200,us.pearl.herominers.com:1200 -u prl1pk7azcw4hujpslw7r4nr8qzgzuz28e8fezf2xz40z99g3gc4ddg5sj7whvj+mdl1p3l9dcrzmyzvd2mllpdepzgysqvrmjx0q525vvnjewsapy0pg7gmshc4lrx --worker 1x5070Ti-7950X3D --tls true,true,true --gpu-cclock0 2025 --gpu-coffset0 270 --gpu-mclock0 7001 --gpu-moffset0 0 --disable-gpu-amd
pause
