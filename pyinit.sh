#! /bin/bash
#
# =============================================================== #
#
# Initiate a python project using git, pyenv and venv
# By Morten Ginnerskov
#
# Last modified: 2021.05.05-15:12 +0200
#
# =============================================================== #
# TODO:
#   - Optional python version
#   - Github user?
#   - Project description
#   - Private or not

PRIVATE="false"
USER=$( whoami )
DESCRIPTION=""
PYTHON_VERSION=$( pyenv versions \
    | awk '{ if( $1 ~ /^[23]\.[[:digit:]]+\.[[:digit:]]+/) print $1 ; else if ( $2 ~ /^[23]\.[[:digit:]]+\.[[:digit:]]+/) print $2 }'
    | tail -1
)
#     | awk '{ if( substr($1,0,1) == "3" && length($1) == 5 ) print $1; else if ( substr($1,0,1) == "*" && length($2) == 5 ) print $2 }' \
#     | awk '$1 ~ /^[23]\.[[:digit:]]+\.[[:digit:]]+/ { print $1 }; else if ( substr($1,0,1) == "*" )' \
# Fix to use regex to

# Use environment variable if it is there, otherwise use current directory
if [[ -n $DEV_PRJ_HOME ]]; then
    DIR=$DEV_PRJ_HOME
else
    DIR=$( pwd )
fi

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -p|--private)
        PRIVATE="true"
        shift
        ;;
    -u|--user)
        USER="$2"
        shift
        shift
        ;;
    -d|--description)
        DESCRIPTION="$2"
        shift
        shift
        ;;
    -v|--version)
        PYTHON_VERSION="$2"
        shift
        shift
        ;;
    -D|--directory)
        DIR="$2"
        shift
        shift
        ;;
    *)
        POSITIONAL+=("$1")
        shift
        ;;
esac
done
set -- "${POSITIONAL[@]}"

PRJ_NAME=$1
PRJ_NAME=PRJ_NAME[-1]
PRJ_DIR=$PRJ_HOME+'/'+$PRJ_NAME


# If no python version specified, use the newest standard python version available
# Otherwise, check if available, if not install it

# mkdir $PRJ_DIR
# Create project directory and initiate a git project
/usr/bin/git init PRJ_DIR

echo "# $PRJ_NAME" >> $PRJ_DIR/README.git

/usr/bin/curl -X POST -H "Authorization: token $(pass personal/github-create-repo-token)" -u 'Ginner' https://api.github.com/user/repos -d '{"name":"$PRJ_NAME","description":"$description","private":"true"}'

/usr/bin/git remote add origin git@ginner-github:Ginner/$PRJ_NAME.git

$HOME/.pyenv/bin/pyenv local X.Y.Z
$HOME/.pyenv/bin/pyenv rehash
