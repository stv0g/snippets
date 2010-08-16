<?php

if ($_REQUEST['router_addr'] and $_REQUEST['mac_addr'] and $_REQUEST['port']) {
     if ($fp = fsockopen($_REQUEST['router_addr'], $_REQUEST['port'], $errno, $errstr, 4)) {
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
     return true;
     }
}
else {
	echo 'Bitte geben Sie Daten ein!';
}

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
IP oder FQHN: <input type="text" name="router_addr" size="30"><br>
MAC-Adresse: <input type="text" name="mac_addr" size="17" maxlength="17"><br>
Port: <input type="text" name="port" size="5" maxlength="5"><br>
<input type="submit" name="Abschicken" value="Aufwecken">
</form>
</body>
