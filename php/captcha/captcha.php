<?php

header('Content-Type: image/gif', true);
header('Cache-Control: no-store', true);

/* Configuration */
$conf['width'] = 145;
$conf['height'] = 50;
$conf['font_size'] = 18;
$conf['length'] = 5;

$conf['fonts'] = array(
	'technine',
	'texasled',
	'xband',
	'3000',
	'42',
	'39smooth'
);

$conf['alphabet'] = array(
	'A', 'B', 'C', 'D', 'E', 'F', 'G',
	'H', 'Q', 'J', 'K', 'L', 'M', 'N',
	'P', 'R', 'S', 'T', 'U', 'V', 'Y',
	'W', '2', '3', '4', '5', '6', '7'
);

$img = imagecreatetruecolor($conf['width'], $conf['height']);
//$col = imagecolorallocate($img, rand(200, 255), rand(200, 255), rand(200, 255));
$col = imagecolorallocate($img, 255, 255, 255);

imagefill($img, 0, 0, $col);

$captcha = '';
$x = 10;

for ($p = 0; $p < 15; $p++) {
	$col = imagecolorallocate($img, rand(150, 255), rand(150, 255), rand(150, 255));
	imageline($img, rand(0, $conf['width']), rand(0, $conf['height']), rand(0, $conf['width']), rand(0, $conf['height']), $col);
}

for($i = 0; $i < $conf['length']; $i++) {

	$chr = $conf['alphabet'][rand(0, count($conf['alphabet']) - 1)];
	$captcha .= $chr;

	$col = imagecolorallocate($img, rand(0, 199), rand(0, 199), rand(0, 199));
	$font = 'fonts/' . $conf['fonts'][rand(0, count($conf['fonts']) - 1)] . '.ttf';

	$y = 25 + rand(0, 20);
	$angle = rand(0, 45);

	imagettftext($img, $conf['font_size'], $angle, $x, $y, $col, $font, $chr);

	$dim = imagettfbbox($conf['font_size'], $angle, $font, $chr);
	$x += $dim[4] + abs($dim[6]) + 10;
}

imagegif($img);
imagedestroy($img);

$_SESSION['captcha'] = $captcha;

?> 
