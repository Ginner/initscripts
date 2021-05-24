# initscripts
Various init-scripts used for automating the initiation of different projects.

## Pyinit
Initiates a python project, creating a folder, initiates git, pyenv and a virtual environment.

The script will have to be executable and in your path.

It will attempt to use the environment variable `DEV_PRJ_HOME` as the project home folder and create the project there, as a subfolder. If the variable isn't available, it'll default to create the project in the current directory.

```
# Setup for the init-scripts, put it in your .bashrc, .zshrc or whichever
export DEV_PRJ_HOME="$HOME/Development"
export PATH="$PATH:$HOME/bin"
```

Activate the virtual environment from within the project folder with `$ source .venv/bin/activate`. Deactivate the environment with `$ deactivate`.

Use `pyinit -h` for usage.

