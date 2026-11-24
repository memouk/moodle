<?php
$wwwroot = getenv('MOODLE_WWWROOT');
$cfg = [
    'dbtype' => 'mariadb',
    'dblibrary' => 'native',
    'dbhost' => getenv('DB_HOST'),
    'dbname' => getenv('DB_NAME'),
    'dbuser' => getenv('DB_USER'),
    'dbpass' => getenv('DB_PASS'),
    'prefix' => 'mdl_',
    'dboptions' => [
        'dbpersist' => false,
        'dbsocket' => false,
        'dbport' => 3306,
        'dbcollation' => 'utf8mb4_unicode_ci',
    ],
];

$lines = ["<?php", "unset(\$CFG);", "global \$CFG;", "\$CFG = new stdClass();", ""];
foreach ($cfg as $key => $value) {
    $lines[] = '$CFG->' . $key . ' = ' . var_export($value, true) . ';';
}
$lines[] = '$CFG->wwwroot   = ' . var_export($wwwroot, true) . ';';
$lines[] = "\$CFG->dataroot  = '/var/www/moodledata';";
$lines[] = "\$CFG->admin     = 'admin';";
$lines[] = '$CFG->directorypermissions = 02777;';
$lines[] = '';
$lines[] = "require_once(__DIR__ . '/lib/setup.php');";
$lines[] = '';

file_put_contents('/var/www/html/config.php', implode("\n", $lines));
fwrite(STDERR, "Se escribió config.php para $wwwroot\n");
