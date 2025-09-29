<#
MindMiner  Copyright (C) 2019-2024  Oleg Samsonov aka Quake4
https://github.com/Quake4/MindMiner
License GPL-3.0
#>

if ([Config]::ActiveTypes -notcontains [eMinerType]::nVidia) { exit }
if (![Config]::Is64Bit) { exit }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Cfg = ReadOrCreateMinerConfig "Do you want use to mine the '$Name' miner" ([IO.Path]::Combine($PSScriptRoot, $Name + [BaseConfig]::Filename)) @{
	Enabled = $true
	BenchmarkSeconds = 120
	ExtraArgs = $null
	Algorithms = @(
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "autolykos2" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "blake3_decred" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "cryptonight_gpu" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "cryptonight_xhv" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "etchash" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "ethash" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "ethashb3" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "ethashr5" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "evrprogpow" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "fishhash" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "firopow" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "fphash" }
		[AlgoInfoEx]@{ Enabled = $([Config]::ActiveTypes -notcontains [eMinerType]::CPU); Algorithm = "heavyhash" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "karlsenhashv2" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "kawpow" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "lyra2v2_webchain" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "meowpow" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "nxlhash" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "phihash" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "progpow_epic" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "progpow_quai" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "progpow_sero" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "progpow_telestai" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "progpow_veil" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "progpow_zano" }
		[AlgoInfoEx]@{ Enabled = $([Config]::ActiveTypes -notcontains [eMinerType]::CPU); Algorithm = "sha3x" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "verthash" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "walahash" }
)}

if (!$Cfg.Enabled) { return }

$port = [Config]::Ports[[int][eMinerType]::nVidia]

$Cfg.Algorithms | ForEach-Object {
	if ($_.Enabled) {
		$Algo = Get-Algo($_.Algorithm)
		if ($Algo) {
			# find pool by algorithm
			$Pool = Get-Pool($Algo)
			if ($Pool -and !($Pool.Name -match "mph" -and ("ethash", "etchash") -contains $_.Algorithm)) {
				$extrargs = Get-Join " " @($Cfg.ExtraArgs, $_.ExtraArgs)
				$nicehash = "--nicehash false"
				if ($Pool.Name -match "nicehash") {
					$nicehash = "--nicehash true"
				}
				$tls = "false"
				if ($Pool.Protocol -match "ssl") { $tls = "true" }
				$pools = [string]::Empty
				$Pool.Hosts | ForEach-Object {
					$pools = Get-Join "!" @($pools, "$_`:$($Pool.Port)")
				}
				$fee = 0.85
                if ("sccpow" -contains $_.Algorithm) { $_.Algorithm = "firopow" }
				if (("ethashr5", "flex", "yespowereqpay") -contains $_.Algorithm) { $fee = 2 }
				elseif (("xelishash", "xelishashv2", "xelishashv2_pepew") -contains $_.Algorithm) { $fee = 1.5 }
				elseif (("autolykos2", "blake3_decred", "fphash", "karlsenhashv2", "nxlhash", "randomalpha", "randomy", "rinhash", "verthash", "walahash") -contains $_.Algorithm) { $fee = 1 }
				elseif (("ethash", "etchash", "sha3x") -contains $_.Algorithm) { $fee = 0.65 }
				elseif (("yespowerurx") -contains $_.Algorithm) { $fee = 0 }
#				if ($Pool.Name -match "mrr") {
				[MinerInfo]@{
					Pool = $Pool.PoolName()
					PoolKey = $Pool.PoolKey()
					Priority = $Pool.Priority
					Name = $Name
					Algorithm = $Algo
					Type = [eMinerType]::nVidia
					API = "srbm2"
					URI = "https://github.com/doktor83/SRBMiner-Multi/releases/download/2.9.8/SRBMiner-Multi-2-9-8-win64.zip"
					Path = "$Name\SRBMiner-MULTI.exe"
					ExtraArgs = $extrargs
					Arguments = "--algorithm $($_.Algorithm) --pool $pools --wallet $($Pool.User) --password $($Pool.Password) --tls $tls --api-enable --api-port $port --disable-cpu --disable-gpu-amd --disable-gpu-intel --disable-worker-watchdog $nicehash $extrargs"
					Port = $port
					BenchmarkSeconds = if ($_.BenchmarkSeconds) { $_.BenchmarkSeconds } else { $Cfg.BenchmarkSeconds }
					RunBefore = $_.RunBefore
					RunAfter = $_.RunAfter
					Fee = $fee
				    }
#                }
#                if ($Pool.Name -notmatch "mrr") {
#				[MinerInfo]@{
#					Pool = $Pool.PoolName()
#					PoolKey = $Pool.PoolKey()
#					Priority = $Pool.Priority
#					Name = $Name
#					Algorithm = $Algo
#					Type = [eMinerType]::nVidia
#					API = "srbm2dual"
#					URI = "https://github.com/doktor83/SRBMiner-Multi/releases/download/2.9.7/SRBMiner-Multi-2-9-7-win64.zip"
#					Path = "$Name\SRBMiner-MULTI.exe"
#					ExtraArgs = $extrargs
#					Arguments = "--algorithm progpow_epic;$($_.Algorithm) --pool 51pool.online:3416;$pools --wallet platinum4#1x5070-7950X3D;$($Pool.User) --password epiccash;$($Pool.Password) --multi-algorithm-job-mode 3 --tls false;$tls --api-enable --api-port $port --disable-cpu --disable-gpu-amd --disable-gpu-intel --disable-worker-watchdog $nicehash $extrargs"
#					Port = $port
#					BenchmarkSeconds = if ($_.BenchmarkSeconds) { $_.BenchmarkSeconds } else { $Cfg.BenchmarkSeconds }
#					RunBefore = $_.RunBefore
#					RunAfter = $_.RunAfter
#					Fee = $fee
#				    }
#                }
			}
		}
	}
}