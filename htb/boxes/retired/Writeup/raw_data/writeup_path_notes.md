# Notes on /writeup/ path

* Saw from html `head` `meta` tag that uses CMS Made Simple. The version isn't clear yet.

```html
<!doctype html>
<html lang="en_US"><head>
	<title>Home - writeup</title>
	
<base href="http://writeup.htb/writeup/" />
<meta name="Generator" content="CMS Made Simple - Copyright (C) 2004-2019. All rights reserved." />
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
```

* /writeup/admin/ is behind basic authentication. I couldn't access it yet. Had no credentials.

* Found the version. It's 2.2.9.1

```
Version 2.2.9.1
-------------------------------
Core - General
  - fix to the CmsLayoutStylesheetQuery class
  - fix an edge case in the Database\Connection::DbTimeStamp() method

MicroTiny v2.2.4
  - Minor fix in error displays.

Phar Installer v1.3.7
  - Fix to edge case in step 3 where memory_limit is set to -1

Version 2.2.9 - Blow Me Down
-------------------------------
Core - General
  - PHP 7.2+ fixes.
  - Now do not call Module::InitializeAdmin() or Module::InitializeFrontend() if the module loading is being forced
    (as is the case sometimes within ModuleManager);
  - Minor changes and fixes to prevent warnings/notices in CLI based scripts
  - Improvem
  ```

  * Version seems to be vulnerable to a number of vulnerabilities.

```txt
$ searchsploit "CMS Made Simple"
CMS Made Simple < 2.2.10 - SQL Injection                   | php/webapps/46635.py
CMS Made Simple 2.2.14 - Arbitrary File Upload (Authentica | php/webapps/48779.py
CMS Made Simple 2.2.14 - Authenticated Arbitrary File Uplo | php/webapps/48742.txt
CMS Made Simple 2.2.14 - Persistent Cross-Site Scripting ( | php/webapps/48851.txt
CMS Made Simple 2.2.15 - RCE (Authenticated)               | php/webapps/49345.txt
CMS Made Simple 2.2.15 - Stored Cross-Site Scripting via S | php/webapps/49199.txt
CMS Made Simple 2.2.15 - 'title' Cross-Site Scripting (XSS | php/webapps/49793.txt
CMS Made Simple 2.2.5 - (Authenticated) Remote Code Execut | php/webapps/44976.py
CMS Made Simple 2.2.7 - (Authenticated) Remote Code Execut | php/webapps/45793.py
CMS Made Simple (CMSMS) Showtime2 - File Upload Remote Cod | php/remote/46627.rb
CMS Made Simple Module Antz Toolkit 1.02 - Arbitrary File  | php/webapps/34300.py
CMS Made Simple Module Download Manager 1.4.1 - Arbitrary  | php/webapps/34298.py
CMS Made Simple Showtime2 Module 3.6.2 - (Authenticated) A | php/webapps/46546.py
CmsMadeSimple v2.2.17 - Remote Code Execution (RCE)        | php/webapps/51600.txt
CmsMadeSimple v2.2.17 - session hijacking via Server-Side  | php/webapps/51599.txt
CmsMadeSimple v2.2.17 - Stored Cross-Site Scripting (XSS)  | php/webapps/51601.txt
----------------------------------------------------------- ---------------------------------
Shellcodes: No Results
----------------------------------------------------------- ---------------------------------
 Paper Title                                               |  Path
----------------------------------------------------------- ---------------------------------
CMS Made Simple v2.2.13 - Paper                            | docs/english/49947-cms-made-simp
----------------------------------------------------------- ---------------------------------
```