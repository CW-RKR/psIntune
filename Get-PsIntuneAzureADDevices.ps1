function Get-psIntuneAzureADDevices {
	<#
	.SYNOPSIS
		Return AzureAD device accounts
	.DESCRIPTION
		Return all AzureAD tenant device accounts
	.EXAMPLE
		Get-psIntuneAzureADDevices
	.NOTES
		Name: Get-psIntuneAzureADDevices
	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneAzureADDevices.md
	#>
	[CmdletBinding()]
	param()
	try {
		if (!$AADCred) { 
			Write-Host "Connecting to AzureAD, you may be required to confirm MFA" -ForegroundColor Yellow
			$Global:AADCred = Connect-AzureAD 
		}
		if (!$AADCred) {
			throw "AzureAD authentication was not completed"
		}
		Write-Host "Requesting devices from Azure AD tenant" -ForegroundColor Cyan
		$aadcomps = Get-AzureADDevice -All $True
		Write-Host "Returned $($aadcomps.Count) devices from Azure AD" -ForegroundColor Cyan
		$aadcomps | Foreach-Object {
			$devname = $_.DisplayName
			Write-Verbose "reading properties for: $devname"
			$llogin = $_.ApproximateLastLogonTimeStamp
			if (![string]::IsNullOrEmpty($llogin)) {
				$xdaysOld = (New-TimeSpan -Start $([datetime]$llogin) -End (Get-Date)).Days
			}
			else {
				$xdaysOld = $null
			}
			if (![string]::IsNullOrEmpty($_.LastDirSyncTime)) {
				$xSyncDays = (New-TimeSpan -Start $([datetime]$_.LastDirSyncTime) -End (Get-Date)).Days
			}
			else {
				$xSyncDays = $null
			}
			[pscustomobject]@{
				Name           = $devname
				DeviceId       = $_.DeviceId
				ObjectId       = $_.ObjectId
				Enabled        = $_.AccountEnabled
				OSName         = $_.DeviceOSType
				OSVersion      = $_.DeviceOSVersion
				TrustType      = $_.DeviceTrustType
				LastLogon      = $_.ApproximateLastLogonTimeStamp
				LastLogonDays  = $xdaysOld
				IsCompliant    = $($_.IsCompliant -eq $True)
				IsManaged      = $($_.IsManaged -eq $True)
				DirSyncEnabled = $($_.DirSyncEnabled -eq $True)
				LastDirSync    = $_.LastDirSyncTime
				LastSyncDays   = $xSyncDays
				ProfileType    = $_.ProfileType
			}
		}
	}
	catch {
		Write-Error $_.Exception.Message
	}
}
