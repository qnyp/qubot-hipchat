# qubot - Simple chat bot for HipChat

## Prerequisite

* Ruby 2.1.0
* Foreman

## Local Setup

### Configuration

Copy sample environment file to `.env`,

```
$ cp sample.env .env
```

and edit.

```
XMPP_JID="***@chat.hipchat.com/bot"
XMPP_NAME="First Last"
XMPP_NICK="First"
XMPP_PASSWORD="***"
XMPP_ROOMS="***@conf.hipchat.com, ***@conf.hipchat.com"
```

You can investigate XMPP/Jabber account information at `https://YOURS.hipchat.com/account/xmpp`.

### Setup Foreman

Install Heroku Toolbelt or foreman.gem

### Bundle and Run

```
$ bundle install
$ foreman start
04:10:00 bot.1  | started with pid 76252
04:10:01 bot.1  | D, [2012-12-13T04:10:01.199111 #76252] DEBUG -- : connect
04:10:04 bot.1  | W, [2012-12-13T04:10:04.240215 #76252]  WARN -- : running
```

Ctrl-C to exit.

## Deployment to Heroku

```
$ heroku create APP_NAME
$ heroku config:add \
  XMPP_JID="..." \
  XMPP_NAME="..." \
  XMPP_NICK="..." \
  XMPP_PASSWORD="..." \
  XMPP_ROOMS="..."
$ git push heroku master
$ heroku ps:scale bot=1
```

## License

MIT License.

## Contributing

1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request
