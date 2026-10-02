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
the settings are written manually in the `oidc.env` file of the module
state directory. Each start of the `roundcubemail-app` service writes
them to `config/config.oauth.php`, or removes that file if the settings
are missing.

| Variable | Required | Description |
|---|---|---|
| `OIDC_ISSUER` | yes | Issuer URL of the realm, for example `https://sso.example.org/realms/dp.example.org` |
| `OIDC_CLIENT_ID` | yes | OIDC client ID |
| `OIDC_CLIENT_SECRET` | yes | OIDC client secret |
| `OIDC_PROVIDER_NAME` | no | Label of the login button, default `Single Sign-On` |
| `OIDC_LOGIN_REDIRECT` | no | `1` redirects the login page straight to the provider, without the password form |

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
api-cli run module/idp1/register-client --data '{"domain": "dp.example.org", "module_id": "roundcubemail1", "redirect_uris": ["https://webmail.example.org/index.php/login/oauth"], "audience": ["mail1"]}'
runagent -m roundcubemail1 sh -c 'umask 077; cat > oidc.env' <<'EOF'
OIDC_ISSUER=https://sso.example.org/realms/dp.example.org
OIDC_CLIENT_ID=roundcubemail1
OIDC_CLIENT_SECRET=<client_secret from register-client>
EOF
runagent -m roundcubemail1 systemctl --user restart roundcubemail-app.service
```

The file is included in the module backup.

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
