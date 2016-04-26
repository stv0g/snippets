<?php
error_reporting(E_ERROR | E_PARSE);

header('content-type: text/html; charset=UTF-8');

require_once 'include/classes/gc.php';

if (empty($_GET['BBOX']))
	$bbox = array(8.537836074829102, 49.8414144408833, 8.615598678588867, 49.874393381852194);
else
	$bbox = explode(',', $_GET['BBOX']);

$start_time = microtime(true);

$gc = new GC('user', 'password');
$data = $gc->getData($bbox);

$exec_time = round((microtime(true) - $start_time), 4);

$caches = $data['cs']['cc'];

echo '<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<title>efficent gc.com spider</title>
		<meta content="text/html; charset=UTF-8" http-equiv="content-type"/>
	</head>
	<body>
		<table><tr><td>ID</td><td>Latitude</td><td>Longitude</td><td>GC-WP</td><td>Typ</td><td>Name</td><td>Found</td><td>Own</td><td>Active</td></tr>';

foreach ($caches as $cache) {
	echo '<tr>';

	echo '<td>' . $cache['id'] . '</td>';
	echo '<td>' . $cache['lat'] . '</td>';
	echo '<td>' . $cache['lon'] . '</td>';
	echo '<td><a href="http://www.geocaching.com/seek/cache_details.aspx?wp=' . $cache['gc'] . '">' . $cache['gc'] . '</a></td>';
	switch($cache['ctid']) {
		case 1:
			$img = '';
			break;
		case 2:
			$img = 'gc-traditional.gif';
			break;
		case 3:
			$img = 'gc-multi.gif';
			break;
		case 8:
			$img = 'gc-mystery.gif';
			break;
		case 11:
			$img = 'gc-webcam.gif';
			break;
		default:
			$img = 'Error: ctid = ' . $cache['ctid'];
	}
	echo '<td><img src="icons/' . $img . '" alt="' . $img . '" /></td>';
	echo '<td>' . $cache['nn'] . '</td>';

	echo '<td><img src="icons/' . (($cache['f']) ? 'accept' : 'delete') . '.png" alt="" /></td>';
	echo '<td><img src="icons/' . (($cache['o']) ? 'accept' : 'delete') . '.png" alt="" /></td>';
	echo '<td><img src="icons/' . (($cache['ia']) ? 'accept' : 'delete') . '.png" alt="" /></td>';
	echo '</tr>';
}
echo '</table><br />';
echo '<div id="count">Count: ' . $data['cs']['count'] . '</div>';
echo '<div id="count">PM: <img src="icons/' . (($data['cs']['pm']) ? 'accept' : 'delete') . '" alt="" /></div>';
echo '<div id="count">LI: <img src="icons/' . (($data['cs']['li']) ? 'accept' : 'delete') . '" alt="" /></div>';
echo '<div id="count">Dist: ' . $data['cs']['dist'] . '</div>';
echo '<div id="count">ET: ' . $data['cs']['et'] . '</div>';
echo '<div id="exec_time">Zeit: ' . $exec_time . ' sec</div>';
echo '</body></html>';


?>