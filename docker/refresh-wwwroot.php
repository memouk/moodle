<?php
mysqli_report(MYSQLI_REPORT_OFF);
$wwwroot = getenv('MOODLE_WWWROOT');
$file = '/var/www/html/config.php';
if (!is_file($file)) {
    fwrite(STDERR, "No hay config.php para actualizar.\n");
    exit(0);
}
$config = file_get_contents($file);
if ($config === false || $config === '') {
    fwrite(STDERR, "config.php está vacío.\n");
    exit(0);
}
$updated = preg_replace(
    '/\$CFG->wwwroot\s*=\s*\'[^\']*\';/',
    "\$CFG->wwwroot   = '" . addslashes($wwwroot) . "';",
    $config,
    1
);
file_put_contents($file, $updated);

$mysqli = new mysqli(getenv('DB_HOST'), getenv('DB_USER'), getenv('DB_PASS'), getenv('DB_NAME'), 3306);
$stmt = $mysqli->prepare("UPDATE mdl_config SET value = ? WHERE name = 'wwwroot'");
$stmt->bind_param('s', $wwwroot);
$stmt->execute();
