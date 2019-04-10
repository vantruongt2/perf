$userpros = $Args[0]
$ips = $Args[1]

Remove-Item –path tmp\*

$userpros.Split(";") | ForEach {
    Add-Content tmp\user.properties "$_"
 }

 $ips.Split(";") | ForEach {
    copy tmp\user.properties "\\$_\jmeter\bin"
 }
  