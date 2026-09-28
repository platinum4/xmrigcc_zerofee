@echo off

cd /d "%~dp0"

:loop
wildrig.exe --algo pearlhash --url pool.pearlhash.xyz:9000 --user prl1pk7azcw4hujpslw7r4nr8qzgzuz28e8fezf2xz40z99g3gc4ddg5sj7whvj@nock=6NWhmw5Ga4TrkpESEvdF41PM8AXHiG78eEgKgNSLpLJJjio5tK7pydi --worker 2x3060Ti-5950X --gpu-core-clock 1470 --gpu-core-offset 210 --gpu-memory-clock 5001

if ERRORLEVEL 1 goto custom
timeout /t 5
goto loop

:custom
echo Custom command here
timeout /t 5
goto loop