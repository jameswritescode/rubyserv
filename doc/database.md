# Database

`RubyServ::Database` allows you to create json flatfile databases on the fly.

**Example:**

```ruby
db = RubyServ::Database.use('users')
db.users = ['james', 'robert']
db.save
```

## How it works:

When `RubyServ::Database.use('database_name')` is called, it will either create a new file at `data/database_name.json` or read the existing file and turn the data into a `Hash`.

Given the hash is `{ name: 'james' }`, you can modify the `Hash` by doing `db.name = 'robert'`, which will change the hash to `{ name: 'robert' }`.

You can add new information to the `Hash` by doing things like:

```ruby
db.age        = 22
db.hair_color = 'black'
```

This will change the `Hash` to:

```json
{
  name: 'robert',
  age: 21,
  hair_color: 'black'
}
```
When you're done modifying the database, you can save it by calling `db.save`. This will convert the `Hash` back to json and save it back to `data/database_name.json`.
