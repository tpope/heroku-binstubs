# Heroku binstubs

Stop typing out `heroku run console --app myapp-staging` and start using
Heroku [binstubs][]: wrappers around the `heroku` command that configure it
for a given app.  Here's an example:

```sh
#!/bin/sh
HEROKU_APP=myapp-staging exec heroku "$@"
```

Binstubs let you do do `staging logs`, `staging info`, and any other Heroku
command without the `--app` or `--remote` insanity, and this plugin makes it
easy to create them.

[binstubs]: https://github.com/sstephenson/rbenv/wiki/Understanding-binstubs

## Installation

    heroku plugins:install https://github.com/tpope/heroku-binstubs.git

## Usage

    heroku binstubs myapp

For each app named like `myapp-*`, create a binstub named `*`.  For example,
`myapp-staging` becomes `staging`.  If there is an app named `myapp`, it
will be created as `production`.

By default, binstubs are created in `./bin`, which works nicely with
`PATH=./bin:...`.  You can override the destination with `--directory`.

    heroku binstubs myapp --directory script/heroku

With no arguments, `heroku binstubs` uses the current directory name,
stripping off anything after a period (`example.com` becomes `example`).

If you'd rather have binstubs that match the exact app name, pass in `--full`.

There are a handful of other commands in the `binstubs` namespace.

### heroku binstubs:create --as

Create a one-off binstub.  For example, with the [Heroku wildcards][] plugin:

    heroku binstubs:create 'myapp-*' --as each-deploy

[heroku wildcards]: https://github.com/tpope/heroku-wildcards

### heroku binstubs:list

List all existing Heroku binstubs.

### heroku binstubs:clean

Delete all existing Heroku binstubs.  Other files are left untouched.

### heroku binstubs:remotes

For each Heroku Git remote, create a binstub with the same name.

### heroku binstubs:all

Create binstubs for every app you have access to.  Always uses the full app
name.  A useful argument is `--directory ~/bin`.

## License

Copyright © Tim Pope.  MIT License.  See LICENSE for details.
