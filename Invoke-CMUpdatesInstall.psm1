function Invoke-CybCMUpdatesInstall {
    <#
    .SYNOPSIS
    .DESCRIPTION
    .PARAMETER
    .EXAMPLE
    #>    
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$True,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True,
        Position=1)]
    [Alias('CN','MachineName','HostName','Name')]
    [string[]]$ComputerName,

    [Parameter(Mandatory=$True,
        Position=2)]
    [string]$SupName
    )

BEGIN {
    #Import TimeStamp function for our logging
    function TimeStamp{
        (get-date -Format "dd.MM.yyyy hh:mm:ss").ToString()
    }
}

PROCESS {
    #Check if we are going to install all updates with compliance 0
    If ($SupName -like "All" -or $SupName -like "all"){
        Write-Verbose "$(TimeStamp) Info... Triggering install for all available updates on remote computer(s)."
        
        #Push our script to remote computers
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $ApplicationClass = [WmiClass]"root\ccm\clientSDK:CCM_SoftwareUpdatesManager"
            $NewUpdates = (Get-WmiObject -Namespace root\ccm\clientsdk -Query "SELECT * FROM CCM_SoftwareUpdate WHERE ComplianceState = '0'")
            
            $WmiMethod_parameters = @{'Namespace'='root\ccm\clientsdk'
                                        'Class'='CCM_SoftwareUpdatesManager'
                                        'Name'='InstallUpdates'}
            $PushInstall = Invoke-WmiMethod @WmiMethod_parameters -ArgumentList (,$NewUpdates)
            
            #Readable result output
            if($PushInstall.ReturnValue -eq '0'){
                $ReturnValue = "Successfull"
            } #If
            elseif($PushInstall.ReturnValue -ne '0'){
                $ReturnValue = "WMI Method Failed"
            } #ElseIf

            #Create an object for the task and output object
            $Properties = @{'ComputerName'=$env:COMPUTERNAME
                            'InstallTriggered'=$ReturnValue}
            $obj = New-Object psobject -Property $Properties
            $obj

        } -ErrorAction SilentlyContinue -ErrorVariable ConnectionErrors -HideComputerName | Select ComputerName,InstallTriggered

    }#If

    
    Else{
        Write-Verbose "$(TimeStamp) Info... Triggering installation of $SupName on remote computer(s)."

        #Push our script to remote computers
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $ApplicationClass = [WmiClass]"root\ccm\clientSDK:CCM_SoftwareUpdatesManager"
            
            foreach($updates in $SupName){
                #Set wildcard for searching for the update
                $update = "%$update%"

                #Query for specific update
                $NewUpdates = (Get-WmiObject -Namespace root\ccm\clientsdk -Query "SELECT * FROM CCM_SoftwareUpdate WHERE Name like '$updates'")
                
                #Trigger installation for the specific update
                $WmiMethod_parameters = @{'Namespace'='root\ccm\clientsdk'
                                            'Class'='CCM_SoftwareUpdatesManager'
                                            'Name'='InstallUpdates'}
                $PushInstall = Invoke-WmiMethod @WmiMethod_parameters -ArgumentList (,$NewUpdates)
            
                #Readable result output
                if($PushInstall.ReturnValue -eq '0'){
                    $ReturnValue = "Successfull"
                } #If
                elseif($PushInstall.ReturnValue -ne '0'){
                    $ReturnValue = "WMI Method Failed"
                } #ElseIf

                #Create an object for the task and output object
                $Properties = @{'ComputerName'=$env:COMPUTERNAME
                                'InstallTriggered'=$ReturnValue}
                $obj = New-Object psobject -Property $Properties
                $obj

            } #Foreach
        } -ErrorAction SilentlyContinue -ErrorVariable ConnectionErrors -HideComputerName | Select ComputerName,InstallTriggered
    } #Else
    

    #Checking for any errors in our ConnectionErrors variable, and then adds information about failed connection(s) to our output.
    $FailedConnection = $ConnectionErrors.TargetObject
    foreach($fail in $FailedConnection){
        $FailedProperties = @{'ComputerName'=$fail
                                'InstallTriggered'="Failed to connect to remote computer."}
        $failobj = New-Object psobject -Property $FailedProperties
        $failobj
    }
}


END {
    #Left empty
}

} #Function
