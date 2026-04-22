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
		@{ Enabled = $true; Algorithm = "autolykos2"; DualAlgorithm = "blake3_decred" }
		@{ Enabled = $true; Algorithm = "autolykos2"; DualAlgorithm = "heavyhash" }
		@{ Enabled = $true; Algorithm = "autolykos2"; DualAlgorithm = "sha256dt" }
		@{ Enabled = $true; Algorithm = "autolykos2"; DualAlgorithm = "sha3x" }
		@{ Enabled = $true; Algorithm = "autolykos2"; DualAlgorithm = "walahash" }
		@{ Enabled = $true; Algorithm = "etchash"; DualAlgorithm = "blake3_decred" }
		@{ Enabled = $true; Algorithm = "etchash"; DualAlgorithm = "heavyhash" }
		@{ Enabled = $true; Algorithm = "etchash"; DualAlgorithm = "sha256dt" }
		@{ Enabled = $true; Algorithm = "ethash"; DualAlgorithm = "blake3_decred" }
		@{ Enabled = $true; Algorithm = "ethash"; DualAlgorithm = "heavyhash" }
		@{ Enabled = $true; Algorithm = "ethash"; DualAlgorithm = "sha256dt" }
		@{ Enabled = $true; Algorithm = "ethashb3"; DualAlgorithm = "blake3_decred" }
		@{ Enabled = $true; Algorithm = "ethashb3"; DualAlgorithm = "heavyhash" }
		@{ Enabled = $true; Algorithm = "ethashb3"; DualAlgorithm = "sha256dt" }
		@{ Enabled = $true; Algorithm = "fishhash"; DualAlgorithm = "blake3_decred" }
		@{ Enabled = $true; Algorithm = "fishhash"; DualAlgorithm = "sha3x" }
)}

if (!$Cfg.Enabled) { return }

$port = [Config]::Ports[[int][eMinerType]::nVidia]

$Cfg.Algorithms | ForEach-Object {
	if ($_.Enabled) {
		$Algo = Get-Algo($_.Algorithm)
		$AlgoDual = Get-Algo($_.DualAlgorithm)
		if ($Algo -and $AlgoDual -and !($Pool.Name -match "mph" -and ("ethash", "etchash") -contains $_.Algorithm)) {
			# find pool by algorithm
			$Pool = Get-Pool($Algo)
			$PoolDual = Get-Pool($AlgoDual)
			if ($Pool -and $PoolDual) {
				$extrargs = Get-Join " " @($Cfg.ExtraArgs, $_.ExtraArgs)
				<#$nicehash = "--nicehash false"
				if ($Pool.Name -match "nicehash") {
					$nicehash = "--nicehash true"
				}#>
				$tls = "false"
				if ($Pool.Protocol -match "ssl") { $tls = "true" }
				$pools = [string]::Empty
				$Pool.Hosts | ForEach-Object {
					$pools = Get-Join "!" @($pools, "$_`:$($Pool.Port)")
				}
				$tlsDual = "false"
				if ($PoolDual.Protocol -match "ssl") { $tlsDual = "true" }
				$poolsDual = [string]::Empty
				$PoolDual.Hosts | ForEach-Object {
					$poolsDual = Get-Join "!" @($poolsDual, "$_`:$($PoolDual.Port)")
				}
				$fee = 0.85
                if ("sccpow" -contains $_.Algorithm) { $_.Algorithm = "firopow" }
				if (("xhash") -contains $_.Algorithm) { $fee = 3 }
				elseif (("dutahashv4", "flex", "yespowereqpay") -contains $_.Algorithm) { $fee = 2 }
				elseif (("xelishash", "xelishashv3") -contains $_.Algorithm) { $fee = 1.5 }
				elseif (("autolykos2", "blake3_decred", "karlsenhashv2", "randomalpha", "randomy", "rinhash", "verthash", "walahash") -contains $_.Algorithm) { $fee = 1 }
				elseif (("ethash", "etchash") -contains $_.Algorithm) { $fee = 0.65 }
				elseif (("yespowerurx") -contains $_.Algorithm) { $fee = 0 }
				[MinerInfo]@{
					Pool = $(Get-FormatDualPool $Pool.PoolName() $PoolDual.PoolName())
					PoolKey = "$($Pool.PoolKey())+$($PoolDual.PoolKey())"
					Priority = $Pool.Priority
					DualPriority = $PoolDual.Priority
					Name = $Name
					Algorithm = $Algo
					DualAlgorithm = $AlgoDual
					Type = [eMinerType]::nVidia
					API = "srbm2"
					URI = "https://github.com/doktor83/SRBMiner-Multi/releases/download/3.2.6/SRBMiner-Multi-3-2-6-win64.zip"
					Path = "$Name\SRBMiner-MULTI.exe"
					ExtraArgs = $extrargs
					Arguments = "--algorithm $($_.Algorithm) --pool $pools --wallet $($Pool.User) --password $($Pool.Password) --tls $tls --algorithm $($_.DualAlgorithm) --pool $poolsDual --wallet $($PoolDual.User) --password $($PoolDual.Password) --tls $tlsDual --api-enable --api-port $port --disable-cpu --disable-gpu-amd --disable-gpu-intel --disable-worker-watchdog --retry-time $($Config.CheckTimeout) $extrargs"
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