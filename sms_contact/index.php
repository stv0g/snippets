<?= '<?xml version="1.0" encoding="UTF-8"' ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de-DE" lang="de-DE">
<head>
	<title>send me a (short) message</title>
	<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
	<script src="js/md5.js" type="text/javascript"></script>
	<script src="js/sms.js" type="text/javascript"></script>
</head>
	<body>
		<div id="sms_contact">
<?php

set_exception_handler(function($exception) {
	echo '<p style="color: red; font-weight: bold;">Error: [' . $exception->getCode() . '] ' . $exception->getMessage() . '</p>';
});

require_once 'xmlrpc/lib/xmlrpc.inc';
require_once 'sipgateAPI.php';
require_once 'blacklist.php';
require_once 'config.php';

$sipgate = new sipgateAPI($username, $password);
$balance = $sipgate->getBalance();

//echo '<p>Guthaben: ' . round($balance['CurrentBalance']['TotalIncludingVat'], 2) . ' ' . $balance['CurrentBalance']['Currency'] . '</p>';

if ($_POST) {
	$message = str_replace("\r", "", trim($_POST['message']));
	$blacklist = read_blacklist($blocked);

	if (!isset($_POST['message'])) {
		throw new Exception('No message!', 5);
	}
	if ($_POST['antispam'] != md5($message)) {
		throw new Exception('Are you cheating me?! Please activate Javascript!', 1);
	}
	if (strlen($message) > 160) {
		throw new Exception('Your message is too long!');
	}
	if ($balance['CurrentBalance']['TotalIncludingVat'] < 1) {
		throw new Exception('No balance left!', 2);
	}
	if ($time = is_blacklisted($blacklist, $_SERVER['REMOTE_ADDR'])) {
		throw new Exception('You can only send one SMS per day! Please wait ' . format_duration($blocked - (time() - $time)) . '!', 3);
	}
	
	//$sipgate->sendSMS($mobilenumber, $message, NULL, $mobilenumber);
	if ($_SERVER['REMOTE_ADDR'] != '172.0.0.1') $blacklist[] = array($_SERVER['REMOTE_ADDR'], time());
	
	echo '<h3>SMS has been send!</h3>
	<p>Thank you :)</p>
	<p><a href="javascript:history.go(-1)" title="back">back</a></p>';
	write_blacklist($blacklist);
}
else {
	$message =  (isset($_REQUEST['message'])) ? $_REQUEST['message'] : '';
	
	echo '<form name="sms" onsubmit="send(this);" action="' . $_SERVER['PHP_SELF'] . '" method="post">
		<table>
			<tr><td>To</td><td>++' . $mobilenumber . '</td></tr>
			<tr><td>Message</td><td><textarea onfocus="update_length(this);" onkeyup="update_length(this);" name="message" cols="40" rows="5">' . $message . '</textarea></td></tr>
			<tr><td>Length</td><td><span id="length">' . strlen($message) . '</span> (left: <span id="left" style="color: green;">' . (160 - strlen($message)) . '</span>)</td></tr>
		</table>
		<input type="hidden" name="antispam" />
		<input type="submit" value="send" />
	</form>';
}

function format_duration($time) {
	if ($time < 60) {
		return $time . ' seconds';
	}
	elseif ($time < 3600) {
		return floor($time/60) . ' minutes';
	}
	else {
		return floor($time/3600) . ':' . floor(($time%3600)/60) . ' hours';
	}
}

?>
		</div>
	</body>
</html>
