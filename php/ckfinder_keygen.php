<?php
/**
 * Keygen for CKFinder
 * tested successfully with version 1.4.1.1
 * written by Steffen Vogel (post@steffenvogel.de)
 * reverse engenering by Micha Schwab & Steffen Vogel
 */
?>

<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de-DE" lang="de-DE">
<head>
	<title>Keygen for CKFinder</title>
	<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
	<script src="scripts.js" type="text/javascript"></script>
	<link rel="stylesheet" type="text/css" href="style.css">
	<meta http-equiv="content-type" content="text/html; charset=UTF-8">
</head>
<body>

<div id="content">

<header>
	<a href="http://0l.de"><img src="http://0l.de/_media/nulll_small.png" alt="0l" /></a>
	<h1>Keygen for CKFinder</h1>
</header>

<p>tested successfully with version 1.4.1.1</p>

<pre>

<?php
$chars = '123456789ABCDEFGHJKLMNPQRSTUVWXYZ';

for ($p = 0; $p <= 10; $p++) {
	for ($i = 0; $i < 13; $i++) $key[$i] = $chars{mt_rand(0, strlen($chars) - 1)};
	$key[0] = $chars{5 * mt_rand(0, floor((strlen($chars) - 1) / 5)) + 1};
	$key[12] = $chars{(strpos($chars, $key[11]) + strpos($chars, $key[8]) * 9) % (strlen($chars) - 1)};
	echo implode($key) . '<br />';
}
?>

</pre>
</div>
</body>
</html>
