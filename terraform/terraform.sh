#!/bin/sh

set -e

setup() {
    echo "Setting up..."
    export DIR=$PWD
    export AWS_ACCESS_KEY_ID=$access_key
    export AWS_SECRET_ACCESS_KEY=$secret_key
    cd $DIR/source/$directory
}

copy_output() {
    echo "Copying output..."
    cp -r $DIR/source/$directory $DIR/terraform
}

load_cache() {
    if [ "$cache" = "true" ] && [ -d "$DIR/source/cache/.terraform" ]; then
        echo "Getting .terraform folder from cache..."
        mv $DIR/source/cache/.terraform $DIR/source/$directory
    fi
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
    copy_output
}

main() {
    if [ -z "$command" ]; then
        echo "Command is a required parameter and must be set."
        exit 1
    fi
    setup
    case "$command" in
        'fmt'      ) terraform_fmt ;;
        'get'      ) terraform_get && copy_output ;;
        'init'     ) terraform_init && copy_output ;;
        'validate' ) terraform_get && terraform_validate ;;
        'destroy'  ) terraform_init && terraform_destroy ;;
        'tests'    ) terraform_tests ;;
        *          ) terraform_init && terraform_cmd ;;
    esac
    if [ "$cache" = "true" ]; then
        echo "Caching .terraform folder..."
        mv $DIR/source/$directory/.terraform $DIR/source/cache
    fi
    echo "Done!"
}

main
