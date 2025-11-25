#!/bin/sh
#
# Copyright (C) 2025 Nethesis S.r.l.
# SPDX-License-Identifier: GPL-3.0-or-later
#

set -e

# Redirect any output to the journal (stderr)
exec 1>&2

url="${1:?missing url}"
user="${2:?missing user}"

cookiejar="$(mktemp)"
token="$(curl -s -c "${cookiejar}" "${url}" | grep 'name="_token"' | sed -E 's/.*value="([^"]+)".*/\1/')"
curl -s -b "${cookiejar}" -c "${cookiejar}" \
    -X POST "${url}/?_task=login" \
    -d "_token=${token}" \
    -d "_task=login" \
    -d "_action=login" \
    -d "_user=${user}" \
    -d "_pass=Nethesis,1234" \
    -d "_timezone=_default_" \
    -d "_url=_task=login"
curl -s -b "${cookiejar}" "${url}/?_task=mail"
