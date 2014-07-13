<?php

require_once 'include/classes/gc.php';

error_reporting(E_ERROR | E_PARSE);
header("Content-type: application/xml");

if (empty($_GET['BBOX']))
	$bbox = array(8.537836074829102, 49.8414144408833, 8.615598678588867, 49.874393381852194);
else
	$bbox = explode(',', $_GET['BBOX']);
	
$ctids = array(2, 3, 4, 5, 6, 7, 8, 9, 11, 13);

$gc = new GC('user', 'password');
$data = $gc->getData($bbox);
$caches = $data['cs']['cc'];

echo '<?xml version="1.0" encoding="UTF-8"?>
		<kml xmlns = "http://earth.google.com/kml/2.1">
			<Document>';

foreach($ctids as $i)
	echo '<Style id="ctid-' . $i . '">
			<IconStyle>
				<Icon>
					<href>http://www.geocaching.com/images/kml/' . $i . '.png</href>
				</Icon>
			</IconStyle>
		</Style>';

foreach($caches as $cache)
	echo '<Placemark id="' . $cache['id'] . '">
			<name><![CDATA[' . $cache['nn'] . ']]></name>
			<description><![CDATA[
				WP: ' . $cache['gc'] . '<br />
				<a href="http://www.geocaching.com/seek/cache_details.aspx?wp=' . $cache['gc'] . '">visit gc.com</a><br />
				<a href="http://www.geocaching.com/my/watchlist.aspx?w=' . $cache['id'] . '">watch listing</a><br />]]>
				</description>
			<Point>
				<coordinates>' . $cache['lon'] . ',' . $cache['lat'] . '</coordinates>
			</Point>
			<styleUrl>#ctid-' . $cache['ctid'] . '</styleUrl>
		</Placemark>';

echo '</Document>
</kml>';

?>