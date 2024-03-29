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

## Get the configuration
You can retrieve the configuration with

```
api-cli run get-configuration --agent module/roundcubemail1 --data null | jq
```

## Uninstall

To uninstall the instance:

    remove-module --no-preserve roundcubemail1

## Testing

Test the module using the `test-module.sh` script:


    ./test-module.sh <NODE_ADDR> ghcr.io/nethserver/roundcubemail:latest

The tests are made using [Robot Framework](https://robotframework.org/)

## UI translation

Translated with [Weblate](https://hosted.weblate.org/projects/ns8/).

To setup the translation process:

- add [GitHub Weblate app](https://docs.weblate.org/en/latest/admin/continuous.html#github-setup) to your repository
- add your repository to [hosted.weblate.org](https://hosted.weblate.org) or ask a NethServer developer to add it to ns8 Weblate project
