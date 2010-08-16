<?php

//header('Content-type: image/png');

function gd_graph($data) {
	$im = imagecreate(count($data), max($data));

	echo 'Breite: ' . count($data) . 'Hoehe: ' . max($data);

	$linecol = imagecolorallocate($im, 0, 0, 255);

	foreach($data as $x => $y) {
		imageline($im, $x, $height, $x, $y, $linecol);
	}

	return $im;
}

$url = 'http://www.google.com/search?num=1&q=';
$agent = "Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4) Gecko/20030624 Netscape/7.1 (ax)"; 
$reffer = 'http://www.google.de';
$prefix['de'] = 'von ungefaer <b>';
$prefix['en'] = 'of about <b>';

$from = ($_GET['from']) ? (int) $_GET['from'] : 0;
$to = ($_GET['to']) ? (int) $_GET['to'] : 3;
$lang = ($_GET['lang']) ? $_GET['lang'] : 'en';

for ($i = $from; $i < $to + 1; $i++) {
	$ch = curl_init();
	curl_setopt($ch, CURLOPT_URL,$url . $i);
	curl_setopt($ch, CURLOPT_HEADER, false);
	curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
	$count[$p] = curl_exec($ch);
	curl_close($ch);

	$count[$p] = substr($count[$p], strpos($count[$p], $prefix[$lang]) + strlen($prefix[$lang]));
	$count[$p] = substr($count[$p], 0, strpos($count[$p], '</b>'));

	$count[$p] = (int) str_replace(',', '', $count[$p]);
	$p++;
}

ImagePNG(gd_graph($count));

?>
