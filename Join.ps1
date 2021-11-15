if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
	Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath';`"";
	exit;
}

# ####################
# SCRIPT CONFIGURATION
# ####################
$DomainName = "domain"
$ServerAdminUsername = "administrator"
$ServerAdminPassword = "password"
$LocalAdminUsername = "administrator"
$LocalAdminPassword = "password"
# ###########################
# END OF SCRIPT CONFIGURATION
# ###########################

$AdminUsername = "$DomainName\$ServerAdminUsername"
$AdminPassword = "$ServerAdminPassword" | ConvertTo-SecureString -asPlainText -Force
$DomaineName = "$DomaineName.local"
$credential = New-Object System.Management.Automation.PSCredential($AdminUsername,$AdminPassword)
$domainquery = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
$launcher = "$PSScriptRoot\Join.bat"
$regex = '[\\][\\]'
$launcher = $launcher -replace $regex, '\'

Function Set-AutoLogon {
	[CmdletBinding()]
	Param(        
		[Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[String[]]$DefaultUsername,

		[Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[String[]]$DefaultPassword,

		[Parameter(Mandatory=$False,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[AllowEmptyString()]
		[String[]]$AutoLogonCount,

		[Parameter(Mandatory=$False,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[AllowEmptyString()]
		[String[]]$Script               
	)

	Begin
	{
		$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
		$RegROPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
	}

	Process
	{
		try
		{
			Set-ItemProperty $RegPath "AutoAdminLogon" -Value "1" -type String  
			Set-ItemProperty $RegPath "DefaultUsername" -Value "$DefaultUsername" -type String  
			Set-ItemProperty $RegPath "DefaultPassword" -Value "$DefaultPassword" -type String
			if($AutoLogonCount)
			{
				Set-ItemProperty $RegPath "AutoLogonCount" -Value "$AutoLogonCount" -type DWord
			}
			else
			{
				Set-ItemProperty $RegPath "AutoLogonCount" -Value "1" -type DWord
			}
			if($Script)
			{
				Set-ItemProperty $RegROPath "(Default)" -Value "$Script" -type String
			}
			else
			{
				Set-ItemProperty $RegROPath "(Default)" -Value "" -type String
			}
		}
		catch
		{
			Write-Output "An error had occured $Error"
		}
	}

	End
	{
		#End
	}
}

if ($domainquery -eq $true)
	{
		Write-Host "Removing $env:COMPUTERNAME from domain"
		Set-AutoLogon -DefaultUsername "$LocalAdminUsername" -DefaultPassword "$LocalAdminPassword" -Script "`"$launcher`""
		Remove-Computer -Credential $credential -Force -Passthrough -Verbose
		Start-Sleep -s 10
		Restart-Computer
	}

if ($domainquery -eq $false)
	{
		Write-Host "Adding $env:COMPUTERNAME to $DomainName"
		Add-Computer -DomainName $DomainName -Credential $credential
		Start-Sleep -s 10
		Restart-Computer
	}
