<?php

if ($_POST) {
	if ($_POST['router_addr'] and $_POST['mac_addr'] and $_POST['port']) {
		if ($fp = fsockopen($_POST['router_addr'], $_POST['port'], $errno, $errstr, 4)) {
			//erlaubte Zeichen:
			$hexchars = array("0","1","2","3","4","5","6","7","8","9",
				"A","B","C","D","E","F",
				"a","b","c","d","e","f"
			);

			// 6 "volle" bytes (Also mit Wert 255 bzw. FF in hexadezimal)
			$data = "\xFF\xFF\xFF\xFF\xFF\xFF";
			$hexmac = "";

			// Jetzt werden unnütige zeichen in der mac-adresse
			// entfernt (also z.B. die bindestriche usw.)
			for ($i = 0; $i < strlen($_REQUEST['mac_addr']); $i++) {
				if (!in_array(substr($_REQUEST['mac_addr'], $i, 1), $hexchars)) {
					$_REQUEST['mac_addr'] = str_replace(substr($_REQUEST['mac_addr'], $i, 1), "", $_REQUEST['mac_addr']);
				}
			}

			for ($i = 0; $i < 12; $i += 2) {
				$hexmac .= chr(hexdec(substr($_REQUEST['mac_addr'], $i, 2)));
			}

			// Hexadresse wird 16mal hintereinandergeschrieben
			for ($i = 0; $i < 16; $i++) {
				$data .= $hexmac;
			}

			fputs($fp, $data);
			fclose($fp);
		}
	}
	else {
		die('Bitte geben Sie Daten ein!');
	}
}
else {

?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de">
    <head>
        <title>WOL PHP Skript</title>
        <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
    </head>
    <body>
<form name="WOL" method="post" action="<?php print $_SERVER['PHP_SELF']; ?>">
<table>
	<tr><td>IP oder FQHN:</td><td><input type="text" name="router_addr" size="30"></td></tr>
	<tr><td>MAC-Adresse:</td><td><input type="text" name="mac_addr" size="30" maxlength="17"></td></tr>
	<tr><td>Port:</td><td><input type="text" name="port" size="30" maxlength="5"></td></tr>
	<tr><td><input type="submit" name="Abschicken" value="Aufwecken"></td></tr>
</table>
</form>
</body>

<?php
}
?>
