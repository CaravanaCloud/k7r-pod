#!/bin/bash
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

BUCKET="767398003706-sde-cur"

aws s3 sync "s3://${BUCKET}/" "$DIR/data/"
