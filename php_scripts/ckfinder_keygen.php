<?php

/* Keygen for CKFinder
 * tested successfully with version 1.4.1.1
 * written by Steffen Vogel (info@steffenvogel.de)
 * reverse engenering by Micha Schwab & Steffen Vogel
 */

$chars = '123456789ABCDEFGHJKLMNPQRSTUVWXYZ';

for ($p = 0; $p <= 100; $p++) {
	for ($i = 0; $i < 13; $i++) $key[$i] = $chars{mt_rand(0, strlen($chars) - 1)};
	$key[0] = $chars{5 * mt_rand(0, floor((strlen($chars) - 1) / 5)) + 1};
	$key[12] = $chars{(strpos($chars, $key[11]) + strpos($chars, $key[8]) * 9) % (strlen($chars) - 1)};
	echo implode($key) . ', ';
}
?>