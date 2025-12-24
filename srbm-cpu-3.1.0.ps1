<#
MindMiner  Copyright (C) 2019-2024  Oleg Samsonov aka Quake4
https://github.com/Quake4/MindMiner
License GPL-3.0
#>

if ([Config]::ActiveTypes -notcontains [eMinerType]::CPU) { exit }
if (![Config]::Is64Bit) { exit }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$extraThreads = $null
$extraCores = $null
if ([Config]::DefaultCPU) {
	$extraThreads = "--cpu-threads $([Config]::DefaultCPU.Threads)"
	$extraCores = "--cpu-threads $([Config]::DefaultCPU.Cores)"
}
<# else {
	$extraThreads = "--cpu-threads $(($Devices[[eMinerType]::CPU]| Measure-Object Threads -Sum).Sum)"
	$extraCores = "--cpu-threads $(($Devices[[eMinerType]::CPU]| Measure-Object Cores -Sum).Sum)"
}#>

$hasGPU = [Config]::ActiveTypes -contains [eMinerType]::AMD -or [Config]::ActiveTypes -contains [eMinerType]::nVidia

$Cfg = ReadOrCreateMinerConfig "Do you want use to mine the '$Name' miner" ([IO.Path]::Combine($PSScriptRoot, $Name + [BaseConfig]::Filename)) @{
	Enabled = $true
	BenchmarkSeconds = 120
	ExtraArgs = $null
	Algorithms = @(
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "argon2d_16000" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "argon2d_dynamic" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "argon2id_chukwa" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "argon2id_chukwa2" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "cpupower"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "cryptonight_ccx" }
		#[AlgoInfoEx]@{ Enabled = !$hasGPU; Algorithm = "cryptonight_gpu" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "cryptonight_turtle" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "cryptonight_upx"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "cryptonight_xhv" } # L3 limit
		[AlgoInfoEx]@{ Enabled = !$hasGPU; Algorithm = "curvehash"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "flex" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "ghostrider"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "lyra2v2_webchain" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "mike" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "minotaurx"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "panthera"; ExtraArgs = $extraCores }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "randomalpha" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "randomarq"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "randomepic" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "randomhscx" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "randomjuno" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "randomscash" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "randomsfx"; ExtraArgs = $extraCores }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "randomvirel" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "randomx"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "randomxeq" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "randomy"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "randomyada" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "rinhash" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "tht" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "verushash"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "xelishash" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "xelishashv3" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "xelishashv2_pepew" }
		[AlgoInfoEx]@{ Enabled = $false; Algorithm = "yescrypt"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $false; Algorithm = "yescryptr16"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $false; Algorithm = "yescryptr32"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $false; Algorithm = "yescryptr8" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "yespower"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "yespoweradvc"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "yespower2b"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "yespoweric"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "yespowerltncg"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "yespowermgpc"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "yespowerr16"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "yespowersugar"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "yespowertide"; ExtraArgs = $extraThreads }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "yespowerurx"; ExtraArgs = $extraCores }
)}

if (!$Cfg.Enabled) { return }

$port = [Config]::Ports[[int][eMinerType]::CPU]

$Cfg.Algorithms | ForEach-Object {
	if ($_.Enabled) {
		$Algo = Get-Algo($_.Algorithm)
		if ($Algo) {
			# find pool by algorithm
			$Pool = Get-Pool($Algo)
			if ($Pool) {
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
#                if ("randomx" -contains $_.Algorithm) { $_.Algorithm = "randomalpha" }
#                if ("cpupower" -contains $_.Algorithm) { $_.Algorithm = "yespowerr16" }
#                if ("argon2id_chukwa2" -contains $_.Algorithm) { $_.Algorithm = "argon2id_chukwa" }
                if ("thought" -contains $_.Algorithm) { $_.Algorithm = "tht" }
                if ("xelishash" -contains $_.Algorithm) { $_.Algorithm = "xelishashv3" }
#                if ("xelishashv2_pepew" -contains $_.Algorithm) { $_.Algorithm = "xelishashv2" }
				if (("tht") -contains $_.Algorithm) { $fee = 5 }
				elseif (("xhash") -contains $_.Algorithm) { $fee = 3 }
				elseif (("flex", "randomhscx", "yespowereqpay") -contains $_.Algorithm) { $fee = 2 }
				elseif (("xelishash", "xelishashv3", "xelishashv2_pepew") -contains $_.Algorithm) { $fee = 1.5 }
				elseif (("autolykos2", "blake3_decred", "fphash", "karlsenhashv2", "nxlhash", "randomalpha", "randomy", "rinhash", "verthash", "walahash") -contains $_.Algorithm) { $fee = 1 }
				elseif (("ethash", "etchash", "sha3x") -contains $_.Algorithm) { $fee = 0.65 }
				elseif (("yespowerurx") -contains $_.Algorithm) { $fee = 0 }

				if ("randomscash" -contains $_.Algorithm -and $Pool.Name -match "mrr") {
                [MinerInfo]@{
					Pool = $Pool.PoolName()
					PoolKey = $Pool.PoolKey()
					Priority = $Pool.Priority
					Name = $Name
					Algorithm = $Algo
					Type = [eMinerType]::CPU
					API = "srbm2dual"
					URI = "https://github.com/doktor83/SRBMiner-Multi/releases/download/3.1.0/SRBMiner-Multi-3-1-0-win64.zip"
					Path = "$Name\SRBMiner-MULTI.exe"
					ExtraArgs = $extrargs
					Arguments = "--algorithm $($_.Algorithm);tht --pool $pools;lab.viporlab.net:5185 --wallet $($Pool.User);41hyEs465UqdXTZU9wdCraG6V8jLA7JCbP.AA --password $($Pool.Password);x --tls $tls;true -t 32;1 --cpu-threads-intensity 1;32 --api-enable --api-port $port --miner-priority 1 --disable-gpu --disable-worker-watchdog --retry-time $($Config.CheckTimeout) $nicehash $extrargs"
					Port = $port
					BenchmarkSeconds = if ($_.BenchmarkSeconds) { $_.BenchmarkSeconds } else { $Cfg.BenchmarkSeconds }
					RunBefore = $_.RunBefore
					RunAfter = $_.RunAfter
					Fee = $fee
				    }
                }
                else {
                [MinerInfo]@{
					Pool = $Pool.PoolName()
					PoolKey = $Pool.PoolKey()
					Priority = $Pool.Priority
					Name = $Name
					Algorithm = $Algo
					Type = [eMinerType]::CPU
					API = "srbm2"
					URI = "https://github.com/doktor83/SRBMiner-Multi/releases/download/3.1.0/SRBMiner-Multi-3-1-0-win64.zip"
					Path = "$Name\SRBMiner-MULTI.exe"
					ExtraArgs = $extrargs
					Arguments = "--algorithm $($_.Algorithm) --pool $pools --wallet $($Pool.User) --password $($Pool.Password) --tls $tls --api-enable --api-port $port --miner-priority 1 --disable-gpu --disable-worker-watchdog --retry-time $($Config.CheckTimeout) $nicehash $extrargs"
					Port = $port
					BenchmarkSeconds = if ($_.BenchmarkSeconds) { $_.BenchmarkSeconds } else { $Cfg.BenchmarkSeconds }
					RunBefore = $_.RunBefore
					RunAfter = $_.RunAfter
					Fee = $fee
				    }
                }
			}
		}
	}
}