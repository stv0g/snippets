<?php

function read_blacklist($time = 86400) {
	$blacklisted = array();
	$handle = fopen('blacklist.csv', 'r');
	while (($data = fgetcsv($handle, 100, "\t")) !== FALSE ) {
		if (count($data) == 2 && time() - $data[1] < $time) {
			$blacklisted[] = $data;
		}
	}
	fclose ($handle);
	
	return $blacklisted;
}

function is_blacklisted($blacklist, $ip) {
	foreach ($blacklist as $entry) {
		if ($entry[0] == $ip)
			return $entry[1];
	}
	return FALSE;
}

function write_blacklist($blacklist) {
	$handle = fopen('blacklist.csv', 'w');
	foreach($blacklist as $entry) {
		fputcsv($handle, $entry, "\t");
	}
	fclose ($handle);
}

?>
