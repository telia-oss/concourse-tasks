#!/bin/sh

set -e

setup() {
    echo "Setting up..."
    export DIR=$PWD
    export AWS_ACCESS_KEY_ID=$access_key
    export AWS_SECRET_ACCESS_KEY=$secret_key
}

load_cache() {
    if [ "$cache" = "true" ] && [ -d "$DIR/source/cache/$directory/.terraform" ]; then
        echo "Getting .terraform folder from cache..."
        mv $DIR/source/cache/$directory/.terraform $DIR/source/$directory
    fi
}

save_cache() {
    if [ -d "$DIR/source/$directory/.terraform" ]; then
        echo "Caching .terraform folder..."
        mkdir -p $DIR/source/cache/$directory
        mv $DIR/source/$directory/.terraform $DIR/source/cache/$directory
    fi
    if [ -f "/usr/local/bin/tflint" ]; then
        echo "Caching tflint..."
        mv /usr/local/bin/tflint $DIR/source/cache
    fi
}

terraform_tflint() {
    if [ "$cache" = "true" ] && [ -f "$DIR/source/cache/tflint" ]; then
        echo "Getting tflint from cache..."
        mv $DIR/source/cache/tflint /usr/local/bin
    else
        echo "Downloading and unzipping tflint..."
        curl -s -L -o /tmp/tflint.zip https://github.com/wata727/tflint/releases/download/v0.5.1/tflint_linux_amd64.zip
        unzip -o -q /tmp/tflint.zip -d /usr/local/bin
    fi
    echo "Running tflint..."
    tflint
}

terraform_fmt() {
    echo "Running terraform fmt..."
    if ! terraform fmt -check=true; then
        echo "Some terraform files need be formatted, run 'terraform fmt' to fix."
        exit 1
    fi
}

terraform_get() {
    load_cache
    echo "Running terraform get (init without backend)..."
    terraform init -backend=false -input=false
}

terraform_init() {
    load_cache
    echo "Running terraform init..."
    terraform init -input=false -lock-timeout=$lock_timeout
}

terraform_validate() {
    echo "Running terraform validate..."
    terraform validate
}

terraform_destroy() {
    echo "Running terraform (forced) destroy..."
    terraform destroy -force -refresh=true -lock-timeout=$lock_timeout
}

terraform_cmd() {
    echo "Running terraform $command..."
    terraform $command -refresh=true -auto-approve=true -lock-timeout=$lock_timeout
}

terraform_tests() {
    echo "Starting terraform tests..."
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
        cd $DIR/source/$directory
        echo "Current directory: $directory"
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
    echo "Done!"
}

main
