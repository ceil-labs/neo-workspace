# Port 80 - HTTP Enumeration

* There's obfuscated javascript code loaded in the page, `inviteapi.min.js`.

Here's the obfuscated code:

```js
eval(function(p, a, c, k, e, d) {
    e = function(c) {
        return c.toString(36)
    }
    ;
    if (!''.replace(/^/, String)) {
        while (c--) {
            d[c.toString(a)] = k[c] || c.toString(a)
        }
        k = [function(e) {
            return d[e]
        }
        ];
        e = function() {
            return '\\w+'
        }
        ;
        c = 1
    }
    ;while (c--) {
        if (k[c]) {
            p = p.replace(new RegExp('\\b' + e(c) + '\\b','g'), k[c])
        }
    }
    return p
}('1 i(4){h 8={"4":4};$.9({a:"7",5:"6",g:8,b:\'/d/e/n\',c:1(0){3.2(0)},f:1(0){3.2(0)}})}1 j(){$.9({a:"7",5:"6",b:\'/d/e/k/l/m\',c:1(0){3.2(0)},f:1(0){3.2(0)}})}', 24, 24, 'response|function|log|console|code|dataType|json|POST|formData|ajax|type|url|success|api/v1|invite|error|data|var|verifyInviteCode|makeInviteCode|how|to|generate|verify'.split('|'), 0, {}))
```

Here's the code that is deobfuscated:

```js
function verifyInviteCode(code) {
    var formData = {
        "code": code
    };
    $.ajax({
        type: "POST",
        dataType: "json",
        data: formData,
        url: '/api/v1/invite/verify',
        success: function (response) {
            console.log(response)
        },
        error: function (response) {
            console.log(response)
        }
    })
}

function makeInviteCode() {
    $.ajax({
        type: "POST",
        dataType: "json",
        url: '/api/v1/invite/how/to/generate',
        success: function (response) {
            console.log(response)
        },
        error: function (response) {
            console.log(response)
        }
    })
}
```

Tested the generate invite code endpoint:

```bash
➜  ~ curl -X POST http://2million.htb/api/v1/invite/how/to/generate \
  -H "Content-Type: application/json" \
  -v

* Host 2million.htb:80 was resolved.
* IPv6: (none)
* IPv4: 100.108.21.107
*   Trying 100.108.21.107:80...
* Connected to 2million.htb (100.108.21.107) port 80
> POST /api/v1/invite/how/to/generate HTTP/1.1
> Host: 2million.htb
> User-Agent: curl/8.7.1
> Accept: */*
> Content-Type: application/json
>
* Request completely sent off
< HTTP/1.1 200 OK
< Cache-Control: no-store, no-cache, must-revalidate
< Content-Type: application/json
< Date: Fri, 03 Apr 2026 06:50:35 GMT
< Expires: Thu, 19 Nov 1981 08:52:00 GMT
< Pragma: no-cache
< Server: nginx
< Set-Cookie: PHPSESSID=vj6gtfo2cv4t2o558k140ql2rm; path=/
< Via: 1.1 Caddy
< Transfer-Encoding: chunked
<
* Connection #0 to host 2million.htb left intact
{"0":200,"success":1,"data":{"data":"Va beqre gb trarengr gur vaivgr pbqr, znxr n CBFG erdhrfg gb \/ncv\/i1\/vaivgr\/trarengr","enctype":"ROT13"},"hint":"Data is encrypted ... We should probbably check the encryption type in order to decrypt it..."}
```

Decrypted the data using ROT13:

```
➜  ~ curl -X POST http://2million.htb/api/v1/invite/generate \
  -H "Content-Type: application/json" \
  -v

* Host 2million.htb:80 was resolved.
* IPv6: (none)
* IPv4: 100.108.21.107
*   Trying 100.108.21.107:80...
* Connected to 2million.htb (100.108.21.107) port 80
> POST /api/v1/invite/generate HTTP/1.1
> Host: 2million.htb
> User-Agent: curl/8.7.1
> Accept: */*
> Content-Type: application/json
>
* Request completely sent off
< HTTP/1.1 200 OK
< Cache-Control: no-store, no-cache, must-revalidate
< Content-Type: application/json
< Date: Fri, 03 Apr 2026 06:53:37 GMT
< Expires: Thu, 19 Nov 1981 08:52:00 GMT
< Pragma: no-cache
< Server: nginx
< Set-Cookie: PHPSESSID=ei1rhcijjk1te8jitrap8hdmgc; path=/
< Via: 1.1 Caddy
< Transfer-Encoding: chunked
<
* Connection #0 to host 2million.htb left intact
{"0":200,"success":1,"data":{"code":"MkJKTk0tUEZJTkwtQUdDT1UtQTNFM0E=","format":"encoded"}}%
```

Decoded the data using base64:

```
➜  ~ echo "MkJKTk0tUEZJTkwtQUdDT1UtQTNFM0E=" | base64 -d
```

```bash
2BJNM-PFINL-AGCOU-A3E3A
```