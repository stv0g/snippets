<?php
@error_reporting(E_ALL);
@ini_set('arg_separator.output','&amp;');
@ini_set('display_errors','on');

set_time_limit(20);

$n = empty($_GET['n']) ? 5 : (int) $_GET['n'];
if ($n >  13) {
	die('Sorry but his is too large!');
}

echo '<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<title>n-Damen Problem - Backtracking</title>
<link rel="stylesheet" type="text/css" href="schach.css">
<script src="schach.js" type="text/javascript"></script>
</head>
<body>
<div id="wrapper">
<div id="header">n-Damen Problem</div>
';

$start = microtime(true);
$solutions = shell_exec('./dame ' . $n);
$end = microtime(true);
$diff = round(($end - $start) * 1000);
$count = count(explode("\n", $solutions));

echo 'F&uuml;r das n-Damen-Problem mit Schachbrettgr&ouml;&szlig;e ' . $n . ' wurden ' . $count . ' L&ouml;sungen gefunden.<br /><br />
<select id="sols" onchange="schach(this.value)" size="2">';

foreach (explode("\n", $solutions) as $solution) {
	echo '<option value="' . $solution . '">' . $solution . '</option>';
}

echo '</select>
<div id="show">Bitte eine L&ouml;sung w&auml;hlen, um diese anzuzeigen.</div>
<br style="clear:both" />
<br />Dazu wurde folgende Zeit ben&ouml;tigt: ' . $diff . ' ms.
<form action="index.php" method="get">
Schachbrettgr&ouml;&szlig;e = <select onchange="submit()" name="n">';

for ($i = 3; $i < 14; $i++) {
	echo '<option ' . (($i == $n) ? 'selected="selected" ' : '') . 'value="' . $i . '">' . $i . '</option>';
}

echo '</select></form>
<div id="copy">&copy; Steffen Vogel<br />
<a href="mailto:post@steffenvogel.de">post@steffenvogel.de</a><br />
<a href="https://www.steffenvogel.de">https://www.steffenvogel.de</a><br />
Based on Micha\'s Javascript & CSS frontend</div>
</div>
</body>
</html>';

?>
