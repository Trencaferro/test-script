#Script que que verifica si la URL respon

#carrego la llista de servidors als quals he de fer ping d'un fitxer extern
$list = $args[0] 
$llistaURL = get-content $list #agafo el nom dels servidors del fitxer txt que rebo d'argument llistaurl.txt
$Result = @() 

# Variables de connexio a la base de dades
$user = 'root'
$pass = 'pwd'
$database = 'monitor'
$MySQLHost = '127.0.0.1'
#fivariables

#obtinc el path de l'execucio local del script
$invocation = (Get-Variable MyInvocation).Value 
$directorypath = Split-Path $invocation.MyCommand.Path
write-host $directorypath 

#funcio de connexio a la base de dades
function ConnectMySQL([string]$user,[string]$pass,[string]$MySQLHost,[string]$database) {
  
  #Carrego el connector en funcio del path local
  #[void][system.reflection.Assembly]::LoadFrom("C:\Users\josep\Desktop\SystemsReport\MySQL.Data.dll")
  [void][system.reflection.Assembly]::LoadFrom($directorypath + '\mySQL.Data.dll')  
 
  #Obrire la connexió
  $connStr = "server=" + $MySQLHost + ";port=3300;uid=" + $user + ";pwd=" + $pass + ";database="+$database+";Pooling=FALSE"
  $conn = New-Object MySql.Data.MySqlClient.MySqlConnection($connStr)
  $conn.Open()
  $cmd = New-Object MySql.Data.MySqlClient.MySqlCommand("USE $database", $conn)
  return $conn
}  

#funcio d'escriure a la BBDD 
function WriteMySQLQuery($conn, [string]$query) {
  $command = $conn.CreateCommand()
  $command.CommandText = $query
  $RowsInserted = $command.ExecuteNonQuery()
  $command.Dispose()
  if ($RowsInserted) {
    return $RowInserted
  } else {
    return $false
  }
}

function enviaAlarma($url){
	$smtpServer = "smtp.motivetelevision.co.uk"
	$msg = new-object Net.Mail.MailMessage	
	$smtp = new-object Net.Mail.SmtpClient($smtpServer)
	$smtp.credentials = New-Object System.Net.NetworkCredential("mail@mail.com", "pwd")
	$msg.From = "mail@mail.com"
	$msg.To.Add("mail@mail.com")
	$msg.Subject = "La $url no respon"
	$msg.Body = "Problemes detectas a la URL $url es requereix atenció de l'administrador"	
	$smtp.Send($msg)
} 

Foreach($url in $llistaURL) {
	write-host estic comprovant $url
	$time = try{ 
	$request = $null 
	## Request the URI, and measure how long the response took. 
	$result1 = Measure-Command { $request = Invoke-WebRequest -Uri $url } 
	$result1.TotalMilliseconds 
	}  
	catch{ 
		$request = $_.Exception.Response 
		$time = -1 
	}   
	$result += [PSCustomObject] @{ 
	Time = Get-Date; 
	url = $url; 
	StatusCode = [int] $request.StatusCode; 
	StatusDescription = $request.StatusDescription; 
	ResponseLength = $request.RawContentLength; 
	TimeTaken =  $time;  
	}#ficatch  
}#fifor

#connectem a la base de dades
$conn = ConnectMySQL $user $pass $MySQLHost $database  

if($result -ne $null){
	Foreach($Entry in $Result){
		$url = $Entry.url
		if($Entry.StatusCode -ne "200") {#Error la plana no respon
			#write-host $Entry.url
            #write-host $Entry.StatusCode
			#write-host $Entry.StatusDescription
			#write-host $Entry.RawContentLength
			$inserexEstat = "UPDATE llistaurl SET estat='ko' WHERE url='$url'"			
			$Rows = WriteMySQLQuery $conn $inserexEstat
			enviaAlarma($Entry.url)
        } 
        else{#temps de respota ok			
            #write-host $Entry.StatusCode
			$inserexEstat = "UPDATE llistaurl SET estat='ok' WHERE url='$url'"			
			$Rows = WriteMySQLQuery $conn $inserexEstat
        }

	}
}
#tanquem la connexio a la Base de dades
$conn.Close() 

#afegit per prova de git 18/01/2016


