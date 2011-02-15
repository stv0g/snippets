<?= '<?xml version="1.0" encoding="UTF-8"' ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de-DE" lang="de-DE">
<head>
	<title>Schicke mir eine Kurznachricht</title>
	<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
	<script src="js/md5.js" type="text/javascript"></script>
	<script src="js/sms.js" type="text/javascript"></script>
</head>
	<body>
		<div id="sms_contact">
<?php

require_once 'config.php';
require_once 'blacklist.php';
require_once 'xmlrpc/xmlrpc.inc';
require_once 'sipgateAPI.php';

set_exception_handler(function($exception) {
	echo '<p style="color: red; font-weight: bold;">Fehler: [' . $exception->getCode() . '] ' . $exception->getMessage() . '</p>';
	show_form();
});

if ($_POST) {
	$sipgate = new sipgateAPI($config['username'], $config['password']);
	$balance = $sipgate->getBalance();
	$message = str_replace("\r", "", trim($_POST['message']));
	$blacklist = read_blacklist($config['blocked']);
	$delta_t = 60*5;

	if (!isset($_POST['message'])) {
		throw new Exception('Keine Nachricht!', 5);
	}
	if ($_POST['antispam'] != md5($message . ceil(time() / $delta_t))) { // check hash
		throw new Exception('Willst du mich bescheissen? Bitte aktiviere Javascript!', 1);
	}
	if (strlen($message) > 160) {
		throw new Exception('Deine Nachricht ist zu lang!');
	}
	if ($balance['CurrentBalance']['TotalIncludingVat'] < $config['reserve']) {
		throw new Exception('Sorry, aber ich habe kein Gutenhaben mehr!', 2);
	}
	if ($time = is_blacklisted($blacklist, $_SERVER['REMOTE_ADDR'])) {
		throw new Exception('Sorry, du musst ' . format_duration($config['blocked'] - (time() - $time)) . ' warten, bevor du die nächste SMS versenden kannst!', 3);
	}
	
	//$sipgate->sendSMS($recipient'], $message, NULL, $config['recipient']);
	echo '<h3>SMS wurde gesendet!</h3><p>Vielen Dank :)</p>';
	echo '<p>Du kannst deine n&auml:chste SMS in ' . format_duration($config['blocked']) . ' senden!</p>';
	echo '<p>Verbleibendes Guthaben: ' . round($balance['CurrentBalance']['TotalIncludingVat'], 2) . ' ' . $balance['CurrentBalance']['Currency'] . ' (das sind noch ' . floor(($balance['CurrentBalance']['TotalIncludingVat'] - $config['reserve']) / 0.079) . ' SMS)</p>';

	if ($_SERVER['REMOTE_ADDR'] != '172.0.0.1') $blacklist[] = array($_SERVER['REMOTE_ADDR'], time());
	
	echo '<p><a href="javascript:history.go(-1)" title="back">back</a></p>';
	write_blacklist($blacklist);
}
else {
	show_form();
}

function show_form() {
	global $config;
	$message =  (isset($_REQUEST['message'])) ? $_REQUEST['message'] : '';

	echo '<form name="sms" onsubmit="send(this);" action="' . $_SERVER['PHP_SELF'] . '" method="post">
		<table>
			<tr><td>An:</td><td>++' . $config['recipient'] . '</td></tr>
			<tr><td>Nachricht:</td><td><textarea onfocus="update_length(this);" onkeyup="update_length(this);" name="message" cols="40" rows="5">' . $message . '</textarea></td></tr>
			<tr><td>Zeichen:</td><td><span id="length">' . strlen($message) . '</span> (&uuml;brig: <span id="left" style="color: green;">' . (160 - strlen($message)) . '</span>)</td></tr>
		</table>
		<input type="hidden" name="antispam" />
		<input type="submit" value="abschicken" />
	</form>';
}

function format_duration($time) {
	if ($time < 60) {
		return $time . ' Sekunden';
	}
	elseif ($time < 3600) {
		return floor($time / 60) . ' Minuten';
	}
	else {
		return floor($time / 3600) . ':' . floor(($time % 3600) / 60) . ' Stunden';
	}
}

?>
		</div>
	</body>
</html>
