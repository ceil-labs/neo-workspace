# Port 80 Enumeration

Service is running on port 80. It's a simple website called BoardLight. BoardLight is a cybersecurity consulting firm specializing in providing cutting-edge security solutions to protect your business from cyber threats

There's not much interactive content. There's a contact form that might be interesting to explore.

Looks like form isn't used. 

```html
           <div class="contact-form">
                <form action="">
                  <div>
                    <input type="text" placeholder="Full Name ">
                  </div>
                  <div>
                    <input type="text" placeholder="Phone Number">
                  </div>
                  <div>
                    <input type="email" placeholder="Email Address">
                  </div>
                  <div>
                    <input type="text" placeholder="Message" class="input_message">
                  </div>
                  <div class="d-flex justify-content-center">
                    <button type="submit" class="btn_on-hover">
                      Send
                    </button>
                  </div>
                </form>
```