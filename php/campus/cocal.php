<?php

/* Constants */
$scriptUrl = ((!empty($_SERVER['HTTPS'])) ? 'https' : 'http') . '://' . $_SERVER['SERVER_NAME'] . $_SERVER['PHP_SELF'];
$baseUrl = 'https://www.campus.rwth-aachen.de/';
$homePath = 'office/default.asp';
$loginPath = 'office/views/campus/redirect.asp';
$calPath = 'office/views/calendar/iCalExport.asp';
$logoutPath = 'office/system/login/logoff.asp';
$roomPath = 'rwth/all/room.asp'

/* Functions */
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

	if ($cookieFile) {
		curl_fixcookie($cookieFile);
	}

	return $output;
}

function get_address($db, $room) {
	$result = sqlite_query($db, 'SELECT address FROM rooms WHERE id = "' . sqlite_escape_string($room). '";');
	return ($result && sqlite_valid($result)) ? sqlite_fetch_array($result) : false;
}

function set_address($db, $room, $address) {
	sqlite_exec($db, 'INSERT OR REPLACE INTO rooms VALUES (
				"' . sqlite_escape_string($address['id']) . '",
				"' . sqlite_escape_string($address['address']) . '",
				"' . sqlite_escape_string($address['cluster']) . '",
				"' . sqlite_escape_string($address['building']) . '",
				"' . sqlite_escape_string($address['building_no']) . '",
				"' . sqlite_escape_string($address['room']) . '",
				"' . sqlite_escape_string($address['room_no']) . '",
				"' . sqlite_escape_string($address['floor']) . '"
			);', $error);
}

function crawl_address($room) {
	$response = curl_request('GET', $basePath . $roomPath . '?room=' . urlencode($room));

	$matches = array();
	preg_match("/<td class=\"default\">H.rsaalgruppe<\/td><td class=\"default\">(?P<cluster>[^<]*)<\/td>/", $response, $matches);
	preg_match("/<td class=\"default\">Geb.udeanschrift<\/td><td class=\"default\">(?P<address>[^<]*)<\/td>/", $response, $matches);
	preg_match("/<td class=\"default\">Geb.udebezeichnung<\/td><td class=\"default\">(?P<building>[^<]*)<\/td>/", $response, $matches);
	preg_match("/<td class=\"default\">Geb.udenummer<\/td><td class=\"default\">(?P<building_no>[^<]*)<\/td>/", $response, $matches);
	preg_match("/<td class=\"default\">Raumname<\/td><td class=\"default\">(?P<room>[^<]*)<\/td>/", $response, $matches);
	preg_match("/<td class=\"default\">Raumnummer<\/td><td class=\"default\">(?P<room_no>[^<]*)<\/td>/", $response, $matches);
	preg_match("/<td class=\"default\">Geschoss<\/td><td class=\"default\">(?P<floor>[^<]*)<\/td>/", $response, $matches);

	foreach ($matches as $key => $value) {
		if (is_numeric($key) unset($matches[$key]);
	}

	array_walk($matches, function ($value) {
		return preg_replace('/[ ]{2,}/sm', ' ', utf8_encode($value));
	});

	return (count($matches['address']) ? $matches : false;
}

function error() {
	global $scriptUrl;

	header("HTTP/1.0 500 Internal Server Error");
	echo '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
		<html>
			<head>
				<meta http-equiv="REFRESH" content="5;url=' . $scriptUrl . '">
				<link rel="stylesheet" type="text/css" href="style.css">
				<meta http-equiv="content-type" content="text/html; charset=UTF-8">
				<link rel="shortcut icon" href="/favicon.png" type="image/png">
				<link rel="icon" href="/favicon.png" type="image/png">
			</head>
			<body>
				<div id="content"><h2>Sorry an error occured!<br />Check your credentials and try again!</h2></div>
			</body>
		</html>';
	die();
}

/* Code */
if (!empty($_GET['hash'])) {
	$cipher = base64_decode($_GET['hash']);
	if (strpos($cipher, ':')) {
		list($matrnr, $passwd) = explode(':', $cipher);
	}
}
else if (!empty($_GET['u']) && !empty($_GET['p'])) {
	$matrnr = $_GET['u'];
	$passwd = $_GET['p'];
}

if (isset($matrnr) && isset($passwd)) {
	/* perform login to get session cookie */
	$cookieFile = tempnam('/tmp', 'campus_');

	/* open database */
	$db = sqlite_open('cocal.db');
	$result = sqlite_query($db, "SELECT name FROM sqlite_master WHERE type='table' AND name='rooms';");
	if (!sqlite_valid($result)) {
		sqlite_exec($db, 'CREATE TABLE rooms (name VARCHAR(255), address VARCHAR(255));');
	}

	curl_request('GET', $baseUrl . $homePath, $cookieFile);

	$loginParams = array(
		'login'		=> urlencode('> Login'),
		'p'		=> urlencode($passwd),
		'u'		=> urlencode($matrnr)
	);

	curl_request('POST', $baseUrl . $loginPath, $cookieFile, $loginParams);

	/* request calendar */
	$calParams = array(
		'startdt'	=> strftime('%d.%m.%Y', time() - 7*24*60*60), /* eine Woche Vergangenheit */
		'enddt'		=> strftime('%d.%m.%Y', time() + 6*31*24*60*60) /* halbes Jahr ZUukunft */
	);

	$response = curl_request('GET', $baseUrl . $calPath, $cookieFile, $calParams);

	/* filter some changes */
	list($headers, $body) = explode("\r\n\r\n", $response, 2);

	if (substr($body, 0, strlen("BEGIN:VCALENDAR")) != "BEGIN:VCALENDAR") {
		error();
	}

	/* header pass through */
	$headers = array_slice(explode("\r\n", $headers), 1);
	foreach ($headers as $header) {
		list($key, $value) = explode(": ", $header);

		switch($key) {
			case 'Content-Disposition':
				$value = 'attachment; filename=campus_office_' . $matrnr . '.ics';
				break;
			case 'Content-Type':
				$value .= '; charset=utf-8';
			break;
		}

		if ($key != 'Content-Length') { // ignore old length
			header($key . ': ' . $value);
		}
	}

	$location = '';
	$lines = explode("\r\n", $body);
	foreach ($lines as $line) {
		if ($line) {
			list($key, $value) = explode(":", $line);
			switch ($key) {
				case 'END':
					if ($value == 'VEVENT') flush();
					unset($location);
					break;

				case 'LOCATION':
					$location = $value;
					$room = strtok($location, " ");
					$address = get_address($db, $room);

					if ($address === false) {
						$crawled = crawl_address($room);
						set_address($db, $room, $address);
					}

					if ($address) {
						$value = $address['address'] . ', Aachen';
					}
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
	sqlite_close($db);
}
else {
	echo '<?xml version="1.0" ?>';
?>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
	<title>/dev/nulll - CampusOffice to Google Sync</title>
	<script src="jquery-1.7.2.min.js" type="text/javascript"></script>
	<script src="scripts.js" type="text/javascript"></script>
	<script src="base64.js" type="text/javascript"></script>
	<script type="text/javascript">
		function unique(length) {
			var chars = "0123456789abcdefghiklmnopqrstuvwxyz";
			var string = '';

			while (length--) {
				var rnum = Math.floor(Math.random() * chars.length);
				string += chars.substring(rnum,rnum+1);
			}

			return string;
		}

		function encode() {
			var cipher = $('#matrnr').val() + ':' + $('#passwd').val();
			var link = '<?php echo $scriptUrl ?>?hash=' + Base64.encode(cipher);

			$.ajax({
				url : 'http://d.0l.de/add.json',
				data : {
					rdata : encodeURI(link),
					host : unique(24),
					type : 'URL',
					pw : $('#passwd').val()
				},
				dataType : 'jsonp',
				success : function(data) {
					$(data).each(function(index, value) {
						if (value.type == 'success' && value.description == 'uri redirection added to db') {
							var host = value.data[0].host.punycode;
							var zone = value.data[0].host.zone.name;
							var link = 'http://' + host + '.' + zone;

							$('#result a').attr('href', link);
				                        $('#result a').text(link);
							$('#result').show(300);
						}
					});
				}

			});
		}
	</script>
	<link rel="stylesheet" type="text/css" href="style.css">
	<meta http-equiv="content-type" content="text/html; charset=UTF-8">
	<link rel="shortcut icon" href="/favicon.png" type="image/png">
	<link rel="icon" href="/favicon.png" type="image/png">
</head>
<body>

<div id="content">
	<header>
		<a href="http://0l.de"><img src="http://0l.de/_media/nulll_small.png" alt="0l" /></a>
		<h1>CampusOffice to Google Sync</h1>
	</header>

	<table style="width: 330px; margin: 10px auto;">
		<tr>
			<td><label for="matrnr">Matrikel-Nr:</label></td>
			<td><input id="matrnr" type="text" name="u" /></td>
		</tr>
		<tr>
			<td><label for="passwd">Passwort:</label></td>
			<td><input id="passwd" type="password" name="p" /></td>
		</tr>
	</table>

	<input type="button" onclick="encode()" value="Get Calendar!" />

	<p id="result" style="display: none">
		<span>Das ist der fertige Link:</span><br />
		<a href=""></a>
	</p>

	<footer>
		<p>by <a href="http://www.steffenvogel.de">Steffen Vogel</a> - <a href="http://0l.de/tools/campus">help</a></p>
	</footer>
</div>
</body>
</html>

<?php
}
?>
