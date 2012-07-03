<?php

$baseUrl = 'https://www.campus.rwth-aachen.de/office/';
$homePath = 'default.asp';
$loginPath = 'views/campus/redirect.asp';
$calPath = 'views/calendar/iCalExport.asp';
$logoutPath = 'system/login/logoff.asp';

/* perform login to get session cookie */
$cookieFile = tempnam('/tmp', 'campus_');

curl_request('GET', $baseUrl . $homePath, $cookieFile);
curl_fixcookie($cookieFile);

$loginParams = array(
	'login'		=> urlencode('> Login'),
	'p'		=> urlencode($_GET['p']),
	'u'		=> urlencode($_GET['u'])
);

curl_request('POST', $baseUrl . $loginPath, $cookieFile, $loginParams);
curl_fixcookie($cookieFile);

/* request calendar */
// TODO args
$calParams = array(
	'startdt'	=> strftime('%d.%m.%Y'),
	'enddt'		=> strftime('%d.%m.%Y', time() + 6*31*24*60*60) /* halbes Jahr == ein Semester */
);

$response = curl_request('GET', $baseUrl . $calPath, $cookieFile, $calParams);
curl_fixcookie($cookieFile);

/* filter some changes */
list($headers, $body) = explode("\r\n\r\n", $response, 2);

$db = sqlite_open('campus.db');
$create = false;
$result = sqlite_query($db, "SELECT name FROM sqlite_master WHERE type='table' AND name='rooms';");
if (!sqlite_valid($result)) {
	sqlite_exec($db, 'CREATE TABLE rooms (name VARCHAR(255), address VARCHAR(255));');
}

/* header pass through */
$headers = array_slice(explode("\r\n", $headers), 1);
foreach ($headers as $header) {
	list($key, $value) = explode(": ", $header);

	switch($key) {
		case 'Content-Disposition':
			$value = 'attachment; filename=campus_office_' . $_GET['u'] . '.ics';
			break;
		case 'Content-Type':
			//$value .= '; charset=utf-8';
			$value = 'text/plain; charset=utf-8';
			break;
	}

	if ($key != 'Content-Disposition')
		header($key . ': ' . $value);
}

$location = '';
$lines = explode("\r\n", $body);
foreach ($lines as $line) {
	if ($line) {
		list($key, $value) = explode(":", $line);
		switch ($key) {
			case 'LOCATION':
				$location = $value;
				$room = strtok($location, " ");
				$address = get_address($db, $room);

				if ($address === false) {
					$address = preg_replace('/[ ]{2,}/sm', ' ', utf8_encode(crawl_address($room)));
					set_address($db, $room, $address);
					$crawled = true;
				}
				$value = $address . ', Aachen';
				break;

			case 'DESCRIPTION':
				if ($value) $value .= '\n';
				$value .= $location;
				break;
		}

		echo $key . ':' . $value;
	}
	echo "\r\n";
}

/* cleanup */
unlink($cookieFile);

function curl_fixcookie($cookieFile) {
	$contents = file_get_contents($cookieFile);
	$lines = explode("\n", $contents);

	foreach ($lines as $i => $line) {
		if (strpos($line, "#HttpOnly_") === 0) {
			$lines[$i] = substr($line, strlen("#HttpOnly_"));
		}
	}

	$contents = implode("\n", $lines);
	file_put_contents($cookieFile, $contents);
}

function curl_request($method, $url, $cookieFile = false, $params = array()) {
	$ch = curl_init();

	$options = array(
		CURLOPT_URL		=> $url,
		CURLOPT_FOLLOWLOCATION	=> true,
		CURLOPT_RETURNTRANSFER	=> true,
		CURLOPT_HEADER		=> true
	);

	if ($cookieFile) {
		$options[CURLOPT_COOKIEFILE] = $cookieFile;
		$options[CURLOPT_COOKIEJAR] = $cookieFile;
	}

	array_walk($params, function(&$value, $key) { $value = $key . '=' . $value; });

	if ($params && strtolower($method) == 'post') {
		$options[CURLOPT_POST] = true;
		$options[CURLOPT_POSTFIELDS] = implode("&", $params);
	}
	else if ($params) { /* assuming default mehtod: GET */
		$options[CURLOPT_URL] .= '?' . implode('&', $params);
	}

	curl_setopt_array($ch, $options);
	$output = curl_exec($ch);
	curl_close($ch);

	return $output;
}

function get_address($db, $room) {
	$result = sqlite_query($db, 'SELECT address FROM rooms WHERE name = "' . sqlite_escape_string($room). '";');
	return ($result && sqlite_valid($result)) ? sqlite_fetch_string($result) : false;
}

function set_address($db, $room, $address) {
	sqlite_exec($db, 'INSERT INTO rooms VALUES ("' . sqlite_escape_string($room) . '", "' . sqlite_escape_string($address) . '");', $error);
}

function crawl_address($room) {
	$response = curl_request('GET', 'http://www.campus.rwth-aachen.de/rwth/all/room.asp?room=' . urlencode($room));

	$matches = array();
	$r = preg_match("/<td class=\"default\">Geb.udeanschrift<\/td><td class=\"default\">([^<]*)<\/td>/", $response, $matches);

	return ($r > 0) ? $matches[1] : false;
}

?>
