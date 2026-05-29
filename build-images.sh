#!/bin/bash

#
# Copyright (C) 2022 Nethesis S.r.l.
# SPDX-License-Identifier: GPL-3.0-or-later
#

# Terminate on error
set -e

# Prepare variables for later use
images=()
# The image will be pushed to GitHub container registry
repobase="${REPOBASE:-ghcr.io/nethserver}"
# Configure the image name
reponame="roundcubemail"
roundcube_image="docker.io/roundcube/roundcubemail:1.7.1-apache"

# Extract the upstream version from the image tag, to set it in the metadata
roundcube_tag="${roundcube_image##*:}"
roundcube_upstream_version="${roundcube_tag%-apache}"
metadata_file="ui/public/metadata.json"
metadata_backup=$(mktemp)

cleanup() {
    cp "${metadata_backup}" "${metadata_file}"
    rm -f "${metadata_backup}"
}

cp "${metadata_file}" "${metadata_backup}"
trap cleanup EXIT

sed -i "s/\"upstream_name\": \"[^\"]*\"/\"upstream_name\": \"Roundcube webmail ${roundcube_upstream_version}\"/" "${metadata_file}"

# Create a new empty container image
container=$(buildah from scratch)

# Reuse existing nodebuilder-roundcubemail container, to speed up builds
if ! buildah containers --format "{{.ContainerName}}" | grep -q nodebuilder-roundcubemail; then
    echo "Pulling NodeJS runtime..."
    buildah from --name nodebuilder-roundcubemail -v "${PWD}:/usr/src:Z" docker.io/library/node:24-slim
fi

echo "Build static UI files with node..."
buildah run --env="NODE_OPTIONS=--openssl-legacy-provider" nodebuilder-roundcubemail sh -c "cd /usr/src/ui && yarn install && yarn build"

# Add imageroot directory to the container image
buildah add "${container}" imageroot /imageroot
buildah add "${container}" ui/dist /ui
# Setup the entrypoint, ask to reserve one TCP port with the label and set a rootless container
buildah config --entrypoint=/ \
    --label="org.nethserver.authorizations=traefik@node:routeadm mail@any:mailadm cluster:accountconsumer" \
    --label="org.nethserver.tcp-ports-demand=1" \
    --label="org.nethserver.rootfull=0" \
    --label="org.nethserver.min-core=3.12.4-0" \
    --label="org.nethserver.images=docker.io/mariadb:10.11.17 ${roundcube_image}" \
    "${container}"
# Commit the image
buildah commit "${container}" "${repobase}/${reponame}"

# Append the image URL to the images array
images+=("${repobase}/${reponame}")

#
# NOTICE:
#
# It is possible to build and publish multiple images.
#
# 1. create another buildah container
# 2. add things to it and commit it
# 3. append the image url to the images array
#

#
# Setup CI when pushing to Github. 
# Warning! docker::// protocol expects lowercase letters (,,)
if [[ -n "${CI}" ]]; then
    # Set output value for Github Actions
    printf "::set-output name=images::%s\n" "${images[*],,}"
else
    # Just print info for manual push
    printf "Publish the images with:\n\n"
    for image in "${images[@],,}"; do printf "  buildah push %s docker://%s:%s\n" "${image}" "${image}" "${IMAGETAG:-latest}" ; done
    printf "\n"
fi
