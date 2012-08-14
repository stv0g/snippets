<?= '<?xml version="1.0" encoding="UTF-8"' ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de-DE" lang="de-DE">
<head>
	<title>Schicke mir eine Kurznachricht</title>
	<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
	<link rel="stylesheet" type="text/css" href="style.css">
	<script src="md5.js" type="text/javascript"></script>
	<script src="sms.js" type="text/javascript"></script>
</head>
	<body onload="parent.document.getElementById('sms_frame').height=document.body.scrollHeight; document.forms.sms_frm.message.focus()">
		<div id="sms_contact">
<?php

require_once 'config.php';
require_once 'blacklist.php';
require_once 'xmlrpc/xmlrpc.inc';
require_once 'sipgateAPI.php';

set_exception_handler(function($exception) {
	echo '<p class="error">Fehler: ' . $exception->getMessage() . '</p>';
	if (get_class($exception) != 'Exception') {
		echo '(Code: ' . $exception->getCode() . ')';
	}

	show_form();
});

if ($_POST) {
	$sipgate   = new sipgateAPI($config['username'], $config['password']);
	$balance   = $sipgate->getBalance();
	$message   = preg_replace('/\r?\n/m', '\n', trim($_POST['message']));
	$blacklist = read_blacklist($config['blocked']);

	if (!isset($_POST['message'])) {
		throw new Exception('Keine Nachricht!');
	}
	if ($message == $config['default']) {
		throw new Exception('Der Standart ist doch langweilig!');
	}
	if ($_POST['antispam'] != md5($message . ceil(time() / $config['delta']))) { // check hash
		throw new Exception('Willst du mich bescheissen? Bitte aktiviere Javascript!');
	}
	if (strlen($message) > 160) {
		throw new Exception('Deine Nachricht ist zu lang!');
	}
	if ($balance['CurrentBalance']['TotalIncludingVat'] < $config['reserve']) {
		throw new Exception('Sorry, aber ich habe kein Gutenhaben mehr!');
	}
	if ($time = is_blacklisted($blacklist, $_SERVER['REMOTE_ADDR'])) {
		throw new Exception('Sorry, du musst ' . format_duration($config['blocked'] - (time() - $time)) . ' warten, bevor du die nächste SMS versenden kannst!');
	}

	$sipgate->sendSMS($config['recipient'], $message, NULL, $config['recipient']);
	$balance = $sipgate->getBalance();
	echo '<h3>SMS wurde gesendet!</h3><p>Vielen Dank :)</p>';
	echo '<p>Du kannst deine n&auml;chste SMS in ' . format_duration($config['blocked']) . ' senden!</p>';
	echo '<p>Verbleibendes Guthaben: ' . round($balance['CurrentBalance']['TotalIncludingVat'], 2) . ' ' . $balance['CurrentBalance']['Currency'] . ' (das sind noch 
' . floor(($balance['CurrentBalance']['TotalIncludingVat'] - $config['reserve']) / 0.079) . ' SMS)</p>';

	if ($_SERVER['REMOTE_ADDR'] != '172.0.0.1') $blacklist[] = array($_SERVER['REMOTE_ADDR'], time());

	echo '<p><a href="javascript:history.go(-1)" title="back">zu&uuml;ck</a></p>';
	write_blacklist($blacklist);
}
else {
	show_form();
}

function show_form() {
	global $config;
	$message =  (isset($_REQUEST['message'])) ? $_REQUEST['message'] : $config['default'];

	echo '<form name="sms_frm" onsubmit="return send(this);" action="' . $_SERVER['PHP_SELF'] . '" method="post">
		<table>
			<!-- <tr><td><span class="head">An:</span> <span id="number">++' . $config['recipient'] . '</span></td></tr> -->
			<tr><td><textarea onfocus="update_length(this);" onkeyup="update_length(this);" name="message" cols="40" rows="5">' . $message . '</textarea></td></tr>
			<tr><td><span class="head">Zeichen:</span> <span id="length">' . strlen($message) . '</span> (&uuml;brig: <span id="left" style="color: green;">' . (160 - strlen($message)) . '</span>)</td></tr>
		</table>
		<input type="hidden" name="antispam" />
		<input id="send_btn" type="submit" value="abschicken" />
	</form>';
}

function format_duration($time) {
	if ($time < 60) return $time . ' Sekunden';
	elseif ($time < 3600) return floor($time / 60) . ' Minuten';
	else return floor($time / 3600) . ':' . sprintf('%02d', floor(($time % 3600) / 60)) . ' Stunden';
}

?>
		</div>
	</body>
</html>
