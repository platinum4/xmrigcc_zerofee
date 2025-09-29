<#
MindMiner  Copyright (C) 2018-2023  Oleg Samsonov aka Quake4
https://github.com/Quake4/MindMiner
License GPL-3.0
#>

if ([Config]::ActiveTypes -notcontains [eMinerType]::nVidia -and [Config]::ActiveTypes -notcontains [eMinerType]::AMD) { exit }
if (![Config]::Is64Bit) { exit }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Cfg = ReadOrCreateMinerConfig "Do you want use to mine the '$Name' miner" ([IO.Path]::Combine($PSScriptRoot, $Name + [BaseConfig]::Filename)) @{
	Enabled = $true
	BenchmarkSeconds = 120
	ExtraArgs = $null
	Algorithms = @(
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "aeternity" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "aleph" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "autolykos2" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "aion" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "beamv3" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "cortex" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "cuckaroo29" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "cuckatoo31" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "cuckatoo32" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "equihash125" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "equihash144" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "equihash192" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "etchash" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "ethash" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "ethashb3" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "fishhash" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "karlsenhashv2" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "nexa" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "pyrin" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "pyrinv2" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "radiant" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "sha3x" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "ton" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "ubqhash" }
)}

if (!$Cfg.Enabled) { return }

$url = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/1.98a/lolMiner_v1.98a_Win64.zip"
$nocolor = if ([Environment]::OSVersion.Version.Major -le 6) { "--nocolor=on " } else { [string]::Empty }

$port_amd = [Config]::Ports[[int][eMinerType]::AMD]
$port_nv = [Config]::Ports[[int][eMinerType]::nVidia]

$Cfg.Algorithms | ForEach-Object {
	if ($_.Enabled) {
		$Algo = Get-Algo($_.Algorithm)
		if ($Algo -and $_.Algorithm -notmatch "zhash" -and $_.Algorithm -notmatch "equihashZCL") {
			# find pool by algorithm
			$Pool = Get-Pool($Algo)
			if ($Pool) {
				$extrargs = Get-Join " " @($Cfg.ExtraArgs, $_.ExtraArgs)
				$coin = [string]::Empty
				$fee = 1
				if ($extrargs -notmatch "--coin" -and $extrargs -notmatch "--algo") {
					switch ($_.Algorithm) {
						"autolykos2" { $coin = "--algo AUTOLYKOS2"; $fee = 1.5 }
						"aeternity" { $coin = "--algo C29AE"; $fee = 2 }
						"aion" { $coin = "--algo EQUI210_9" }
						"beamv3" { $coin = "--algo BEAM-III" }
						"cortex" { $coin = "--coin CTXC"; $fee = 2.5 }
						"cuckaroo29" { $coin = "--algo CR29"; $fee = 2 }
						"cuckatoo31" { $coin = "--algo C31"; $fee = 2 }
						"cuckatoo32" { $coin = "--algo C32"; $fee = 2 }
						"equihash125" { $coin = "--coin ZEL" }
						"equihash144" { $coin = "--coin AUTO144_5" }
						"equihash192" { $coin = "--coin AUTO192_7" }
						"equihash192" { $coin = "--coin AUTO192_7" }
						"etchash" { $coin = "--algo ETCHASH"; $fee = 0.7 }
						"ethash" { $coin = "--algo ETHASH"; $fee = 0.7 }
						"nexa" { $coin = "--algo NEXA"; $fee = 2 }
						"octopus" { $coin = "--algo OCTOPUS"; $fee = 2 }
						"ubqhash" { $coin = "--algo UBQHASH"; $fee = 0.7 }
						"zhash" { $coin = "--coin AUTO144_5" }
						default { $coin = "--algo $($_.ToUpper())" }
					}
				}
				$tls = "0"
				if ($Pool.Protocol -match "ssl") { $tls = "1" }
				$pools = [string]::Empty
				$user = $Pool.User
				if ($Pool.Name -match "mrr") {
					$user = $user.Replace(".", ":")
				}
				$Pool.Hosts | ForEach-Object {
					$pools = Get-Join " " @($pools, "--pool $_`:$($Pool.Port) --user $user --pass $($Pool.Password) --tls $tls")
				}
				if ($Pool.Name -notmatch "mrr" -and ($_.Algorithm -eq "ethash" -or $_.Algorithm -eq "etchash")) {
					$pools += " --worker $([Config]::WorkerNamePlaceholder)"
					if ($Pool.Name -match "mph" -or $Pool.Name -match "nicehash") {
						$pools += " --ethstratum ETHV1"
					}
				}
				[MinerInfo]@{
					Pool = $Pool.PoolName()
					PoolKey = $Pool.PoolKey()
					Priority = $Pool.Priority
					Name = $Name
					Algorithm = $Algo
					Type = [eMinerType]::nVidia
					TypeInKey = $true
					API = "lol2"
					URI = $url
					Path = "$Name\lolMiner.exe"
					ExtraArgs = $extrargs
					Arguments = "$coin $pools --apiport $port_nv --watchdog exit --timeprint 1 $nocolor`--devices NVIDIA $extrargs"
					Port = $port_nv
					BenchmarkSeconds = if ($_.BenchmarkSeconds) { $_.BenchmarkSeconds } else { $Cfg.BenchmarkSeconds }
					RunBefore = $_.RunBefore
					RunAfter = $_.RunAfter
					Fee = $fee
				}
				[MinerInfo]@{
					Pool = $Pool.PoolName()
					PoolKey = $Pool.PoolKey()
					Priority = $Pool.Priority
					Name = $Name
					Algorithm = $Algo
					Type = [eMinerType]::AMD
					TypeInKey = $true
					API = "lol2"
					URI = $url
					Path = "$Name\lolMiner.exe"
					ExtraArgs = $extrargs
					Arguments = "$coin $pools --apiport $port_amd --watchdog exit --timeprint 1 $nocolor`--devices AMD $extrargs"
					Port = $port_amd
					BenchmarkSeconds = if ($_.BenchmarkSeconds) { $_.BenchmarkSeconds } else { $Cfg.BenchmarkSeconds }
					RunBefore = $_.RunBefore
					RunAfter = $_.RunAfter
					Fee = $fee
				}
			}
		}
	}
}