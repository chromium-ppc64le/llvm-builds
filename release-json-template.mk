# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

define release_json_template :=
{
    "name": "LLVM $(llvm_rev)",
    "tag_name": "v$(llvm_rev)",
    "description": "LLVM $(llvm_rev)",
    "assets": {
        "links": [
            {
                "name": "$(llvm-dist-file)",
                "url": "$(CI_JOB_URL)/artifacts/raw/target/$(llvm-dist-file)"
            }
        ]
    }
}
endef

export release_json_template

