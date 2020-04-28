# omeka-s docker generator

allows the generation of docker containers of omeka-s applications
built using [git submodules]. it's still kind of a work in progress
as we move to aws (no idea if this works in production).

## prerequisite: set up an application repository

in order to make things easier on ourselves, we've set up a repository
pattern for bundling an omeka-s instance with modules and themes using
git's submodules.

to get started, init a new repository and add the omeka-s core as a submodule.

```bash
$ git init
$ git submodule add https://github.com/omeka/omeka-s core
```

this will store the omeka-s code in a subdirectory labeled `core`. if you're
fine with using the latest commit to core's `master` branch, you're ready
to add modules + themes. if you want to use the latest tag, you'll want to
do the following:

```bash
$ cd core
$ git fetch && git fetch --tags
$ git checkout <tag>
$ cd ..
```

(note: we only use use tagged versions of core, modules, and themes. this pattern
is the same across all three.)

add modules and themes the same way, storing them in the appropriate subdirectories:

```bash
$ git submodule add https://github.com/zerocrates/AltText modules/AltText
$ git submodule add https://github.com/omeka-s-themes/thedaily themes/thedaily
```

eventually, you'll have a `tree` that looks like:

```bash
├── README.md
├── core
│   └── ... all of the files for omeka-s
├── modules
│   ├── AltText
│   ├── CSVImport
│   ├── CustomVocab
│   ├── FileSideload
│   ├── Folksonomy
│   ├── Mapping
│   ├── MetadataBrowse
│   ├── Omeka2Importer
│   ├── RightsStatements
│   ├── Search
│   ├── Sharing
│   └── ValueSuggest
└── themes
    ├── centerrow
    ├── cozy
    ├── default
    ├── papers
    └── thedaily
```

commit that repo + push it to remote location (like github).

## building a docker image from your repository

now that you have a remote repository with the modules + themes stored,
time to build the docker image.

from this directory (replace the `GIT_URL` value with that of your application),
run:

```bash
docker build \
       --build-args GIT_URL=https://github.com/malantonio/lvehc-omeka-example \
       -t lafayettecollegelibraries/lvehc-omeka:latest \
       .
```

this will clone the repository (+ submodules), and move the `modules/` and `themes/`
directories to their respective locations within the omeka-s code.

if you have different submodule directory names, you can change them with build arguments.

build argument     | default value
-------------------|--------------
`OMEKA_CORE_DIR`   | `core`
`OMEKA_MODULE_DIR` | `modules`
`OMEKA_THEME_DIR`  | `themes`

## deploying the image

the generated image's [entrypoint script] creates the `config/database.ini` file needed
to connect to the site's database using environment variables.

environment variable | default value
---------------------|----------------
`OMEKA_DB_USER`      | `omeka`
`OMEKA_DB_PASSWORD`  | `omeka_db_password`
`OMEKA_DB_NAME`      | `omeka`
`OMEKA_DB_HOST`      | `localhost`
`OMEKA_DB_PORT`      | `3306`

using `docker-compose`, you can set up the db using the base `mariadb` image,
or `mysql` if that's your thing. the following example will get you started
(change `services.app.build.context` to be a path to the Dockerfile within here).

```yaml
version: '3.7'

volumes:
  app:
  db:

services:
  app:
    build:
      context: .
      args:
        GIT_URL: https://github.com/malantonio/lvehc-omeka-example
    ports:
      - 4000:80
    volumes:
      - app:/var/www/html/files
    environment:
      OMEKA_DB_USER: omeka
      OMEKA_DB_PASSWORD: omeka_db_password
      OMEKA_DB_NAME: omeka
      OMEKA_DB_HOST: db:3306
    depends_on:
      - db

  db:
    image: mariadb:10.4
    volumes:
      - db:/var/lib/mysql
    environment:
      MYSQL_RANDOM_ROOT_PASSWORD: 'yes'
      MYSQL_DATABASE: omeka
      MYSQL_USER: omeka
      MYSQL_PASSWORD: omeka_db_password
```

[git submodules]: https://git-scm.com/book/en/v2/Git-Tools-Submodules
[entrypoint script]: ./scripts/docker-entrypoint.sh
