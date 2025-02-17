#!/bin/bash

set -x

work_dir=$(pwd)

# check if it is empty and clone the repo
if [ -z "$(ls -A oci-test)" ]; then
    git clone git@github.com:nicholasSUSE/oci-test.git
else
    echo "The folder 'oci-test' is not empty."
    cd oci-test
    git fetch
    git pull
fi

cd $work_dir
ls