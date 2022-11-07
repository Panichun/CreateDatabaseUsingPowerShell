#Install-Module SqlServer


###################################
#Part 1: Create DB Function
###################################
$SqlUser='sa'
$SqlPassword ='123'
#暫設帳號密碼模擬環境


#Function createDB is to test server connection and $sql is a query to 'SELECT '''
#Use $sql to test connection
function createDB([String]$server)
{
  #Write-Host $sql
 try
  {
   Invoke-Sqlcmd -Query $sql -Serverinstance $server -Username $SqlUser -Password $SqlPassword -ErrorAction Stop
   #return 0
  }
  catch
  {
   Write-Host "error when running sql" -ForeGroundColor Red
   Write-Host $_  -ForeGroundColor Red  
   return -1
   #return -1 is for later statuscheck
  }
}

#function makeSQL is to store all the fixed values and be called when creating database
function makeSQL([Int]$env, [String]$server)
{
 Write-Host "env: $env"
 Write-Host "Server: $server"
 $DataFileSize = ''
 $DataFileGrowth = ''
 $LogFileSize = ''
 $LogFileGrowth = ''
 $recoverymode = ''
 
 if($env -eq 1)
 {
   $DataFileSize = '8MB'
   $DataFileGrowth = '1MB'
   $LogFileSize = '1MB'
   $LogFileGrowth = '1MB'
   $recoverymode = 'simple'
 }
 elseif($env -eq 2)
 {
   if($server -eq 'SQL2019-2')
    {
     $DataFileSize = '100MB'
      $DataFileGrowth = '1MB'
      $LogFileSize = '100MB'
      $LogFileGrowth = '10MB'
      $recoverymode = 'simple'
    }
    else
    {
     $DataFileSize = '100MB'
      $DataFileGrowth = '100MB'
      $LogFileSize = '100MB'
      $LogFileGrowth = '100MB'
      $recoverymode = 'full'
    }
 }
 else
 {
   if($server -eq 'SQL2019-3')
    {
     $DataFileSize = '10MB'
      $DataFileGrowth = '10MB'
      $LogFileSize = '10MB'
      $LogFileGrowth = '10MB'
      $recoverymode = 'SIMPLE'
    }
    else
    {
      $DataFileSize = '500MB'
      $DataFileGrowth = '500MB'
      $LogFileSize = '50MB'
      $LogFileGrowth = '10MB'
      $recoverymode = 'FULL'
    }
 }
 $log = '_log'
 $secondaryfilecount = 8
 $logpath = 'LOG'
 $datapath = 'DATA'
 # create variable with SQL to execute environment.
 $sql = "
 CREATE DATABASE [$dbname]
  CONTAINMENT = NONE
  ON  PRIMARY
 ( NAME = N'$dbname', FILENAME = N'${dataDriveName}:\$datapath\$dbname.mdf' , SIZE = $DataFileSize , FILEGROWTH = $DataFileGrowth) "

 if($env -eq 3)
 {
   $sql += ", "
   for($i=2; $i -le ($secondaryfilecount) ; $i++)
   {  
      if($i -ne ($secondaryfilecount))
       {
         $sql += "( NAME = N'$dbname$i', FILENAME = N'${dataDriveName}:\$datapath\$dbname$i.ndf' , SIZE = $DataFileSize , FILEGROWTH = $DataFileGrowth), "
       }
       else
       {
         $sql += "( NAME = N'$dbname$i', FILENAME = N'${dataDriveName}:\$datapath\$dbname$i.ndf' , SIZE = $DataFileSize , FILEGROWTH = $DataFileGrowth) "
       }
   }
 }

 $sql +=
 " LOG ON
  ( NAME = N'$dbname$log', FILENAME = N'${logDriveName}:\$logpath\$dbname$log.ldf' , SIZE = $LogFileSize , FILEGROWTH = $LogFileGrowth )
 GO
  USE [master]
 GO
 ALTER DATABASE [$dbname] SET RECOVERY $recoverymode
 GO
 ALTER AUTHORIZATION ON DATABASE::[$dbname] TO [sa]
 GO "
 return $sql #把 make好的SQL傳給呼叫者，if there's no return value, Cannot validate argument on parameter 'Query'. The argument is null or empty. Provide an argument that is not null or empty, and then try the command again.
}

#####################################
#Part 2: Read-Host
#Environment 1,2,3:
#Servername:
#DB name:
#Data drive name:
#Log drive name:
#Return error and exit if not correct
#####################################

[Int]$environment = Read-Host "Choose from 1 to 3: Local(1)/STG_hub&STG(2)/UAT_hub&Prod(3)";
if ($environment -gt 3 -or $environment -le 0) 
 {
 Write-Host ("Error!!! Out of range. Database creation failed!") -ForeGroundColor Red
 #return -1
 Exit 
 }

#----------------Server check connection 
[String]$servername = Read-Host "Server name(Local, STG or Prod)";
# Test Server
$sql = "SELECT ''" 
#Write-Host $sql
$svrStatus=createDB($servername)
if($svrStatus -eq -1)
{
 Write-Host "Server is not running!Database creation failed!" -ForegroundColor Red
 return 
}

#------------------Env. limitation check simulation
$stgHub="SQL2019-2"  #'maia-stghub.tw01.ppuff.com'
$uatHub="SQL2019-3"  #'maia-uathub.tw01.ppuff.com'
$local="Localhost"   #'devdb.coreop.net'


if($environment -eq 1 -and $servername -ne $local){
  Write-Host ('Server name is invalid, for env.1, localhost only. Create database failed!') -ForegroundColor Red
  Exit
}

if($environment -eq 2 -and $servername -ne "SQL2019-3"){ 
  Write-Host ('Server name is invalid, for env.2, stg only. Create database failed!') -ForegroundColor Red
  Exit
}elseif($environment -eq 3 -and $servername -ne "SQL2019-2"){
  Write-Host ('Server name is invalid, for env.3, prod only. Create database failed!') -ForegroundColor Red
  Exit
}
#------------------

<##----------------Env. limitation check 
$stgHub= "maia-stghub.tw01.ppuff.com"
$uatHub="maia-uathub.tw01.ppuff.com"
$local= "devdb.coreop.net"
$stg= "SB01SR-C69-Z*"
$stg1="maia-z*.tw01.ppuff.com"
$proda="SB01SR-C69-A*"
$prodb="SB01SR-C69-B*"
$prodc="maia-A*.tw01.ppuff.com"
$prodd="maia-B*.tw01.ppuff.com"

if($environment -eq 1 -and $servername -ne $local){
  Write-Host ('Server name is invalid, for env.1, localhost only. Create database failed!') -ForegroundColor Red
  Exit
}

if($environment -eq 2 -and $servername -ne $stg -or $servername -ne $stg1){ 
  Write-Host ('Server name is invalid, for env.2, stg only. Create database failed!') -ForegroundColor Red
  Exit
}elseif($environment -eq 3 -and $servername -ne $proda -or $servername -ne $prodb -or $servername -ne $prodc -or $servername -ne $prodd){
  Write-Host ('Server name is invalid, for env.3, prod only. Create database failed!') -ForegroundColor Red
  Exit
}
#----------------#>


[String]$dbname = Read-Host "Database name";
if ($null -eq $dbname -or $dbname -eq '') 
{Write-Host ('Error!!! DB name cannot be blank! Please enter a DB name.Database creation failed!') -ForegroundColor Red
 return
 exit
}

$dbquery1 = "SELECT name FROM master.sys.databases WHERE name LIKE '" +$dbname+ "'"
$result = Invoke-Sqlcmd -ServerInstance $servername -query $dbquery1 -Username $SqlUser -Password $SqlPassword


foreach($row in $result)
{ 
 if ($row.name -eq $dbname) 
 { 
 Write-Host "[$dbname] Database already exists!" -ForegroundColor Red
 exit
 }
}


[String]$dataDriveName = Read-Host "Data drive name(example: 'C')";
if ($dataDriveName -eq '' -or $dataDriveName.length -gt 1)
{
 Write-Host ('Error!!! Data drive name invalid!Database creation failed!') -ForegroundColor Red
 return
 Exit 
} 

[String]$logDriveName = Read-Host "Log drive name(example: 'C')";
if ( $logDriveName -eq '' -or $logDriveName.length -gt 1)
{
 Write-Host ('Error!!! Log drive name invalid!Database creation failed!') -ForegroundColor Red
 return 
 Exit 
} 


####################################
#Part 3: Call makesQL to execute
####################################

if($environment -eq 1) 
{
 $sql=makeSQL $environment $servername
 $sqlStatus=createDB($servername)
 if($sqlStatus -eq -1)
 {
  return -1
 }
}
else
{
 $sql=makeSQL $environment $servername
 $sqlStatus=createDB($servername)
 if($sqlStatus -eq -1)
 {
  return -1
 }
 Start-Sleep -Seconds 2
 if($environment -eq 2)
 {
   $sql=makeSQL $environment $stgHub
    $sqlStatus=createDB($stgHub)
 }
 else
 {
   $sql=makeSQL $environment $uatHub
   $sqlStatus=createDB($uatHub)
 }
 if($sqlStatus -eq -1)
 {
  return -1
 }
}
      
####################################
#Test if database created successfully
####################################      

$dbquery = "SELECT name FROM master.sys.databases WHERE name LIKE '" +$dbname+ "'"
$result = Invoke-Sqlcmd -ServerInstance $servername -query $dbquery -Username $SqlUser -Password $SqlPassword


foreach($row in $result)
{ 
if ($row.name -eq $dbname) 
{ 
 Write-Host "[$dbname] Database created successfully!" -ForegroundColor Green
}
else 
{ 
 Write-Host "[$dbname] NOT created!"  -ForegroundColor Red}
}