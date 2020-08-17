# pixelfeed

This is a project written using [Lucky](https://luckyframework.org). Enjoy!

## Deploying

This relies on a service stored at: /etc/systemd/system/pixelfeed.service

```sh
#!/bin/sh

set -e

git pull origin main
shards install
crystal build --release src/start_server.cr
sudo systemctl daemon-reload # if the service changed
sudo service pixelfeed restart
```

### Setting up the project

1. [Install required dependencies](https://luckyframework.org/guides/getting-started/installing#install-required-dependencies)
1. Update database settings in `config/database.cr`
1. Run `script/setup`
1. Run `lucky dev` to start the app

### Learning Lucky

Lucky uses the [Crystal](https://crystal-lang.org) programming language. You can learn about Lucky from the [Lucky Guides](https://luckyframework.org/guides/getting-started/why-lucky).
