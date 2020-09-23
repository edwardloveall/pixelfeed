# pixelfeed

A feed of pixelart from various services (Reddit, Twitter, DeviantArt, etc)

## Deploying

This relies on a service stored at: /etc/systemd/system/pixelfeed.service

```sh
#!/bin/sh

set -e

git pull origin main
# Migrating? see below
shards install
crystal build --release src/start_server.cr
sudo systemctl daemon-reload # if the service changed
sudo service pixelfeed restart
```

### Migrating

To migrate you need to set all the environment varibles for the app. One easy way to do this is to copy/paste from your local `.env` file, and escape the newline characters at the end. Something like this:

```sh
FOO=... \
BAR=... \
DATABASE_URL=postgresql://username:password@127.0.0.1/pixelfeed_production
```

They don't even have to be the real values, except for the `DATABASE_URL`. You can find the username and password in 1Password under `pixelfeed Deploy`. Once they're all set, you can run `crystal run tasks.cr -- db.migrate`
