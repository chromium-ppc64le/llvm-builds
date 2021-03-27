#!/bin/bash

set -o xtrace

chmod +x ./release-cli

links=""

for f in target/*; do
  filename=$(basename -- $f)
  links+=" --assets-link {\"name\":\"${filename}\",\"url\":\"${PACKAGE_REGISTRY_URL}/${filename}\"}"
done

./release-cli create --name "LLVM ${CI_COMMIT_TAG}" --description "LLVM ${CI_COMMIT_TAG}" --tag-name ${CI_COMMIT_TAG} ${links}
