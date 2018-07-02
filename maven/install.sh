#!/bin/sh

set -euo pipefail

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
    export MVN_DIR="${directory:-$DIR/source}"
    export MVN_RELEASE="${release_url}"
    export MVN_SNAPSHOT="${snapshot_url}"
    export MVN_USERNAME="${username}"
    export MVN_PASSWORD="${password}"
}

make_settings() {
    mkdir -p $DIR/.m2/repository
    if [ ! -z "$MVN_USERNAME" ] && [ ! -z "$MVN_PASSWORD" ]; then
        cat > $DIR/settings.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<settings>
	<servers>
        <server>
            <id>$MVN_RELEASE</id>
            <username>$MVN_USERNAME</username>
            <password>$MVN_PASSWORD</password>
        </server>
        <server>
            <id>$MVN_SNAPSHOT</id>
            <username>$MVN_USERNAME</username>
            <password>$MVN_PASSWORD</password>
        </server>
	</servers>
	<localRepository>$DIR/.m2/repository</localRepository>
</settings>
EOF
    else
        print warning "No username and/or password set for Maven repository."
        cat > $DIR/settings.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<settings>
	<localRepository>$DIR/.m2/repository</localRepository>
</settings>
EOF
    fi
    print success "Make settings.xml"
}

mvn_build() {
    mvn -q -f $MVN_DIR/pom.xml --settings $DIR/settings.xml install
    print success "Maven build"
    cp -p "$(ls -t $MVN_DIR/target/*.jar | grep -v /orig | head -1)" jar-files/app.jar
    print success "Saved .jar to output"
}
