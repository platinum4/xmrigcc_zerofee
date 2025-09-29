<#
MindMiner  Copyright (C) 2018-2023  Oleg Samsonov aka Quake4
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
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "anime" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "bmw512" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "curvehash" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "evrprogpow" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "firopow" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "ghostrider" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "memehash" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "meowpow" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "mike" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "nexapow" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "phihash" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "progpow-ethercore" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "progpow-quai" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "progpow-sero" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "progpow-telestai" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "progpow-veil" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "progpowz" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "qhash" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "vprogpow" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "sha256csm" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "sha512256d" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "skydoge" }
)}

if (!$Cfg.Enabled) { return }

$port = [Config]::Ports[[int][eMinerType]::nVidia]

$Cfg.Algorithms | ForEach-Object {
	if ($_.Enabled) {
		$Algo = Get-Algo($_.Algorithm)
		if ($Algo) {
			# find pool by algorithm
			$Pool = Get-Pool($Algo)
			if ($Pool) {
				$extrargs = Get-Join " " @($Cfg.ExtraArgs, $_.ExtraArgs)
				$hosts = [string]::Empty
				$Pool.Hosts | ForEach-Object {
					if ($Pool.Protocol -match "ssl") { $hosts = Get-Join " " @($hosts, "-o stratum+tcps://$_`:$($Pool.Port) -u $($Pool.User) -p $($Pool.Password)") }
                    else { $hosts = Get-Join " " @($hosts, "-o $_`:$($Pool.PortUnsecure) -u $($Pool.User) -p $($Pool.Password)") }
				}
				$fee = 0
				if (("evrprogpow", "firopow", "kawpow", "meowpow", "nexapow", "phihash", "progpow-quai", "progpow-sero", "progpow-telestai", "progpow-veil", "progpow-veriblock", "progpowz") -contains $_.Algorithm) { $fee = 0.75 }
				elseif (("curvehash", "ghostrider", "mike") -contains $_.Algorithm) { $fee = 1 }
				elseif (("sha256csm", "skydoge") -contains $_.Algorithm) { $fee = 2 }
				elseif ("qhash" -contains $_.Algorithm) { $fee = 5 }
				[MinerInfo]@{
					Pool = $Pool.PoolName()
					PoolKey = $Pool.PoolKey()
					Priority = $Pool.Priority
					Name = $Name
					Algorithm = $Algo
					Type = [eMinerType]::nVidia
					TypeInKey = $true
					API = "xmrig"
					URI = "https://github.com/andru-kun/wildrig-multi/releases/download/0.45.6/wildrig-multi-windows-0.45.6.zip"
					Path = "$Name\wildrig.exe"
					ExtraArgs = $extrargs
					Arguments = "-a $($_.Algorithm) $hosts -R $($Config.CheckTimeout) --no-adl --no-igcl --print-time 60 -r 5 --send-stale --api-port=$port $extrargs"
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