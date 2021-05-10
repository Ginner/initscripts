#! /bin/bash -x
#
# =============================================================== #
#
# Initiate a python project using git, pyenv and venv
# By Morten Ginnerskov
#
# Last modified: 2021.05.10-15:31 +0200
#
# =============================================================== #
# TODO:
#   - Dry run mode (-n)
#   - Help text
#   - Supress output

private="false"
user=$( whoami )
description=""
python_versions=$( pyenv versions \
    | awk '{ if( $1 ~ /^[23]\.[[:digit:]]+\.[[:digit:]]+/) print $1 ; else if ( $2 ~ /^[23]\.[[:digit:]]+\.[[:digit:]]+/) print $2 }'
)
python_version=$( echo "$python_versions" | tail --lines=1 )

# Use environment variable if it is there, otherwise use current directory
if [[ -n $DEV_PRJ_HOME ]]; then
    dir=$DEV_PRJ_HOME
else
    dir=$( pwd )
fi

positional=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -p|--private)
        private="true"
        shift
        ;;
    -u|--user)
        user="$2"
        shift
        shift
        ;;
    -d|--description)
        description="$2"
        shift
        shift
        ;;
    -v|--version)
        python_version="$2"
        shift
        shift
        ;;
    -D|--directory)
        dir="$2"
        shift
        shift
        ;;
    *)
        positional+=("$1")
        shift
        ;;
esac
done
set -- "${positional[@]}"

prj_name=$1

prj_dir="$dir$prj_name"

if [[ -d "$prj_dir" ]]; then
    echo "A directory named $prj_name already exists" >&2
    exit 1
elif [[ ! -d "$dir" ]]; then
    echo "Your project directory is not valid. You might have an empty DEV_PRJ_HOME variable or supplied an empty string to the 'directory option.'" >&2
    exit 1
fi

# Initiate git version control
/usr/bin/git init "$prj_dir"
cd "$prj_dir" || { echo "Failed to change into project directory." >&2; exit 1; }

# If no python version specified, use the newest standard python version available
# Otherwise, check if available, if not install it
if [[ "$python_versions" == *"$python_version"* ]]; then
    "$HOME"/.pyenv/bin/pyenv local "$python_version"
else
    "$HOME"/.pyenv/bin/pyenv install "$python_version" && "$HOME"/.pyenv/bin/pyenv local "$python_version"
fi

# Create initial README file
echo "# $prj_name" >> "$prj_dir"/README.git

# Create project on Github
/usr/bin/curl -X POST -H "Authorization: token $(pass personal/github-create-repo-token)" -u "$user" https://api.github.com/user/repos -d "{\"name\":\"$prj_name\",\"description\":\"$description\",\"private\":\"$private\"}"

# Add the github remote
/usr/bin/git remote add origin git@"$user"-github:"$user"/"$prj_name".git

# Make sure the pyenv is up to date
"$HOME"/.pyenv/bin/pyenv rehash

# Initiate python virtual environment
python -m venv .venv

# Inform the user
if [[ -e "$prj_dir/.python-version" ]]; then
    echo "pyenv environment initiated with python version $( cat "$prj_dir"/.python-version )"
else
    echo "Something went wrong... A pyenv environment has not been initiated." >&2
    exit 1
fi

if [[ -d "$prj_dir/.venv" ]]; then
    echo "A virtual environment has been initiated. Activate it from within the project folder with 'source ./venv/bin/activate'. Your prompt should then reflect the change. Deactivate the virtual environment with 'deactivate'."
else
    echo "Something went wrong... A virtual environment has not been initiated." >&2
    exit 1
fi

if [[ -d "$prj_dir/.git" ]]; then
    echo "A git repository has been initiated for the project."
else
    echo "Something went wrong... Version control has not been initiated." >&2
    exit 1
fi
