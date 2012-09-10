<?php

require_once 'config.php';
require_once 'xmlrpc/xmlrpc.inc';
require_once 'sipgateAPI.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
	$headers = getallheaders();
	$body = file_get_contents('php://input');
	$json = json_decode($body, true);

	file_put_contents('aws.log', print_r($headers, true) . "\r\n", FILE_APPEND);
	file_put_contents('aws.log', print_r($body, true) . "\r\n", FILE_APPEND);
	file_put_contents('aws.log', print_r($json, true) . "\r\n", FILE_APPEND);

	switch ($headers['x-amz-sns-message-type']) {
		case 'SubscriptionConfirmation':
			fopen($json['SubscribeURL'], 'r');
			break;

		case 'Notification':
			$sipgate   = new sipgateAPI($config['username'], $config['password']);
			$balance   = $sipgate->getBalance();
			$message   = preg_replace('/\r?\n/m', '\n', trim($json['Message']));

			if ($balance < $config['reserve']) {
				header("HTTP/1.0 402 Payment Required");
				die();
			}

			$sipgate->sendSMS($config['recipient'], $message, NULL, $config['recipient']);
			break;

		default:
			header("HTTP/1.1 501 Not Implemented");
	}
}
else {
	header("HTTP/1.1 405 Method Not Allowed");
}

?>
