function Invoke-CIPPStandardDisableViva {
    <#
    .FUNCTIONALITY
        Internal
    .COMPONENT
        (APIName) DisableViva
    .SYNOPSIS
        (Label) Disable daily Insight/Viva reports
    .DESCRIPTION
        (Helptext) Disables the daily viva reports for all users.
        (DocsDescription) Disables the daily viva reports for all users.
    .NOTES
        CAT
            Exchange Standards
        TAG
        ADDEDCOMPONENT
        IMPACT
            Low Impact
        ADDEDDATE
            2022-05-25
        POWERSHELLEQUIVALENT
            Set-UserBriefingConfig
        RECOMMENDEDBY
        UPDATECOMMENTBLOCK
            Run the Tools\Update-StandardsComments.ps1 script to update this comment block
    .LINK
        https://docs.cipp.app/user-documentation/tenant/standards/list-standards/exchange-standards#low-impact
    #>

    param($Tenant, $Settings)
    ##$Rerun -Type Standard -Tenant $Tenant -Settings $Settings 'DisableViva'

    try {
        # TODO This does not work without Global Admin permissions for some reason. Throws an "EXCEPTION: Tenant admin role is required" error. -Bobby
        $CurrentSetting = New-GraphGetRequest -Uri "https://graph.microsoft.com/beta/organization/$Tenant/settings/peopleInsights" -tenantid $Tenant -AsApp $true
    } catch {
        $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
        Write-LogMessage -API 'Standards' -tenant $Tenant -message "Failed to get Viva insights settings. Error: $ErrorMessage" -sev Error
        Return
    }

    If ($Settings.remediate -eq $true) {
        Write-Host 'Time to remediate'

        if ($CurrentSetting.isEnabledInOrganization -eq $false) {
            Write-LogMessage -API 'Standards' -tenant $Tenant -message 'Viva is already disabled.' -sev Info
        } else {
            try {
                # TODO This does not work without Global Admin permissions for some reason. Throws an "EXCEPTION: Tenant admin role is required" error. -Bobby
                New-GraphPOSTRequest -Uri "https://graph.microsoft.com/beta/organization/$Tenant/settings/peopleInsights" -tenantid $Tenant -AsApp $true -Type PATCH -Body '{"isEnabledInOrganization": false}' -ContentType 'application/json'
                Write-LogMessage -API 'Standards' -tenant $Tenant -message 'Disabled Viva insights' -sev Info
            } catch {
                $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
                Write-LogMessage -API 'Standards' -tenant $Tenant -message "Failed to disable Viva for all users. Error: $ErrorMessage" -sev Error
            }
        }
    }

    if ($Settings.alert -eq $true) {

        if ($CurrentSetting.isEnabledInOrganization -eq $false) {
            Write-LogMessage -API 'Standards' -tenant $Tenant -message 'Viva is disabled' -sev Info
        } else {
            Write-StandardsAlert -message 'Viva is not disabled' -object $CurrentSetting -tenant $Tenant -standardName 'DisableViva' -standardId $Settings.standardId
            Write-LogMessage -API 'Standards' -tenant $Tenant -message 'Viva is not disabled' -sev Info
        }
    }

    if ($Settings.report -eq $true) {
        $state = $CurrentSetting.isEnabledInOrganization ? $true : ($CurrentSetting | Select-Object isEnabledInOrganization)
        Set-CIPPStandardsCompareField -FieldName 'standards.DisableViva' -FieldValue $State -Tenant $Tenant
        Add-CIPPBPAField -FieldName 'DisableViva' -FieldValue $CurrentSetting.isEnabledInOrganization -StoreAs bool -Tenant $Tenant
    }

}
