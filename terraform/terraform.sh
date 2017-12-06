#!/bin/sh

set -e

print() {
    local GREEN='\033[1;32m'
    local YELLOW='\033[1;33m'
    local RED='\033[0;31m'
    local NC='\033[0m'
    local BOLD='\e[1m'
    local REGULAR='\e[0m'
    case "$1" in
        'failure' ) echo -e "${RED}✗ $2${NC}" ;;
        'success' ) echo -e "${GREEN}√ $2${NC}" ;;
        'warning' ) echo -e "${YELLOW}⚠ $2${NC}" ;;
        'header'  ) echo -e "${BOLD}$2${REGULAR}" ;;
    esac
}

setup() {
    export DIR="$PWD"
    export AWS_ACCESS_KEY_ID="${access_key}"
    export AWS_SECRET_ACCESS_KEY="${secret_key}"
    mkdir -p $DIR/source/cache
}

install_tflint() {
    curl -s -L -o /tmp/tflint.zip https://github.com/wata727/tflint/releases/download/v0.5.1/tflint_linux_amd64.zip
    unzip -o -q /tmp/tflint.zip -d $DIR/source/cache
    ln -s $DIR/source/cache/tflint /usr/local/bin/tflint
    print success "Download and install tflint"
}

load_tflint() {
    if [ "$cache" = "true" ] && [ -f "$DIR/source/cache/tflint" ]; then
        ln -s $DIR/source/cache/tflint /usr/local/bin
        print success "Load tflint from cache"
    else
        if [ "$cache" = "true" ]; then
            print warning "Load tflint from cache (file not found)"
        fi
        install_tflint
    fi
}

load_cache() {
    if [ "$cache" = "true" ] && [ -d "$DIR/source/cache/$directory/.terraform" ]; then
        mv $DIR/source/cache/$directory/.terraform $DIR/source/$directory
        print success "Load .terraform from cache"
    else
        print warning "Load .terraform from cache (file not found)"
    fi
}

save_cache() {
    if [ -d "$DIR/source/$directory/.terraform" ]; then
        mkdir -p $DIR/source/cache/$directory
        mv $DIR/source/$directory/.terraform $DIR/source/cache/$directory
        print success "Save cache"
    fi
}

terraform_tflint() {
    if [ ! -f "/usr/local/bin/tflint" ]; then
        load_tflint
    fi
    tflint >> /dev/null
    print success "tflint"
}

terraform_fmt() {
    if ! terraform fmt -check=true >> /dev/null; then
        print failure "terraform fmt (Some files need to be formatted, run 'terraform fmt' to fix.)"
        exit 1
    fi
    print success "terraform fmt"
}

terraform_get() {
    load_cache
    # NOTE: We are using init here to download providers in addition to modules.
    terraform init -backend=false -input=false >> /dev/null
    terraform get -update=true >> /dev/null
    print success "terraform get (init without backend)"
}

terraform_init() {
    load_cache
    terraform init -input=false -lock-timeout=$lock_timeout >> /dev/null
    print success "terraform init"
}

terraform_validate() {
    terraform validate
    print success "terraform validate"
}

terraform_destroy() {
    terraform destroy -force -refresh=true -lock-timeout=$lock_timeout
}

terraform_apply() {
    terraform apply -refresh=true -auto-approve=true -lock-timeout=$lock_timeout
}

terraform_test() {
    terraform_fmt
    terraform_get
    terraform_validate
    # terraform_tflint
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
            print failure "Directory not found: $directory"
            exit 1
        fi
        cd $DIR/source/$directory
        print header "Current directory: $directory"
        case "$command" in
            'fmt'      ) terraform_fmt ;;
            'get'      ) terraform_get ;;
            'init'     ) terraform_init ;;
            'validate' ) terraform_get && terraform_validate ;;
            'tflint'   ) terraform_get && terraform_tflint ;;
            'test'     ) terraform_test ;;
            'tests'    ) terraform_test ;;
            'destroy'  ) terraform_init && terraform_destroy ;;
            'apply'    ) terraform_init && terraform_apply ;;
            *          ) echo "Command not supported: $command" && exit 1;;
        esac
        if [ "$cache" = "true" ]; then
            save_cache
        fi
    done
}

main
