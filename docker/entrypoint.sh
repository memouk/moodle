#!/bin/sh
set -eu

dataroot=/var/www/moodledata
mkdir -p "$dataroot"
chown -R www-data:www-data "$dataroot"

if [ "${MOODLE_WWWROOT:-auto}" = "auto" ] || [ -z "${MOODLE_WWWROOT:-}" ]; then
    ip=$(curl -fsS https://checkip.amazonaws.com | tr -d '[:space:]')
    MOODLE_WWWROOT="http://${ip}"
    export MOODLE_WWWROOT
fi

ln -sf /proc/self/fd/2 /var/log/apache2/error.log
apache2-foreground &
apache_pid=$!

php -r '
mysqli_report(MYSQLI_REPORT_OFF);
$host = getenv("DB_HOST");
$user = getenv("DB_USER");
$pass = getenv("DB_PASS");
$name = getenv("DB_NAME");
fwrite(STDERR, "Esperando a MariaDB en $host\n");
for ($i = 0; $i < 60; $i++) {
    $mysqli = mysqli_init();
    $mysqli->options(MYSQLI_OPT_CONNECT_TIMEOUT, 5);
    if (@$mysqli->real_connect($host, $user, $pass, $name, 3306)) {
        $mysqli->close();
        fwrite(STDERR, "MariaDB respondió.\n");
        exit(0);
    }
    fwrite(STDERR, "Intento " . ($i + 1) . ": " . $mysqli->connect_error . "\n");
    sleep(5);
}
fwrite(STDERR, "La base no respondió a tiempo.\n");
exit(1);
'

installed=$(php -r '
mysqli_report(MYSQLI_REPORT_OFF);
$mysqli = new mysqli(getenv("DB_HOST"), getenv("DB_USER"), getenv("DB_PASS"), getenv("DB_NAME"), 3306);
if ($mysqli->connect_errno !== 0) {
    fwrite(STDERR, $mysqli->connect_error . "\n");
    exit(1);
}
$result = $mysqli->query("SHOW TABLES LIKE \"mdl_config\"");
echo ($result && $result->num_rows > 0) ? "yes" : "no";
')

if [ "$installed" = "no" ]; then
    su --preserve-environment -s /bin/sh www-data -c "cd /var/www/html && php admin/cli/install.php \
        --lang=es \
        --wwwroot=\"$MOODLE_WWWROOT\" \
        --dataroot=/var/www/moodledata \
        --dbtype=mariadb \
        --dbhost=\"$DB_HOST\" \
        --dbport=3306 \
        --dbname=\"$DB_NAME\" \
        --dbuser=\"$DB_USER\" \
        --dbpass=\"$DB_PASS\" \
        --fullname=\"$MOODLE_FULLNAME\" \
        --shortname=\"$MOODLE_SHORTNAME\" \
        --adminuser=admin \
        --adminpass=\"$ADMIN_PASS\" \
        --adminemail=\"$ADMIN_EMAIL\" \
        --agree-license \
        --non-interactive \
        --allow-unstable"
else
    if [ ! -f /var/www/html/config.php ]; then
        php /var/www/html/docker/write-config.php
    else
        php /var/www/html/docker/refresh-wwwroot.php
    fi
    chown www-data:www-data /var/www/html/config.php
    if ! su --preserve-environment -s /bin/sh www-data -c "cd /var/www/html && php admin/cli/upgrade.php --non-interactive --allow-unstable"; then
        echo "La base quedó a medias. Se vacía y se instala de nuevo." >&2
        php /var/www/html/docker/reset-database.php
        rm -f /var/www/html/config.php
        su --preserve-environment -s /bin/sh www-data -c "cd /var/www/html && php admin/cli/install.php \
            --lang=es \
            --wwwroot=\"$MOODLE_WWWROOT\" \
            --dataroot=/var/www/moodledata \
            --dbtype=mariadb \
            --dbhost=\"$DB_HOST\" \
            --dbport=3306 \
            --dbname=\"$DB_NAME\" \
            --dbuser=\"$DB_USER\" \
            --dbpass=\"$DB_PASS\" \
            --fullname=\"$MOODLE_FULLNAME\" \
            --shortname=\"$MOODLE_SHORTNAME\" \
            --adminuser=admin \
            --adminpass=\"$ADMIN_PASS\" \
            --adminemail=\"$ADMIN_EMAIL\" \
            --agree-license \
            --non-interactive \
            --allow-unstable"
    fi
fi

wait "$apache_pid"
