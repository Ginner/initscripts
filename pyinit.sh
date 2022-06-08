#! /bin/bash
#
# =============================================================== #
#
# Initiate a python project using git, pyenv and venv
# By Ginner
#
# Last modified: 2022.06.08-06:42 +0200
#
# =============================================================== #

# Initiate variables
private="false"
user=$( git config --get user.name | tr '[:upper:]' '[:lower:]' )
description=""
python_versions=$( pyenv versions \
    | awk '{ if( $1 ~ /^[23]\.[[:digit:]]+\.[[:digit:]]+/) print $1 ; else if ( $2 ~ /^[23]\.[[:digit:]]+\.[[:digit:]]+/) print $2 }'
)
python_version=$( echo "$python_versions" | tail --lines=1 )
git="1"
dry="0"

# Use environment variable if it is there, otherwise use current directory
if [[ -n $DEV_PRJ_HOME ]]; then
    dir=$DEV_PRJ_HOME
else
    dir=$( pwd )
fi

read -r -d '' helptext <<- 'EOH'
Initiates a python project, creating a folder and initiates git, pyenv and a virtual environment.

Usage: pyinit [OPTIONS] PROJECT-NAME

Options:
    -p, --private                   Create the GitHub project as a private project.
    -u, --user <USER>               Use github user USER. Defaults to git user.name.
    -d, --description <DESCRIPTION> Short description for the GitHub project.
    -V, --version <X.Y.Z>           Set the python version to be used. Defaults to the newest
                                    available version.
    -D, --directory <DIR>           Directory in which to create the project. Default will use
                                    environment variable DEV_PRJ_HOME if available, if not it will use the current working directory.
    -n, --dry-run                   Show what happens without actually doing anything.
    -l, --local                     Initiate the project without git (e.g. you're going to clone a repo).
    -h, --help                      Print help and exit.

Virtual Environment:
    The virtual environment is activated from within the project-directory, by running `$ source .venv/bin/activate` and deactivated by running `$ deactivate`.

Examples:
    pyinit -p -u John test-project  Creates a project named 'test-project', using the GitHub
                                    user 'john'. The GitHub project will be private.
EOH

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
        user="${2,,}"
        shift
        shift
        ;;
    -d|--description)
        description="$2"
        shift
        shift
        ;;
    -V|--version)
        python_version="$2"
        shift
        shift
        ;;
    -D|--directory)
        dir="$2"
        shift
        shift
        ;;
    -h|--help)
        echo "$helptext"
        exit 0
        ;;
    -n|--dry-run )
        dry="1"
        shift
        ;;
    -l|--local )
        git="0"
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

prj_dir="$dir/$prj_name"

# Dry run
if [[ "$dry" -eq 1 ]]; then
    echo "The command will create a project directory named '$prj_name' in '$dir'."
    echo "The project will be using python version $python_version."
    if [[ "$git" -eq 1 ]]; then
        echo -n "It will attempt to create a GitHub repo named '$prj_name' under user '$user', the repo will be"
        if [[ "$private" == "true" ]]; then
            echo " private."
        else
            echo " public."
        fi
        if [[ -n "$description" ]]; then
            printf "The GitHub repo will be given the following description:\n"
            echo "$description"
        fi
    fi
    exit 0
fi

# Check directories
if [[ -d "$prj_dir" ]]; then
    echo "A directory named $prj_name already exists" >&2
    exit 1
elif [[ ! -d "$dir" ]]; then
    echo "Your project directory is not valid. You might have an empty DEV_PRJ_HOME variable or supplied an empty string to the 'directory option.'" >&2
    exit 1
fi

mkdir --verbose "$prj_dir"
cd "$prj_dir" || { echo "Failed to change into project directory." >&2; exit 1; }

# If no python version specified, use the newest standard python version available
# Otherwise, check if available, if not install it
while true; do
    if [[ "$python_versions" == *"$python_version"* ]]; then
        "$HOME"/.pyenv/bin/pyenv local "$python_version"
        break
    else
        cat <<-END
Python version $python_version is not installed.

    [1] Attempt to install the version and proceed
    [2] Show installed versions
    [3] Exit

END
        echo -n "What do you wish to do? [1/2/3]: "
        read -r ans
        case "$ans" in
            1 )
                "$HOME"/.pyenv/bin/pyenv install "$python_version" && "$HOME"/.pyenv/bin/pyenv local "$python_version"
                break
                ;;
            2 )
                echo "Installed python versions:"
                echo "$python_versions"
                echo " "
                echo -n "Which version do you want? (it doesn't have to be in the list): "
                read -r python_version
                continue
                ;;
            3 )
                cd "$dir" || exit 0
                rmdir --verbose "$prj_dir"
                exit 0
                ;;
            * )
                echo "$ans is not an option, choose 1, 2 or 3."
                continue
                ;;
        esac
    fi
done

# Create initial README file
echo "# $prj_name" >> "$prj_dir"/README.md

# Initiate git version control
if [[ "$git" -eq 1 ]]; then
    /usr/bin/git init "$prj_dir"
    # Create project on Github
    /usr/bin/curl -X POST -H "Authorization: token $(pass personal/github-create-repo-token | /usr/bin/head -1)" -u "$user" https://api.github.com/user/repos -d "{\"name\":\"$prj_name\",\"description\":\"$description\",\"private\":\"$private\"}"
    # Add the github remote
    /usr/bin/git remote add origin git@"$user"-github:"$user"/"$prj_name".git
fi

# Make sure the pyenv is up to date
"$HOME"/.pyenv/bin/pyenv rehash

# Initiate python virtual environment
python -m venv .venv

# Download a .gitignore file
/usr/bin/curl -O https://raw.githubusercontent.com/Ginner/gitignore/master/python/.gitignore

# Inform the user
if [[ -e "$prj_dir/.python-version" ]]; then
    echo "pyenv environment initiated with python version $( cat "$prj_dir"/.python-version )"
else
    echo "Something went wrong... A pyenv environment has not been initiated." >&2
    exit 1
fi

if [[ -d "$prj_dir/.venv" ]]; then
    echo "A virtual environment has been initiated. Activate it from within the project folder with 'source .venv/bin/activate'. Your prompt should then reflect the change. Deactivate the virtual environment with 'deactivate'."
else
    echo "Something went wrong... A virtual environment has not been initiated." >&2
    exit 1
fi

if [[ -d "$prj_dir/.git" ]]; then
    echo "A git repository has been initiated for the project."
elif [[ "$git" -eq 0 ]]; then
    echo "No git repository initiated."
else
    echo "Something went wrong... Version control has not been initiated." >&2
    exit 1
fi

if [[ -e "$prj_dir/.gitignore" ]]; then
    echo "A .gitignore file has been downloaded. You should go through it to make sure the files you intend to version control are not ignored. "
else
    echo "No .gitignore file has been downloaded." >&2
    exit 1
fi
