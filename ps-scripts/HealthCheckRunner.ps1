<#
.SYNOPSIS
Health Check Script Runner.

.DESCRIPTION
The script runs health check scripts and script outputs via e-mail. The script either uses the XML configuration file passed as a parameter, 
or default "healthcheckrunnerconfig.xml". 

Sample structure of the XML configuration file:

<HealthCheckRunner>
	<RunnerLogFile Name="c:\temp\health_check_runner.log"></RunnerLogFile>

	<HealthCheckScripts>
		<HealthCheckScript Name="c:\temp\health_check_VMAX.ps1 -DeviceList vmax_list.txt -full">
			<Description>VMAX Health Check</Description>
			<LogDirectory>c:\temp\vmax</LogDirectory>
			<LogFilePrefix>vmax_health_check</LogFilePrefix>
			<MailTo>john.smith@example.test</MailTo>
		</HealthCheckScript>
	</HealthCheckScripts>
</HealthCheckRunner>	

.EXAMPLE

PS> HealthCheckRunner.ps1 -ConfigFile health_check_runner_config.xml

.NOTES


.LINK

#>


param(
    [string]$ConfigFile="health_check_runner_config.xml"
)

$SCRIPT_VERSION="2.1.1"

function writeLogMsg {
    param( [string]$msg
    )
    
    $t=get-date -uformat "%m%d%Y-%H:%M"
    "$t` $msg" >> $RUNNERLOGFILE
    "$t` $msg"
}

if( ! (test-path $ConfigFile) ) {
    
    writeLogMsg "Configuration file $CONFIGFILE is missing"
    exit
}

[xml]$configFile=(gc $ConfigFile)

$RUNNERLOGFILE=$configFile.HealthCheckRunner.RunnerLogFile.Name

foreach( $healthCheckScript in $configFile.SelectNodes("//HealthCheckScript") ) {
    $scriptName=$healthCheckScript.Name
    $description=$healthCheckScript.Description
    $logDir=$healthCheckScript.LogDirectory
    $logFilePrefix=$healthCheckScript.LogFilePrefix
    $mailTo=$healthCheckScript.MailTo
    
    $d=(get-date -uformat "%m%d%Y-%H%M")
    $logFile=$logDir + "\" + $logFilePrefix + "_" + $d + ".txt"

    writeLogMsg "Starting: $description"
    writeLogMsg "Script name: $scriptName"
    writeLogMsg "Log file: $logFile"
    Invoke-Expression $scriptName 2>&1 | out-string -width 120 > $logFile

    if( $mailTo.length -ne 0 ) {

        writeLogMsg "E-mail report to: $mailTo"
        
        $msg=("Health Check report location: " + (hostname) + " " + $logFile + "`n`n" )
    
        $msg=$msg + (cat $logFile | out-string  )
    
        Send-MailMessage -To $mailTo -Subject "$description $d" -From "slf_storage_support_team@sunlife.com" -SmtpServer smtp.ca.sunlife -Body $msg
    }

    writeLogMsg "Finished: $description"
    
    ""
        
    
}