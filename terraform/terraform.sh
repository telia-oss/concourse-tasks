#!/bin/sh

set -e

GREEN='\033[1;32m'
RED='\033[0;31m'
NC='\033[0m'

header() {
    echo -e "\e[1m$1\e[0m"
}

failed() {
    echo -e "${RED}✗ $1${NC}"
}

passed() {
    echo -e "${GREEN}√ $1${NC}"
}

setup() {
    export DIR=$PWD
    export AWS_ACCESS_KEY_ID=$access_key
    export AWS_SECRET_ACCESS_KEY=$secret_key
    mkdir -p $DIR/source/cache
}

setup_tflint() {
    if [ "$cache" = "true" ] && [ -f "$DIR/source/cache/tflint" ]; then
        ln -s $DIR/source/cache/tflint /usr/local/bin
        passed "Load tflint from cache"
    else
        if [ "$cache" = "true" ]; then
            failed "Load tflint from cache (file not found)."
        fi

        curl -s -L -o /tmp/tflint.zip https://github.com/wata727/tflint/releases/download/v0.5.1/tflint_linux_amd64.zip
        unzip -o -q /tmp/tflint.zip -d $DIR/source/cache
        ln -s $DIR/source/cache/tflint /usr/local/bin/tflint
        passed "Download and install tflint"
    fi
}

load_cache() {
    if [ "$cache" = "true" ] && [ -d "$DIR/source/cache/$directory/.terraform" ]; then
        mv $DIR/source/cache/$directory/.terraform $DIR/source/$directory
        passed "Load cache"
    fi
}

save_cache() {
    if [ -d "$DIR/source/$directory/.terraform" ]; then
        mkdir -p $DIR/source/cache/$directory
        mv $DIR/source/$directory/.terraform $DIR/source/cache/$directory
        passed "Save cache"
    fi
}

terraform_tflint() {
    if [ ! -f "/usr/local/bin/tflint" ]; then
        setup_tflint
    fi
    tflint >> /dev/null
    passed "tflint"
}

terraform_fmt() {
    if ! terraform fmt -check=true >> /dev/null; then
        failed "terraform fmt (Some files need to be formatted, run 'terraform fmt' to fix.)"
        exit 1
    fi
    passed "terraform fmt"
}

terraform_get() {
    load_cache
    terraform init -backend=false -input=false >> /dev/null
    passed "terraform get (init without backend)"
}

terraform_init() {
    load_cache
    terraform init -input=false -lock-timeout=$lock_timeout >> /dev/null
    passed "terraform init"
}

terraform_validate() {
    terraform validate
    passed "terraform validate"
}

terraform_destroy() {
    terraform destroy -force -refresh=true -lock-timeout=$lock_timeout
}

terraform_cmd() {
    echo "Running terraform $command..."
    terraform $command -refresh=true -auto-approve=true -lock-timeout=$lock_timeout
}

terraform_tests() {
    terraform_fmt
    terraform_get
    terraform_validate
    terraform_tflint
}

main() {
    if [ -z "$command" ]; then
        echo "Command is a required parameter and must be set."
        exit 1
    fi
    if [ -z "$directories" ]; then
        echo "No directories provided. Please set the parameter."
        exit 1
    fi

    setup
    for directory in $directories; do
        if [ ! -d "$DIR/source/$directory" ]; then
            failed "Directory not found: $directory"
            exit 1
        fi
        cd $DIR/source/$directory
        header "Current directory: $directory"
        case "$command" in
            'fmt'      ) terraform_fmt ;;
            'get'      ) terraform_get ;;
            'init'     ) terraform_init ;;
            'validate' ) terraform_get && terraform_validate ;;
            'tflint'   ) terraform_get && terraform_tflint ;;
            'destroy'  ) terraform_init && terraform_destroy ;;
            'test'     ) terraform_tests ;;
            'tests'    ) terraform_tests ;;
            *          ) terraform_init && terraform_cmd ;;
        esac
        if [ "$cache" = "true" ]; then
            save_cache
        fi
    done
}

main
