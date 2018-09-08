# Docker Dev-Env

Maintainer: @macwinnie <git@macwinnie.me>

## System-Requirements

This Environment is thought to set up a web development environment on MacOS and Debian Linux systems. It does not provide any IDE, Docker-Host-Installation, etc.

Required are:

* `python` / `python3` installed
* `pip` – `python`-Library installed
* `Docker` installed

## Folder structure

```
./
├── README.md
│
├── images            # within this folder, you should prepare your image definitions
│
├── init              # the actual script part of this repository
│   │
│   ├── config        # holds definition files for all other scripts
│   │
│   ├── container     # subfolders are `categories`, bejond them the
│   │   │             # definition files for containers are sorted
│   │   ├── default
│   │   └── system
│   │       ├── database.sh    # `system.database`
│   │       │                  #    is a MariaDB container
│   │       ├── phpmyadmin.sh  # `system.phpmyadmin`
│   │       │                  #    provides a PMA instance
│   │       ├── portainer.sh   # `system.portainer`
│   │       │                  #    provide Porainer instance
│   │       └── traefik.sh     # `system.traefik`
│   │                          #    manages HTTP(S) Requests as reverse proxy
│   │
│   ├── create.sh     # script for creation of new definition files
│   │
│   ├── manage.sh     # script for managing containers
│   │
│   └── templates     # folder for Jinja2 templates used by scripts
│
└── persistentdata    # the folder our persistent container data will be hold
```

## How to use

The Scripts should be located in an Dev-Folder – i.e. `~/Development/init_docker`. There will be created a folder structure under `~/Development/container` (directory `container` placed in the parent folder of `init_docker` directory) where Container-Data will live in.

After installation by `git clone https://github.com/macwinnie/docker_devenv.git ~/Development/init_docker`, you can do the following:

### Create a new Container-Definition-File

For creating a new definition file, you can simply run `./create.sh` within the `init_docker` directory. The script will lead you through the creation process by asking you some questions.

### Manage container

Managing containers is easy through the `./manage.sh` script. The container definition files are sorted by so called categories for some structure. The resulting container is named after the schema `category.container`.

### Aliasing on the terminal

Since one does not always want to change directory to this repository if one wants to manage docker containers, these bash commands could help you to create aliases for working with these scripts – assuming you are in the root of this project:

#### Linux
```sh
DEF_DST="$( cd ; pwd -P )/.profile"
SCRIPT_PATH="$( pwd -P )/init/"
sed -i '/alias cntmanage=/d' $DEF_DST
sed -i '/alias cntcreate=/d' $DEF_DST
echo "alias cntmanage='${SCRIPT_PATH}manage.sh'" >> $DEF_DST
echo "alias cntcreate='${SCRIPT_PATH}create.sh'" >> $DEF_DST
```

#### MacOS
```sh
DEF_DST="$( cd ; pwd -P )/.profile"
SCRIPT_PATH="$( pwd -P )/init/"
sed -i '' '/alias cntmanage=/d' $DEF_DST
sed -i '' '/alias cntcreate=/d' $DEF_DST
echo "alias cntmanage='${SCRIPT_PATH}manage.sh'" >> $DEF_DST
echo "alias cntcreate='${SCRIPT_PATH}create.sh'" >> $DEF_DST
```

#### Using our internal zsh-config

```sh
SCRIPT_PATH="$( pwd -P )/init/"
alias cntmanage=$SCRIPT_PATH'manage.sh'
alias cntcreate=$SCRIPT_PATH'create.sh'
``

ATTENTION: you probably have to adjust the `DEF_DST` variable to match your preferred destination for the aliases – i.e. `~/.zprofile` if you are using `zsh`.
