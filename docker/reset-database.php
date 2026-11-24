<?php
mysqli_report(MYSQLI_REPORT_OFF);
$mysqli = new mysqli(getenv('DB_HOST'), getenv('DB_USER'), getenv('DB_PASS'), getenv('DB_NAME'), 3306);
if ($mysqli->connect_errno !== 0) {
    fwrite(STDERR, $mysqli->connect_error . "\n");
    exit(1);
}
$mysqli->query('SET FOREIGN_KEY_CHECKS=0');
$tables = $mysqli->query('SHOW TABLES');
while ($row = $tables->fetch_array()) {
    $mysqli->query('DROP TABLE `' . str_replace('`', '', $row[0]) . '`');
}
$mysqli->query('SET FOREIGN_KEY_CHECKS=1');
fwrite(STDERR, "Tablas de Moodle eliminadas.\n");
