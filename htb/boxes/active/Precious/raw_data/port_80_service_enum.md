# Port 80 Service Enumeration

* HTTP server
* Using Phusion Passenger(R) 6.0.15, Ruby
* nginx/1.18.0

Simple page for converting web page to PDF.

```html
<!DOCTYPE html>
<html>
<head>
    <title>Convert Web Page to PDF</title>
    <link rel="stylesheet" href="stylesheets/style.css">
</head>
<body>
    <div class="wrapper">
        <h1 class="title">Convert Web Page to PDF</h1>
        <form action="/" method="post">
            <p>Enter URL to fetch</p><br>
            <input type="text" name="url" value="">
            <input type="submit" value="Submit">
        </form>
        <h2 class="msg"></h2>
    </div> 
</body>
</html>
```