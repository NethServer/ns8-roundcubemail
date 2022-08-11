# ns8-roundcubemail

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
- `mail_server`: a fully qualified domain name for the mail server
- `plugins`: a list of plugins(coma separated) to enable in roundcubemail
- `upload_max_filesize`: The maximum size of attachment in MB (default 5MB)
- `imap_port`: The port number of the IMAP server (1-65535)
- `smtp_port`: The port number of the SMTP server (1-65535)
- `starttls_imap`: Use starttls to encrypt the communication for the IMAP server (true/false)
- `starttls_smtp`: Use starttls to encrypt the communication for the SMTP server (true/false)
- `encrypted_imap`: Use tls to encrypt the communication for the IMAP server (true/false)
- `encrypted_smtp`: Use tls to encrypt the communication for the SMTP server (true/false)
- `tls_verify_imap`: Verify the certificate of the imap server (true/false)
- `tls_verify_smtp`: Verify the certificate of the smtp server (true/false)

Example:

```
api-cli run configure-module --agent module/roundcubemail1 --data - <<EOF
{
  "host": "roundcubemail.domain.com",
  "http2https": true,
  "lets_encrypt": false,
  "mail_server": "mail.domain.com",
  "plugins": "archive,zipdownload",
  "upload_max_filesize": 5,
  "imap_port": 993,
  "smtp_port": 465,
  "starttls_imap": false,
  "starttls_smtp": false,
  "encrypted_imap": true,
  "encrypted_smtp": true,
  "tls_verify_imap": false,
  "tls_verify_smtp": false
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
