#!/usr/bin/env sh
#
# Push local container images to a remote s3 bucket as a tar archive.
# Dependencies: buildah, podman
# Author: lucas.pruvost@pm.me.
# Repository: https://github.com/intoxx/buildah-s3.
# License: MIT.
#

COLOR_SUCCESS="\033[1;32m"
COLOR_ERR="\033[1;31m"
COLOR_INFO="\033[1;36m"
COLOR_RESET="\033[0m"

# Print an error message and exit the program.
err() {
	printf "${COLOR_ERR}[ERROR]${COLOR_RESET} : "
	([ ! -z "$1" ] && echo -e $1) || echo "code $?"
	exit 1
}

# Check if the command is present on the system, exits if not.
check_cmd() {
	[ -z "$1" ] && err

	command -v $1 &> /dev/null
	[ "$?" -ne "0" ] && err "'$1' not found."
}

usage() {
	echo "Usage: S3_BUCKET=<bucket> S3_KEY=<key> S3_SECRET=<secret> push <image>"
}

# Arguments and dependencies checks.
init() {
	# Image argument
	[ -z "$1" ] && usage && err "wrong usage"

	# S3_BUCKET env argument
	[ -z "$S3_BUCKET" ] && usage && err "Missing environment variable : S3_BUCKET"

	# S3_REGION env argument
	[ -z "$S3_REGION" ] && usage && err "Missing environment variable : S3_REGION"

	# S3_ENDPOINT env argument
	[ -z "$S3_ENDPOINT" ] && usage && err "Missing environment variable : S3_ENDPOINT"

	# S3_KEY env argument
	[ -z "$S3_KEY" ] && usage && err "Missing environment variable : S3_KEY"

	# S3_SECRET env argument
	[ -z "$S3_SECRET" ] && usage && err "Missing environment variable : S3_SECRET"

	# Check for buildah
	check_cmd "buildah"

	# Check for podman
	check_cmd "podman"
}

# Init
init $@

# Archive the image
DIR=`cat /proc/sys/kernel/random/uuid`
IMAGE_NAME=${1%%:*} # return image from image:tag in $1
IMAGE_TAG=${1##*:} && ([ "$IMAGE_TAG" = "$IMAGE_NAME" ] || [ -z "$IMAGE_TAG" ]) && IMAGE_TAG=latest # same but for tag, defaulting to "latest" in case of wrong value
IMAGE_BASENAME="$IMAGE_NAME/$IMAGE_TAG"
IMAGE_PATH="$IMAGE_BASENAME.tar"
IMAGE_DIGEST="$IMAGE_BASENAME.tar.digest"

# TODO: add support to change compression through --compression-format and --compression-level arguments
mkdir -p "$DIR/$IMAGE_NAME"
buildah push --digestfile="$DIR/$IMAGE_DIGEST" $IMAGE_NAME oci-archive:"$DIR/$IMAGE_PATH":$IMAGE_NAME

[ "$?" -ne "0" ] && err "impossible to create archive"

# Push it to S3
# TODO: handle expiration through --expires argument
podman run \
	-v ./$DIR:/aws:Z \
	-e "AWS_ACCESS_KEY_ID=$S3_KEY" \
	-e "AWS_SECRET_ACCESS_KEY=$S3_SECRET" \
	-e "AWS_REGION=$S3_REGION" \
	--rm -it docker.io/amazon/aws-cli s3 \
		sync . "s3://$S3_BUCKET" \
		--endpoint-url "$S3_ENDPOINT" \
		--exclude "*" \
		--include "$IMAGE_NAME*" \
		--metadata name="$IMAGE_NAME",tag="$IMAGE_TAG",image="$IMAGE_NAME:$IMAGE_TAG"

[ "$?" -ne "0" ] && err "impossible to push" # TODO: add verbose mode

# Cleanup
rm -rf "$DIR"

# Show uploaded resources
BASE_URL="$S3_ENDPOINT/$S3_BUCKET"
echo -e "${COLOR_SUCCESS}[SUCCESS]${COLOR_RESET} files uploaded to :"
echo -e "\t$BASE_URL/$IMAGE_PATH"
echo -e "\t$BASE_URL/$IMAGE_DIGEST"
