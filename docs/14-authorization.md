---
sidebar_position: 14
---

# Authorization

#### authorize(user, password)

Sets credentials for HTTP basic authentication. `basic_authorize` is deprecated
in favor of it.

```ruby
page.driver.authorize("login", "password")
visit "/admin"
```
