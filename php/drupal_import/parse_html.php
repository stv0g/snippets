<?php

$db = mysql_connect('localhost', 'user', 'password');
mysql_select_db('database', $db);

$html = file_get_contents($argv[1]);

$pattern = '/^.*<!-- news id=page\.news\.([\w]*)\.([\d]{4})([\d]{2})([\d]{2})[\d]* date=.* Uhr.*<p class="newsShort".*>(.*)<\/p>.*<p class="newsLong".*>(.*)<\/p>.*<p class="text">(.*)<\/p>.*<br \/>.*<a href="javascript:history.back\(\);".*$/siU';

if(preg_match($pattern, $html, $matches)) {

	$time = strtotime($matches[2] . '-' . $matches[3] . '-' . $matches[4]);

	for ($i = 1; $i <= 5; $i++) {
		echo trim($matches[$i]) . " ";
	}

	echo $time;
	echo "\n";


	switch (trim($matches[1])) {
		case 'brasil':
			$tid = 2;
			break;
		case 'intern':
			$tid = 1;
			break;
		case 'latein':
			$tid = 3;
			break;
		case 'tropen':
			$tid = 4;
			break;
		case 'allg':
			$tid = 5;
			break;
		default:
			$tid = 0;
	}

	$tidy_config = array(
		'clean'						=> true,
		'drop-proprietary-atrributes'			=> true,
		'output-xhtml'					=> true,
		'indent'					=> true,
		'show-body-only'				=> true);
	$tidy = new tidy();
	$tidy->parseString($matches[7], $tidy_config);
	$tidy->cleanRepair();


	mysql_query('INSERT INTO import_nodes SET
					tid = ' . $tid . ',
					uid = 1,
					created = ' . $time . ',
					short = \'' . mysql_real_escape_string(trim($matches[5])) . '\',
					text = \'' . mysql_real_escape_string($tidy) . '\'', $db);

	echo mysql_error();

}
else {
	echo 'error occured!';
}
?>
