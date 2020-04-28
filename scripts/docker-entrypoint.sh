#!/bin/bash
set -euo pipefail

omeka_root="/var/www/html"
module_path="$omeka_root/modules"
db_config_path="$omeka_root/config/database.ini"
composer="$omeka_root/build/composer.phar"

# an array of omeka-s modules that need to be installed, since we're
# adding them via git and not their distributions. this will be converted
# into a space-delimited string and passed to the install-modules script.
# it should be noted that this doesn't need to be on a per-app basis.
# this script will skip modules that it doesn't find.
modules_to_install=(CSVImport)

envs=(
  OMEKA_DB_USER
  OMEKA_DB_PASSWORD
  OMEKA_DB_NAME
  OMEKA_DB_HOST
)

# creates a config/database.ini file from environment variables
cat > "$db_config_path" <<END_CAT
user     = ${OMEKA_DB_USER:-omeka}
password = ${OMEKA_DB_PASSWORD:-omeka_db_password}
dbname   = ${OMEKA_DB_NAME:-omeka}
host     = ${OMEKA_DB_HOST:-localhost}
port     = ${OMEKA_DB_PORT:-3306}
END_CAT

# tests a db connection
# see: https://github.com/docker-library/wordpress/blob/master/php7.4/apache/docker-entrypoint.sh#L235-L282
if ! php -- <<'EOPHP'
<?php

$stderr = fopen('php://stderr', 'w');
list($host, $socket) = explode(':', getenv('OMEKA_DB_HOST'), 2);
$port = getenv('OMEKA_DB_PORT') ? getenv('OMEKA_DB_PORT') : 3306;

// cast our port to an int if it's present
if (is_numeric($socket)) {
  $port = (int) $socket;
  $socket = null;
}

$user = getenv('OMEKA_DB_USER');
$pass = getenv('OMEKA_DB_PASSWORD');
$dbName = getenv('OMEKA_DB_NAME');

$maxTries = 10;

do {
  $mysql = new mysqli($host, $user, $pass, $dbName, $port);
  if ($mysql->connect_error) {
    fwrite($stderr, "\n" . 'MySQL Connection Error: (' . $mysql->connect_errno . ') ' . $mysql->connect_error . "\n");
    --$maxTries;
    if ($maxTries <= 0) {
      exit(1);
    }
    sleep(5);
  }
} while ($mysql->connect_error);

if (!$mysql->query('CREATE DATABASE IF NOT EXISTS `' . $mysql->real_escape_string($dbName) . '`')) {
  fwrite($stderr, "\n" . 'MySQL "CREATE DATABASE" Error: ' . $mysql->error . "\n");
  $mysql->close();
  exit(1);
}
$mysql->close();
EOPHP

then
  echo >&2
  echo >&2 "WARNING: unable to establish a database connection to '$OMEKA_DB_HOST'"
  echo >&2 '  continuing anyways (which might have unexpected results)'
  echo >&2
fi

# some modules need to be installed with composer if they're sourced from
# their git repos (as we're doing).
for module in "${modules_to_install[@]}"
do
  dir="$module_path/$module"
  if [ -d "$dir" ]; then
    cd $dir && $composer install
  fi
done

# clearing out the relevant envrionment variables so that stray "phpinfo()" calls
# don't leak secrets from our code
for e in "${envs[@]}"; do
  unset "$e"
done

exec "$@"
