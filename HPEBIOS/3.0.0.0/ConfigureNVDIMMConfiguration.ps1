﻿######################################
#Configuring the NVDIMM configuration
################################----#
<#
.Synopsis
    This Script allows user to configure the NVDIMM for HPE Proliant Gen10 Intel and Gen9 servers

.DESCRIPTION
    This script allows user to configure the NVDIMM. Following features can be configured.
    NVDIMMFunctionality       :-  Use this option to enable or disable the NVDIMM functionality.
    NVDIMMMemoryInterleaving :- Use this option to NVDIMM memory interleaving.
	NVDIMMSanitizePolicy :- Use this option to NVDIMM sanitize\erase on next reboot policy.

.EXAMPLE
    ConfigureNVDIMMConfiguration.ps1

    This mode of execution of script will prompt for 
    
    -Address    :- Accept IP(s) or Hostname(s). For multiple servers IP(s) or Hostname(s) should be separated by comma(,)
    
    -Credential :- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
    
    -NVDIMMFunctionality   :- Accepted values are Enabled and Disabled.
    
    -NVDIMMMemoryInterleaving :- Accepted values are Enabled and Disabled.
    
    -NVDIMMSanitizePolicy :- Accepted values are Disabled, SanitizeAndRebootSystem, SanitizeAndShutdownSystem, SanitizeAndBootToFirmwareUI, and SanitizeToFactoryDefaults.

.EXAMPLE
    ConfigureNVDIMMConfiguration.ps1 -Address "10.20.30.40" -Credential $userCredential -NVDIMMFunctionality Enabled -NVDIMMMemoryInterleaving Enabled -NVDIMMSanitizePolicy SanitizeAndRebootSystem

    This mode of script have input parameter for Address, Credential, NVDIMMFunctionality, NVDIMMMemoryInterleaving, and NVDIMMSanitizePolicy.
    
    -Address:- Use this parameter to specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    
    -Credential :- Use this parameter to specify user Credential.In the case of multiple servers use same credential for all the servers
    
    -NVDIMMFunctionality :- Use this Parameter to enable or disable the NVDIMM functionality. Accepted values are Enabled and Disabled.
    
    -NVDIMMMemoryInterleaving :- Use this Parameter to NVDIMM memory interleaving. Accepted values are Enabled and Disabled.
    
    -NVDIMMSanitizePolicy :- Use this parameter to NVDIMM sanitize\erase on next reboot policy. Accepted values are Disabled, SanitizeAndRebootSystem, SanitizeAndShutdownSystem, SanitizeAndBootToFirmwareUI, and SanitizeToFactoryDefaults.

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 3.0.0.0
    Date    : 11/04/2020
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    NVDIMMFunctionality
	NVDIMMMemoryInterleaving
    NVDIMMSanitizePolicy

.OUTPUTS
    None (by default)

.LINK
    
   http://www.hpe.com/servers/powershell
   https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEBIOS
#>



#Command line parameters
Param(
    # IP(s) or Hostname(s).If multiple addresses seperated by comma (,)
    [string[]]$Address,   
    #In the case of multiple servers it use same credential for all the servers
    [PSCredential]$Credential,
    #Use this Parameter to enable or disable the NVDIMM functionality. Accepted values are Enabled and Disabled.
    [String[]]$NVDIMMFunctionality, 
	#Use this Parameter to NVDIMM memory interleaving. Accepted values are Enabled and Disabled.
    [String[]]$NVDIMMMemoryInterleaving, 
    #Use this parameter to NVDIMM sanitize\erase on next reboot policy. Accepted values are Disabled, SanitizeAndRebootSystem, SanitizeAndShutdownSystem, SanitizeAndBootToFirmwareUI, and SanitizeToFactoryDefaults.
    [string[]]$NVDIMMSanitizePolicy
     )

 #Check for server avaibiality

 function CheckServerAvailability ($ListOfAddress)
 {
    [int]$pingFailureCount = 0
    [array]$PingedServerList = @()
    foreach($serverAddress in $ListOfAddress)
    {
       if(Test-Connection $serverAddress)
       {
        #Write-Host "Server $serverAddress pinged successfully."
        $PingedServerList += $serverAddress
       }
       else
       {
        Write-Host ""
        Write-Host "Server $serverAddress is not reachable. Please check network connectivity"
        $pingFailureCount ++
       }
    }

    if($pingFailureCount -eq $ListOfAddress.Count)
    {
        Write-Host ""
        Write-Host "Server(s) are not reachable please check network conectivity"
        exit
    }
    return $PingedServerList
 }

#clear host
Clear-Host

# script execution started
Write-Host "****** Script execution started ******" -ForegroundColor Yellow
Write-Host ""
#Decribe what script does to the user

Write-Host "This script allows user to configure the NVDIMM configuration. Following features can be configured."
Write-Host "NVDIMM Functionality"
Write-Host "NVDIMM Memory Interleaving"
Write-Host "NVDIMM Sanitize Policy"
Write-Host ""

#dont shoe error in scrip

#$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Continue"
#$ErrorActionPreference = "Inquire"
$ErrorActionPreference = "SilentlyContinue"

#check powershell support
$PowerShellVersion = $PSVersionTable.PSVersion.Major

if($PowerShellVersion -ge "3")
{
    Write-Host "Your powershell version : $($PSVersionTable.PSVersion) is valid to execute this script"
    Write-Host ""
}
else
{
    Write-Host "This script required PowerSehll 3 or above"
    Write-Host "Current installed PowerShell version is $($PSVersionTable.PSVersion)"
    Write-Host "Please Update PowerShell version"
    Write-Host ""
    Write-Host "Exit..."
    Write-Host ""
    exit
}

#Load HPEBIOSCmdlets module
$InstalledModule = Get-Module
$ModuleNames = $InstalledModule.Name

if(-not($ModuleNames -like "HPEBIOSCmdlets"))
{
    Write-Host "Loading module :  HPEBIOSCmdlets"
    Import-Module HPEBIOSCmdlets
    if(($(Get-Module -Name "HPEBIOSCmdlets")  -eq $null))
    {
        Write-Host ""
        Write-Host "HPEBIOSCmdlets module cannot be loaded. Please fix the problem and try again"
        Write-Host ""
        Write-Host "Exit..."
        exit
    }
}
else
{
    $InstalledBiosModule  =  Get-Module -Name "HPEBIOSCmdlets"
    Write-Host "HPEBIOSCmdlets Module Version : $($InstalledBiosModule.Version) is installed on your machine."
    Write-host ""
}

# check for IP(s) or Hostname(s) Input. if not available prompt for Input

if($Address.Count -eq 0)
{
    $Address = Read-Host "Enter Server address (IP or Hostname). Multiple entries seprated by comma(,)"
}
    
[array]$ListOfAddress = ($Address.Trim().Split(','))

if($ListOfAddress.Count -eq 0)
{
    Write-Host "You have not entered IP(s) or Hostname(s)"
    Write-Host ""
    Write-Host "Exit ..."
    exit
}

if($Credential -eq $null)
{
    $Credential = Get-Credential -Message "Enter username and Password(Use same credential for multiple servers)"
    Write-Host ""
}

#Ping and test IP(s) or Hostname(s) are reachable or not
$ListOfAddress =  CheckServerAvailability($ListOfAddress)

#Create connection object
[array]$ListOfConnection = @()
$connection = $null
[int] $connectionCount = 0

foreach($IPAddress in $ListOfAddress)
{
    
    Write-Host ""
    Write-Host "Connecting to server  : $IPAddress"
    $connection = Connect-HPEBIOS -IP $IPAddress -Credential $Credential -DisableCertificateAuthentication 

    if($connection -ne $null)
     {  
        Write-Host ""
        Write-Host "Connection established to the server $IPAddress" -ForegroundColor Green
        $connection
        if($connection.TargetInfo.ProductName.Contains("Gen10") -and $connection.TargetInfo.ProcessorName.Contains("Intel"))
        {
            $ListOfConnection += $connection
        }
        else
        {
            Write-Host "This script is not supported on the target server $($connection.IP)"
			Disconnect-HPEBIOS -Connection $connection
        }
    }
    else
    {
         Write-Host "Connection cannot be established to the server : $IPAddress" -ForegroundColor Red
    }
}

if($ListOfConnection.Count -eq 0)
{
    Write-Host "Exit"
    Write-Host ""
    exit
}

# Get current NVDIMMFunctionality, NVDIMMMemoryInterleaving, and NVDIMMSanitizePolicy configuration

Write-Host ""
Write-Host "Current NVDIMMFunctionality, NVDIMMMemoryInterleaving, and NVDIMMSanitizePolicy configuration" -ForegroundColor Green
Write-Host ""
$counter = 1
foreach($serverConnection in $ListOfConnection)
{
        $NVDIMMConfigurationResult = $serverConnection | Get-HPEBIOSNVDIMMConfiguration
        
        $returnObject = New-Object psobject
        $returnObject | Add-Member NoteProperty IP         $NVDIMMConfigurationResult.IP
        $returnObject | Add-Member NoteProperty Hostname   $NVDIMMConfigurationResult.Hostname
        $returnObject | Add-Member NoteProperty NVDIMMFunctionality  $NVDIMMConfigurationResult.NVDIMMFunctionality
        $returnObject | Add-Member NoteProperty NVDIMMMemoryInterleaving $NVDIMMConfigurationResult.NVDIMMMemoryInterleaving
		$returnObject | Add-Member NoteProperty NVDIMMSanitizePolicy $NVDIMMConfigurationResult.NVDIMMSanitizePolicy

        Write-Host "-------------------Server $counter-------------------" -ForegroundColor Yellow
        Write-Host ""
        $returnObject
        $CurrentNVDIMMConfigurationResult += $returnObject
        $counter++
}

# Get the valid value list fro each parameter
$NVDIMMConfigurationParameterMetaData = $(Get-Command -Name Set-HPEBIOSNVDIMMConfiguration).Parameters
$NVDIMMFunctionalityValidValue = $($NVDIMMConfigurationParameterMetaData["NVDIMMFunctionality"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$NVDIMMMemoryInterleavingValidValue = $($NVDIMMConfigurationParameterMetaData["NVDIMMMemoryInterleaving"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues
$NVDIMMSanitizePolicyValidValue = $($NVDIMMConfigurationParameterMetaData["NVDIMMSanitizePolicy"].Attributes | where {$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues

#Prompt for User input if it is not given as script  parameter 
Write-Host "Input Hint : For multiple server please enter parameter values seprated by comma(,)" -ForegroundColor Yellow
Write-HOst ""

if($NVDIMMFunctionality.Count -eq 0)
{
    $tempNVDIMMFunctionality = Read-Host "Enter NVDIMMFunctionality [Accepted values : ($($NVDIMMFunctionalityValidValue -join ","))]"
    $NVDIMMFunctionality = $tempNVDIMMFunctionality.Trim().Split(',')
    IF($NVDIMMFunctionality.Count -eq 0){
        Write-Host "NVDIMMFunctionality value is not provided`nExit....."
        Exit
    }
}

if($NVDIMMMemoryInterleaving.Count -eq 0)
{
    $tempNVDIMMMemoryInterleaving = Read-Host "Enter NVDIMMMemoryInterleaving [Accepted values : ($($NVDIMMMemoryInterleavingValidValue -join ","))]"
    $NVDIMMMemoryInterleaving = $tempNVDIMMMemoryInterleaving.Trim().Split(',')
    IF($NVDIMMMemoryInterleaving.Count -eq 0){
        Write-Host "NVDIMMMemoryInterleaving value is not provided`nExit....."
        Exit
    }
}

if($NVDIMMSanitizePolicy.Count -eq 0)
{
    $tempNVDIMMSanitizePolicy = Read-Host "Enter NVDIMMSanitizePolicy [Accepted values : ($($NVDIMMSanitizePolicyValidValue -join ","))]"
    $NVDIMMSanitizePolicy = $tempNVDIMMSanitizePolicy.Trim().Split(',')
    IF($NVDIMMSanitizePolicy.Count -eq 0){
        Write-Host "NVDIMMSanitizePolicy value is not provided`nExit....."
        Exit
    }
}

Write-Host "Changing NVDIMMFunctionality, NVDIMMMemoryInterleaving, and NVDIMMSanitizePolicy configuration....." -ForegroundColor Green  
$failureCount = 0

if($ListOfConnection.Count -ne 0)
{
    $setNVDIMMConfigurationResult =  Set-HPEBIOSNVDIMMConfiguration -Connection $ListOfConnection -NVDIMMFunctionality $NVDIMMFunctionality -NVDIMMMemoryInterleaving $NVDIMMMemoryInterleaving -NVDIMMSanitizePolicy $NVDIMMSanitizePolicy
    
    foreach($result in $setNVDIMMConfigurationResult)
    {    
        if(($result.Status -eq "Error"))
        {
            Write-Host ""
            Write-Host "NVDIMMFunctionality, NVDIMMMemoryInterleaving, and NVDIMMSanitizePolicy configuration cannot be changed"
            Write-Host "Server : $($result.IP)"
            Write-Host "Error : $($($result).StatusInfo)"
		    Write-Host "StatusInfo.Category : $($result.StatusInfo.Category)"
		    Write-Host "StatusInfo.Message : $($result.StatusInfo.Message)"
		    Write-Host "StatusInfo.AffectedAttribute : $($result.StatusInfo.AffectedAttribute)"
            $failureCount++
        }
		elseif($result.Status -eq "Warning")
	    {
		    Write-Host ""
		    Write-Host "Server : $($result.IP)"
		    Write-Host "Status : $($result.Status)"
		    Write-Host "StatusInfo : $($result.StatusInfo)"
		    Write-Host "StatusInfo.Category : $($result.StatusInfo.Category)"
		    Write-Host "StatusInfo.Message : $($result.StatusInfo.Message)"
		    Write-Host "StatusInfo.AffectedAttribute : $($result.StatusInfo.AffectedAttribute)"
	    }
    }
}


if($failureCount -ne $ListOfConnection.Count)
{
    Write-Host ""
    Write-host "NVDIMMFunctionality, NVDIMMMemoryInterleaving, and NVDIMMSanitizePolicy configuration successfully changed" -ForegroundColor Green
    Write-Host ""
    $counter = 1
    foreach($serverConnection in $ListOfConnection)
    {
        $NVDIMMConfigurationResult = $serverConnection | Get-HPEBIOSNVDIMMConfiguration
       
        $returnObject = New-Object psobject
        $returnObject | Add-Member NoteProperty IP         $NVDIMMConfigurationResult.IP
        $returnObject | Add-Member NoteProperty Hostname   $NVDIMMConfigurationResult.Hostname
        $returnObject | Add-Member NoteProperty NVDIMMFunctionality  $NVDIMMConfigurationResult.NVDIMMFunctionality
        $returnObject | Add-Member NoteProperty NVDIMMMemoryInterleaving $NVDIMMConfigurationResult.NVDIMMMemoryInterleaving
		$returnObject | Add-Member NoteProperty NVDIMMSanitizePolicy $NVDIMMConfigurationResult.NVDIMMSanitizePolicy
        Write-Host "-------------------Server $counter-------------------" -ForegroundColor Yellow
        Write-Host ""
        $returnObject
        $counter ++
    }
}
    
Disconnect-HPEBIOS -Connection $ListOfConnection
$ErrorActionPreference = "Continue"
Write-Host "****** Script execution completed ******" -ForegroundColor Yellow
exit

# SIG # Begin signature block
# MIIeZwYJKoZIhvcNAQcCoIIeWDCCHlQCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCApUWkWYAWlDq8q
# z/JDV+E+ApETlCyfQyz+FlV+7nEoYKCCGXMwggPuMIIDV6ADAgECAhB+k+v7fMZO
# WepLmnfUBvw7MA0GCSqGSIb3DQEBBQUAMIGLMQswCQYDVQQGEwJaQTEVMBMGA1UE
# CBMMV2VzdGVybiBDYXBlMRQwEgYDVQQHEwtEdXJiYW52aWxsZTEPMA0GA1UEChMG
# VGhhd3RlMR0wGwYDVQQLExRUaGF3dGUgQ2VydGlmaWNhdGlvbjEfMB0GA1UEAxMW
# VGhhd3RlIFRpbWVzdGFtcGluZyBDQTAeFw0xMjEyMjEwMDAwMDBaFw0yMDEyMzAy
# MzU5NTlaMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsayzSVRLlxwS
# CtgleZEiVypv3LgmxENza8K/LlBa+xTCdo5DASVDtKHiRfTot3vDdMwi17SUAAL3
# Te2/tLdEJGvNX0U70UTOQxJzF4KLabQry5kerHIbJk1xH7Ex3ftRYQJTpqr1SSwF
# eEWlL4nO55nn/oziVz89xpLcSvh7M+R5CvvwdYhBnP/FA1GZqtdsn5Nph2Upg4XC
# YBTEyMk7FNrAgfAfDXTekiKryvf7dHwn5vdKG3+nw54trorqpuaqJxZ9YfeYcRG8
# 4lChS+Vd+uUOpyyfqmUg09iW6Mh8pU5IRP8Z4kQHkgvXaISAXWp4ZEXNYEZ+VMET
# fMV58cnBcQIDAQABo4H6MIH3MB0GA1UdDgQWBBRfmvVuXMzMdJrU3X3vP9vsTIAu
# 3TAyBggrBgEFBQcBAQQmMCQwIgYIKwYBBQUHMAGGFmh0dHA6Ly9vY3NwLnRoYXd0
# ZS5jb20wEgYDVR0TAQH/BAgwBgEB/wIBADA/BgNVHR8EODA2MDSgMqAwhi5odHRw
# Oi8vY3JsLnRoYXd0ZS5jb20vVGhhd3RlVGltZXN0YW1waW5nQ0EuY3JsMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIBBjAoBgNVHREEITAfpB0wGzEZ
# MBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMTANBgkqhkiG9w0BAQUFAAOBgQADCZuP
# ee9/WTCq72i1+uMJHbtPggZdN1+mUp8WjeockglEbvVt61h8MOj5aY0jcwsSb0ep
# rjkR+Cqxm7Aaw47rWZYArc4MTbLQMaYIXCp6/OJ6HVdMqGUY6XlAYiWWbsfHN2qD
# IQiOQerd2Vc/HXdJhyoWBl6mOGoiEqNRGYN+tjCCBKMwggOLoAMCAQICEA7P9DjI
# /r81bgTYapgbGlAwDQYJKoZIhvcNAQEFBQAwXjELMAkGA1UEBhMCVVMxHTAbBgNV
# BAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTAwLgYDVQQDEydTeW1hbnRlYyBUaW1l
# IFN0YW1waW5nIFNlcnZpY2VzIENBIC0gRzIwHhcNMTIxMDE4MDAwMDAwWhcNMjAx
# MjI5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29y
# cG9yYXRpb24xNDAyBgNVBAMTK1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2Vydmlj
# ZXMgU2lnbmVyIC0gRzQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCi
# Yws5RLi7I6dESbsO/6HwYQpTk7CY260sD0rFbv+GPFNVDxXOBD8r/amWltm+YXkL
# W8lMhnbl4ENLIpXuwitDwZ/YaLSOQE/uhTi5EcUj8mRY8BUyb05Xoa6IpALXKh7N
# S+HdY9UXiTJbsF6ZWqidKFAOF+6W22E7RVEdzxJWC5JH/Kuu9mY9R6xwcueS51/N
# ELnEg2SUGb0lgOHo0iKl0LoCeqF3k1tlw+4XdLxBhircCEyMkoyRLZ53RB9o1qh0
# d9sOWzKLVoszvdljyEmdOsXF6jML0vGjG/SLvtmzV4s73gSneiKyJK4ux3DFvk6D
# Jgj7C72pT5kI4RAocqrNAgMBAAGjggFXMIIBUzAMBgNVHRMBAf8EAjAAMBYGA1Ud
# JQEB/wQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIHgDBzBggrBgEFBQcBAQRn
# MGUwKgYIKwYBBQUHMAGGHmh0dHA6Ly90cy1vY3NwLndzLnN5bWFudGVjLmNvbTA3
# BggrBgEFBQcwAoYraHR0cDovL3RzLWFpYS53cy5zeW1hbnRlYy5jb20vdHNzLWNh
# LWcyLmNlcjA8BgNVHR8ENTAzMDGgL6AthitodHRwOi8vdHMtY3JsLndzLnN5bWFu
# dGVjLmNvbS90c3MtY2EtZzIuY3JsMCgGA1UdEQQhMB+kHTAbMRkwFwYDVQQDExBU
# aW1lU3RhbXAtMjA0OC0yMB0GA1UdDgQWBBRGxmmjDkoUHtVM2lJjFz9eNrwN5jAf
# BgNVHSMEGDAWgBRfmvVuXMzMdJrU3X3vP9vsTIAu3TANBgkqhkiG9w0BAQUFAAOC
# AQEAeDu0kSoATPCPYjA3eKOEJwdvGLLeJdyg1JQDqoZOJZ+aQAMc3c7jecshaAba
# tjK0bb/0LCZjM+RJZG0N5sNnDvcFpDVsfIkWxumy37Lp3SDGcQ/NlXTctlzevTcf
# Q3jmeLXNKAQgo6rxS8SIKZEOgNER/N1cdm5PXg5FRkFuDbDqOJqxOtoJcRD8HHm0
# gHusafT9nLYMFivxf1sJPZtb4hbKE4FtAC44DagpjyzhsvRaqQGvFZwsL0kb2yK7
# w/54lFHDhrGCiF3wPbRRoXkzKy57udwgCRNx62oZW8/opTBXLIlJP7nPf8m/PiJo
# Y1OavWl0rMUdPH+S4MO8HNgEdTCCBWIwggRKoAMCAQICEQDUdpM6iqGV/ka3TP9c
# iP0/MA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVh
# dGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3Rp
# Z28gTGltaXRlZDEkMCIGA1UEAxMbU2VjdGlnbyBSU0EgQ29kZSBTaWduaW5nIENB
# MB4XDTIwMDEyOTAwMDAwMFoXDTIxMDEyODIzNTk1OVowgdIxCzAJBgNVBAYTAlVT
# MQ4wDAYDVQQRDAU5NDMwNDELMAkGA1UECAwCQ0ExEjAQBgNVBAcMCVBhbG8gQWx0
# bzEcMBoGA1UECQwTMzAwMCBIYW5vdmVyIFN0cmVldDErMCkGA1UECgwiSGV3bGV0
# dCBQYWNrYXJkIEVudGVycHJpc2UgQ29tcGFueTEaMBgGA1UECwwRSFAgQ3liZXIg
# U2VjdXJpdHkxKzApBgNVBAMMIkhld2xldHQgUGFja2FyZCBFbnRlcnByaXNlIENv
# bXBhbnkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC/HqROXVDBjlM9
# iO1+LPF+eg83mnnDDx5LZumEvK2XBxgrf6BpnneJLOZrZ7Yz1vm+PqmFPBRpjo1v
# vdnuaGjbvRl79+EKY8Q+LaUQlKSP6IZKWsUYOfE4Qzpgiq1PzrXmQTsJRWBAPGru
# c4CAkXEDsGAgk+v3CyyHmLHdyckvpatgiWYZ737OB6jKGr3y9T0Pg5p1R+5delGF
# dAGreh3JcTsEAANKFWsW06ZzzOAGWTeK6+kFpfYzi9US5yQkr4hDyU/eJWjsZukW
# Mped6HclyfEfL5wds3XORuPUGR/Ky4tfKWzBYHwFZBsdmlQPsKT9dsTC9aXCcwGD
# bWhMbwU9AgMBAAGjggGGMIIBgjAfBgNVHSMEGDAWgBQO4TqoUzox1Yq+wbutZxoD
# ha00DjAdBgNVHQ4EFgQU0RQ06V6L6xgHFg1wnDPe7A0Pb/YwDgYDVR0PAQH/BAQD
# AgeAMAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwEQYJYIZIAYb4
# QgEBBAQDAgQQMEAGA1UdIAQ5MDcwNQYMKwYBBAGyMQECAQMCMCUwIwYIKwYBBQUH
# AgEWF2h0dHBzOi8vc2VjdGlnby5jb20vQ1BTMEMGA1UdHwQ8MDowOKA2oDSGMmh0
# dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1JTQUNvZGVTaWduaW5nQ0EuY3Js
# MHMGCCsGAQUFBwEBBGcwZTA+BggrBgEFBQcwAoYyaHR0cDovL2NydC5zZWN0aWdv
# LmNvbS9TZWN0aWdvUlNBQ29kZVNpZ25pbmdDQS5jcnQwIwYIKwYBBQUHMAGGF2h0
# dHA6Ly9vY3NwLnNlY3RpZ28uY29tMA0GCSqGSIb3DQEBCwUAA4IBAQAdX/d8FQgq
# me0jyU0SSIfhvViD+AUdt3CG0kFXgtMC+G2Se7PI9di9sL5/tJO+9GHgC2lNC1Xh
# hgOtP+7l3FlQ5yhAFXFnN4XfYLAir83fsf3pSswMIS+P8FmOkAuuiNeUOxTCKBoL
# 1yCB4SzeqviNR99MvW7/BDKuLQFIq5FIWS+RUWfPIbT2DcmgnPcrUwNYzs0NBnCh
# Ml+uSQYwNpu2sP7h2eJn2WB6vIE1gmhD1ebF70xvKIZc08aXCExIwQX/ybhpVVpa
# ftqfn424WD962IRUx7WTAXNXXyPlgph0BABD8xW4l5FdKaOsBE9eyWpjebQ4vHpN
# 6yEE7UHsnRjuMIIFdzCCBF+gAwIBAgIQE+oocFv07O0MNmMJgGFDNjANBgkqhkiG
# 9w0BAQwFADBvMQswCQYDVQQGEwJTRTEUMBIGA1UEChMLQWRkVHJ1c3QgQUIxJjAk
# BgNVBAsTHUFkZFRydXN0IEV4dGVybmFsIFRUUCBOZXR3b3JrMSIwIAYDVQQDExlB
# ZGRUcnVzdCBFeHRlcm5hbCBDQSBSb290MB4XDTAwMDUzMDEwNDgzOFoXDTIwMDUz
# MDEwNDgzOFowgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpOZXcgSmVyc2V5MRQw
# EgYDVQQHEwtKZXJzZXkgQ2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3
# b3JrMS4wLAYDVQQDEyVVU0VSVHJ1c3QgUlNBIENlcnRpZmljYXRpb24gQXV0aG9y
# aXR5MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAgBJlFzYOw9sIs9Cs
# Vw127c0n00ytUINh4qogTQktZAnczomfzD2p7PbPwdzx07HWezcoEStH2jnGvDoZ
# tF+mvX2do2NCtnbyqTsrkfjib9DsFiCQCT7i6HTJGLSR1GJk23+jBvGIGGqQIjy8
# /hPwhxR79uQfjtTkUcYRZ0YIUcuGFFQ/vDP+fmyc/xadGL1RjjWmp2bIcmfbIWax
# 1Jt4A8BQOujM8Ny8nkz+rwWWNR9XWrf/zvk9tyy29lTdyOcSOk2uTIq3XJq0tyA9
# yn8iNK5+O2hmAUTnAU5GU5szYPeUvlM3kHND8zLDU+/bqv50TmnHa4xgk97Exwzf
# 4TKuzJM7UXiVZ4vuPVb+DNBpDxsP8yUmazNt925H+nND5X4OpWaxKXwyhGNVicQN
# wZNUMBkTrNN9N6frXTpsNVzbQdcS2qlJC9/YgIoJk2KOtWbPJYjNhLixP6Q5D9kC
# nusSTJV882sFqV4Wg8y4Z+LoE53MW4LTTLPtW//e5XOsIzstAL81VXQJSdhJWBp/
# kjbmUZIO8yZ9HE0XvMnsQybQv0FfQKlERPSZ51eHnlAfV1SoPv10Yy+xUGUJ5lhC
# LkMaTLTwJUdZ+gQek9QmRkpQgbLevni3/GcV4clXhB4PY9bpYrrWX1Uu6lzGKAgE
# JTm4Diup8kyXHAc/DVL17e8vgg8CAwEAAaOB9DCB8TAfBgNVHSMEGDAWgBStvZh6
# NLQm9/rEJlTvA73gJMtUGjAdBgNVHQ4EFgQUU3m/WqorSs9UgOHYm8Cd8rIDZssw
# DgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wEQYDVR0gBAowCDAGBgRV
# HSAAMEQGA1UdHwQ9MDswOaA3oDWGM2h0dHA6Ly9jcmwudXNlcnRydXN0LmNvbS9B
# ZGRUcnVzdEV4dGVybmFsQ0FSb290LmNybDA1BggrBgEFBQcBAQQpMCcwJQYIKwYB
# BQUHMAGGGWh0dHA6Ly9vY3NwLnVzZXJ0cnVzdC5jb20wDQYJKoZIhvcNAQEMBQAD
# ggEBAJNl9jeDlQ9ew4IcH9Z35zyKwKoJ8OkLJvHgwmp1ocd5yblSYMgpEg7wrQPW
# CcR23+WmgZWnRtqCV6mVksW2jwMibDN3wXsyF24HzloUQToFJBv2FAY7qCUkDrvM
# KnXduXBBP3zQYzYhBx9G/2CkkeFnvN4ffhkUyWNnkepnB2u0j4vAbkN9w6GAbLIe
# vFOFfdyQoaS8Le9Gclc1Bb+7RrtubTeZtv8jkpHGbkD4jylW6l/VXxRTrPBPYer3
# IsynVgviuDQfJtl7GQVoP7o81DgGotPmjw7jtHFtQELFhLRAlSv0ZaBIefYdgWOW
# nU914Ph85I6p0fKtirOMxyHNwu8wggX1MIID3aADAgECAhAdokgwb5smGNCC4JZ9
# M9NqMA0GCSqGSIb3DQEBDAUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKTmV3
# IEplcnNleTEUMBIGA1UEBxMLSmVyc2V5IENpdHkxHjAcBgNVBAoTFVRoZSBVU0VS
# VFJVU1QgTmV0d29yazEuMCwGA1UEAxMlVVNFUlRydXN0IFJTQSBDZXJ0aWZpY2F0
# aW9uIEF1dGhvcml0eTAeFw0xODExMDIwMDAwMDBaFw0zMDEyMzEyMzU5NTlaMHwx
# CzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNV
# BAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDEkMCIGA1UEAxMb
# U2VjdGlnbyBSU0EgQ29kZSBTaWduaW5nIENBMIIBIjANBgkqhkiG9w0BAQEFAAOC
# AQ8AMIIBCgKCAQEAhiKNMoV6GJ9J8JYvYwgeLdx8nxTP4ya2JWYpQIZURnQxYsUQ
# 7bKHJ6aZy5UwwFb1pHXGqQ5QYqVRkRBq4Etirv3w+Bisp//uLjMg+gwZiahse60A
# w2Gh3GllbR9uJ5bXl1GGpvQn5Xxqi5UeW2DVftcWkpwAL2j3l+1qcr44O2Pej79u
# TEFdEiAIWeg5zY/S1s8GtFcFtk6hPldrH5i8xGLWGwuNx2YbSp+dgcRyQLXiX+8L
# Rf+jzhemLVWwt7C8VGqdvI1WU8bwunlQSSz3A7n+L2U18iLqLAevRtn5RhzcjHxx
# KPP+p8YU3VWRbooRDd8GJJV9D6ehfDrahjVh0wIDAQABo4IBZDCCAWAwHwYDVR0j
# BBgwFoAUU3m/WqorSs9UgOHYm8Cd8rIDZsswHQYDVR0OBBYEFA7hOqhTOjHVir7B
# u61nGgOFrTQOMA4GA1UdDwEB/wQEAwIBhjASBgNVHRMBAf8ECDAGAQH/AgEAMB0G
# A1UdJQQWMBQGCCsGAQUFBwMDBggrBgEFBQcDCDARBgNVHSAECjAIMAYGBFUdIAAw
# UAYDVR0fBEkwRzBFoEOgQYY/aHR0cDovL2NybC51c2VydHJ1c3QuY29tL1VTRVJU
# cnVzdFJTQUNlcnRpZmljYXRpb25BdXRob3JpdHkuY3JsMHYGCCsGAQUFBwEBBGow
# aDA/BggrBgEFBQcwAoYzaHR0cDovL2NydC51c2VydHJ1c3QuY29tL1VTRVJUcnVz
# dFJTQUFkZFRydXN0Q0EuY3J0MCUGCCsGAQUFBzABhhlodHRwOi8vb2NzcC51c2Vy
# dHJ1c3QuY29tMA0GCSqGSIb3DQEBDAUAA4ICAQBNY1DtRzRKYaTb3moqjJvxAAAe
# HWJ7Otcywvaz4GOz+2EAiJobbRAHBE++uOqJeCLrD0bs80ZeQEaJEvQLd1qcKkE6
# /Nb06+f3FZUzw6GDKLfeL+SU94Uzgy1KQEi/msJPSrGPJPSzgTfTt2SwpiNqWWhS
# Ql//BOvhdGV5CPWpk95rcUCZlrp48bnI4sMIFrGrY1rIFYBtdF5KdX6luMNstc/f
# SnmHXMdATWM19jDTz7UKDgsEf6BLrrujpdCEAJM+U100pQA1aWy+nyAlEA0Z+1CQ
# Yb45j3qOTfafDh7+B1ESZoMmGUiVzkrJwX/zOgWb+W/fiH/AI57SHkN6RTHBnE2p
# 8FmyWRnoao0pBAJ3fEtLzXC+OrJVWng+vLtvAxAldxU0ivk2zEOS5LpP8WKTKCVX
# KftRGcehJUBqhFfGsp2xvBwK2nxnfn0u6ShMGH7EezFBcZpLKewLPVdQ0srd/Z4F
# UeVEeN0B3rF1mA1UJP3wTuPi+IO9crrLPTru8F4XkmhtyGH5pvEqCgulufSe7pgy
# BYWe6/mDKdPGLH29OncuizdCoGqC7TtKqpQQpOEN+BfFtlp5MxiS47V1+KHpjgol
# HuQe8Z9ahyP/n6RRnvs5gBHN27XEp6iAb+VT1ODjosLSWxr6MiYtaldwHDykWC6j
# 81tLB9wyWfOHpxptWDGCBEowggRGAgEBMIGRMHwxCzAJBgNVBAYTAkdCMRswGQYD
# VQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGDAWBgNV
# BAoTD1NlY3RpZ28gTGltaXRlZDEkMCIGA1UEAxMbU2VjdGlnbyBSU0EgQ29kZSBT
# aWduaW5nIENBAhEA1HaTOoqhlf5Gt0z/XIj9PzANBglghkgBZQMEAgEFAKB8MBAG
# CisGAQQBgjcCAQwxAjAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisG
# AQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCDsyQTQ/IOO
# KEYsGNTRPIUIOcvz2BElrbVABN9OcErcqDANBgkqhkiG9w0BAQEFAASCAQCO2ike
# uM5wwT/gnezu0kZp93DF9BoCPnjXMb27v7awoiqO9PeFu32+F97fOFp54SLlCDel
# XeUjpBaC3xodY44syns0kE168AKkPlDCvLf9R3+WXjFHYwRGqvGNlveMuaaVmsGB
# YnN60DxfGXIteMbqKg0n7/oGQ/2912xB7UhMdyMv0TzPS7v25T1g1m3mrc5z/oKk
# QTxgQl1VWJiGzxi9VIM6WF/JWTmX009GRSYM2GJ7jc7WeVQ8YSI1t+Xgdj2+ayIV
# AR1utdC534ZqaO5E7DE+DdAPqP7lHOXc0een+kJQTEdaiBlOXEZkzSv1CA9RFkv/
# uBQ7hho4cw3psexLoYICCzCCAgcGCSqGSIb3DQEJBjGCAfgwggH0AgEBMHIwXjEL
# MAkGA1UEBhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTAwLgYD
# VQQDEydTeW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIENBIC0gRzICEA7P
# 9DjI/r81bgTYapgbGlAwCQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG
# 9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTIwMDUxODExNTM1MVowIwYJKoZIhvcNAQkE
# MRYEFKSXu3G5RObudm5K3KnNjOtoDI7DMA0GCSqGSIb3DQEBAQUABIIBAIZddrcq
# PqIPJzvKq6g0fgwhZ8F+TlupUl2O0/9aUKYIMICLuEXvwdKbKhfi6+sCqAg6h2Zz
# Z/ootLddcfP28oZIAqR9ZEojyqIznpLUN3VidNsUHNPyNtziXIy6jWC51asbnpET
# 6yZje7OHMQoZac82OKuU/nK7ldzDrTlIi/Cprlz71PHik/7MxRVKlITW9ySfQHB+
# fmJMtFkMUsUDXOcEbh/dCqoPD/FMo7XN0qxGitwshYuHU/gN4r143Cf/MBySCjrO
# zNFoJHaaI1dOuyQWHhvbfEGtw098a4LOSw7+EiE3XAK8vXrVkAxEoNWdsMFG1axm
# hJG2CXkBA6eRIfs=
# SIG # End signature block
