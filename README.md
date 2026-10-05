# ns8-roundcubemail

Found all settings to overwrite the default, drop them in your file for example ~.config/state/config/mySettings.php (start by `<?php`)

https://github.com/roundcube/roundcubemail/blob/master/config/defaults.inc.php

## Install

Instantiate the module with:

    add-module ghcr.io/nethserver/roundcubemail:latest 1

The output of the command will return the instance name.
Output example:

    {"module_id": "roundcubemail1", "image_name": "roundcubemail", "image_url": "ghcr.io/nethserver/roundcubemail:latest"}

## Configure

Let's assume that the mattermost instance is named `mattermost1`.

Launch `configure-module`, by setting the following parameters:
- `host`: a fully qualified domain name for the application
- `http2https`: enable or disable HTTP to HTTPS redirection (true/false)
- `lets_encrypt`: enable or disable Let's Encrypt certificate (true/false)
- `mail_server`: the module UUID of the the mail server (only on NS8), for example `24c52316-5af5-4b4d-8b0f-734f9ee9c1d9`
- `mail_domain`: the mail domain used for user IMAP login and Roundcube user identifier. It must
  correspond to a valid mail domain handled by `mail_server` where user names are valid mail addresses too
- `plugins`: a list of plugins(coma separated) to enable in roundcubemail (default enabled : `archive,zipdownload,managesieve,markasjunk`)
- `upload_max_filesize`: The maximum size of attachment in MB (default 5MB)

Example:

```
api-cli run configure-module --agent module/roundcubemail1 --data - <<EOF
{
  "host": "roundcubemail.domain.com",
  "http2https": true,
  "lets_encrypt": false,
  "mail_server": "mail1",
  "plugins": "",
  "upload_max_filesize": 5
}
EOF
```

The above command will:
- start and configure the roundcubemail instance
- configure a virtual host for trafik to access the instance

## Single sign-on (OIDC)

Work in progress, see NethServer/dev#8080. Roundcube can log users in
with an OpenID Connect provider, like the NS8 idp module, next to the
password login form. The provider is not discovered automatically yet:
the client settings are written manually in the `oidc.env` file of the
module state directory. Each start of the `roundcubemail-app` service
writes them to `config/config.oauth.php`, or removes that file if the
settings are missing.

| Variable in `oidc.env` | Required | Description |
|---|---|---|
| `OIDC_ISSUER` | yes | Issuer URL of the realm, for example `https://sso.example.org/realms/dp.example.org` |
| `OIDC_CLIENT_ID` | yes | OIDC client ID |
| `OIDC_CLIENT_SECRET` | yes | OIDC client secret |

Settings that are not secret are in the module environment:

| Environment variable | Default | Description |
|---|---|---|
| `OIDC_LOGIN_MODE` | `optional` | `optional`: the login page shows the password form and the SSO button. `exclusive`: the login page goes straight to the provider. See below |
| `OIDC_PROVIDER_NAME` | `Single Sign-On` | Label of the login button |

The client of the provider needs:

- the redirect URI `https://<host>/index.php/login/oauth`;
- the client of the mail server (Dovecot) in the token audience: Roundcube
  sends the access token to IMAP and SMTP with `OAUTHBEARER`, and Dovecot
  accepts it only if its client is in the audience. The mail module must
  have OIDC enabled too.

The user name is the `preferred_username` claim: Roundcube appends the
mail domain to it, as for password logins.

For example, with the idp module:

```
api-cli run module/idp1/register-client --data '{"domain": "dp.example.org", "module_id": "roundcubemail1", "redirect_uris": ["https://webmail.example.org/index.php/login/oauth"], "post_logout_redirect_uris": ["https://webmail.example.org/?_task=logout"], "audience": ["mail1"]}'
runagent -m roundcubemail1 sh -c 'umask 077; cat > oidc.env' <<'EOF'
OIDC_ISSUER=https://sso.example.org/realms/dp.example.org
OIDC_CLIENT_ID=roundcubemail1
OIDC_CLIENT_SECRET=<client_secret from register-client>
EOF
runagent -m roundcubemail1 systemctl --user restart roundcubemail-app.service
```

After the logout from the provider, Roundcube asks to return to its
logout page, `https://<host>/?_task=logout`. Roundcube builds this URI
itself: register it exactly in `post_logout_redirect_uris`, otherwise the
provider refuses the logout redirect.

The file is included in the module backup.

### Login mode

Set the login mode in the module environment, then restart the app
service to apply it:

```
runagent -m roundcubemail1 python3 -c 'import agent; agent.set_env("OIDC_LOGIN_MODE", "exclusive")'
runagent -m roundcubemail1 systemctl --user restart roundcubemail-app.service
```

An unknown value works as `optional`, with a warning in the log.

**Warning:** in `exclusive` mode Roundcube has no emergency login path.
It removes the user name and password fields from its login page, also
when the provider cannot be reached, so nobody can log in to the
webmail while the provider is down. To recover, switch back to
`optional` and restart the app service:

```
runagent -m roundcubemail1 python3 -c 'import agent; agent.set_env("OIDC_LOGIN_MODE", "optional")'
runagent -m roundcubemail1 systemctl --user restart roundcubemail-app.service
```

In both modes, mail clients that connect to IMAP and SMTP keep using
the LDAP passwords.

If the realm of the provider accepts only federated logins (the
`federated` login mode of the idp module), use `exclusive`: otherwise
the Roundcube password form still accepts the LDAP passwords of native
accounts, bypassing the federated provider and its multi-factor
authentication.

## Get the configuration
You can retrieve the configuration with

```
api-cli run get-configuration --agent module/roundcubemail1 --data null | jq
```

## Uninstall

To uninstall the instance:

    remove-module --no-preserve roundcubemail1

## Running tests locally

This module uses the NS8 standard testing infrastructure. For instructions on how to run the test suite locally, refer to the [Running tests locally](https://github.com/NethServer/ns8-github-actions/blob/v1/README.md#running-tests-locally) section of NS8 GitHub Actions.

## UI translation

Translated with [Weblate](https://hosted.weblate.org/projects/ns8/).

To setup the translation process:

- add [GitHub Weblate app](https://docs.weblate.org/en/latest/admin/continuous.html#github-setup) to your repository
- add your repository to [hosted.weblate.org](https://hosted.weblate.org) or ask a NethServer developer to add it to ns8 Weblate project
