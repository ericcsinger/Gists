#######################################
#START: Variables
$ErrorActionPreference = 'Continue'

$All_Paths_To_Process = @(
    "$($env:windir)\system32\config\sam",
    "$($env:windir)\system32\config\security",
    "$($env:windir)\system32\config\system" 
    )

$Output_Object = [PSCustomObject]@{
    Details = New-Object -TypeName "System.Collections.ArrayList"
    Snapshots_Removed = $false
    Remediated = $false
    }

#END: Variables
#######################################

#######################################
#START: Loop through all paths
Foreach ($Path_To_Process in $All_Paths_To_Process)
    {
    try 
        {
        #######################################
        #START: Path Variables
        $Script_Section = "Path Variables"
        Write-Host "[$($Script_Section)]: START"
        
        $Path_Result_Object = [pscustomobject]@{
            Path = $($Path_To_Process)
            Mitigation_In_Place = $null
            }

        Write-Host "[$($Script_Section)]: END"
        #END: Path Variables
        #######################################

        #######################################
        #START: Get current permissions
        $Script_Section = "Get current permissions for path $($Path_To_Process)"
        Write-Host "[$($Script_Section)]: START"
        $Path_ACL = $null
        $Path_ACL = Get-ACL -Path $Path_To_Process

        Write-Host "[$($Script_Section)]: END"
        #END: Get current permissions
        #######################################

        #######################################
        #START: Analyze if mitigation in place
        $Script_Section = "Analyze if mitigation in place for path $($Path_To_Process)"
        Write-Host "[$($Script_Section)]: START"
        
        $Path_ACL_Users = $null
        $Path_ACL_Users = $Path_ACL.Access | where-object {$_.IdentityReference -eq "BUILTIN\Users"}

        If ($null -eq $Path_ACL_Users)
            {
            Write-Host "[$($Script_Section)]: Mitigation in place for this path!" -ForegroundColor Green
            $Path_Result_Object.Mitigation_In_Place = $true
            }
        else 
            {
            Write-Host "[$($Script_Section)]: Mitigation missing for this path!" -ForegroundColor Yellow
            $Path_Result_Object.Mitigation_In_Place = $false
            }

        Write-Host "[$($Script_Section)]: END"
        #END: Analyze if mitigation in place
        #######################################
        
        #######################################
        #START: Remediate mitigation for path 
        $Script_Section = "Remediate mitigation for path $($Path_To_Process)"
        Write-Host "[$($Script_Section)]: START"
        
        If ($Path_Result_Object.Mitigation_In_Place -eq $true)
            {
            Write-Host "[$($Script_Section)]: Skipping, mitigation already in place"
            }
        else 
            {
            Write-Host "[$($Script_Section)]: Defining new ACL" 
            $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Users","ReadAndExecute","Allow")
            $Path_ACL.RemoveAccessRule($AccessRule)

            Write-Host "[$($Script_Section)]: Removing Users from ACL"
            $Path_ACL | Set-Acl -Path $Path_To_Process
            }

        Write-Host "[$($Script_Section)]: END"
        #END: Remediate mitigation for path 
        #######################################

        #######################################
        #START: ReAnalyze if mitigation in place
        $Script_Section = "ReAnalyze if mitigation in place for path $($Path_To_Process)"
        Write-Host "[$($Script_Section)]: START"

        Write-Host "[$($Script_Section)]: START"
        $Path_ACL = $null
        $Path_ACL = Get-ACL -Path $Path_To_Process
        
        $Path_ACL_Users = $null
        $Path_ACL_Users = $Path_ACL.Access | where-object {$_.IdentityReference -eq "BUILTIN\Users"}

        If ($null -eq $Path_ACL_Users)
            {
            Write-Host "[$($Script_Section)]: Mitigation in place for this path!" -ForegroundColor Green
            $Path_Result_Object.Mitigation_In_Place = $true
            [void]$Output_Object.Details.Add($Path_Result_Object)
            }
        else 
            {
            Throw "Mitigation missing for this path, remediation failed"
            }

        Write-Host "[$($Script_Section)]: END"
        #END: ReAnalyze if mitigation in place
        #######################################
        
        }
    catch 
        {
        Throw "[$($Script_Section)]: Command: ""$($_.InvocationInfo.MyCommand)"", Message: ""$($_.Exception.Message)"", LineNumber ""$($_.InvocationInfo.ScriptLineNumber)"""
        }
    }

#END: Loop through all paths
#######################################

#######################################
#START: Remidiate VSS snapshots
$Script_Section = "Remidiate VSS snapshots if any VSS snapshots exist"
Write-Host "[$($Script_Section)]: START"

try 
    {
    Write-Host "[$($Script_Section)]: Getting the C: drive volume ID"
    $C_Drive_Volume_DeviceID = Get-WmiObject -Class win32_volume | Where-Object {$_.DriveLetter -eq 'c:'} | Select-Object -ExpandProperty DeviceID

    if ($null -eq $C_Drive_Volume_DeviceID)
        {
        Throw "Could not find C drive volume ID"
        }


    Write-Host "[$($Script_Section)]: Getting all shadow copies for drive C"
    $All_Shadow_Copies = Get-WmiObject -Class win32_shadowcopy | Where-Object {$_.VolumeName -eq $C_Drive_Volume_DeviceID}

    If ($null -ne $All_Shadow_Copies)
        {
        Write-Host "[$($Script_Section)]: There are shadow copies to delete"

        Foreach ($Shadow_Copy in $All_Shadow_Copies)
            {
            Write-Host "[$($Script_Section)]: Removing shadow copy id ""$($shadow_copy.ID)"""
            $Shadow_Copy | Remove-WmiObject 
            $Output_Object.Snapshots_Removed = $true
            }
        }
    }
catch 
    {
    Throw "[$($Script_Section)]: Command: ""$($_.InvocationInfo.MyCommand)"", Message: ""$($_.Exception.Message)"", LineNumber ""$($_.InvocationInfo.ScriptLineNumber)"""
    }

Write-Host "[$($Script_Section)]: END"
#END: Remidiate VSS snapshots if any VSS snapshots exist
#######################################


#######################################
#START: Validate VSS Snapshots removed
$Script_Section = "Remidiate VSS snapshots if any VSS snapshots exist"
Write-Host "[$($Script_Section)]: START"

try 
    {
    Write-Host "[$($Script_Section)]: Getting the C: drive volume ID"
    $C_Drive_Volume_DeviceID = Get-WmiObject -Class win32_volume | Where-Object {$_.DriveLetter -eq 'c:'} | Select-Object -ExpandProperty DeviceID

    if ($null -eq $C_Drive_Volume_DeviceID)
        {
        Throw "Could not find C drive volume ID"
        }


    Write-Host "[$($Script_Section)]: Getting all shadow copies for drive C"
    $All_Shadow_Copies = Get-WmiObject -Class win32_shadowcopy | Where-Object {$_.VolumeName -eq $C_Drive_Volume_DeviceID}

    If ($null -ne $All_Shadow_Copies)
        {
        Throw "There are still shadow copies, deletion failed"
        }
    Else
        {
        Write-Host "[$($Script_Section)]: System remediated!" -ForegroundColor Green
        $Output_Object.Remediated = $true
        }
    }
catch 
    {
    Throw "[$($Script_Section)]: Command: ""$($_.InvocationInfo.MyCommand)"", Message: ""$($_.Exception.Message)"", LineNumber ""$($_.InvocationInfo.ScriptLineNumber)"""
    }

Write-Host "[$($Script_Section)]: END"
#END: Validate VSS Snapshots removed
#######################################

$Output_Object | ConvertTo-Json -Depth 10