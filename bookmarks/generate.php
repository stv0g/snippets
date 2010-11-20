<?php

echo '<table>';
$row = 1;
$handle = fopen("bookmarks.csv", "r");
while (($data = fgetcsv($handle, 300, ";")) !== FALSE) {
	echo '<tr><td style="border-bottom: 1px solid grey;">' . $row++ . '</td><td style="border-bottom: 1px solid grey;">' . (($data[2] != '') ? '<img style="height: 16px; width: 16px;" src="' . $data[2] . '" alt="" />' : '&nbsp;') . '</td><td style="border-bottom: 1px solid grey;"><a href="' . $data[1] . '">' . $data[3] . '</a></td></tr>' . "\n";
}
fclose($handle);

echo '</table>';

?>
