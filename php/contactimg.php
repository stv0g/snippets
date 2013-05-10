<?php

function getExtension($filename) {
	return strtolower(substr(strrchr($filename,"."),1));
}

if (!empty($_FILES["contacts"])) {
	$count = count($_FILES["contacts"]["tmp_name"]);
	$files = array("zip" => array(),
			"vcf" => array(),
			"contact" => array());

	for($i = 0; $i < $count; $i++) {
		$extension = getExtension($_FILES["contacts"]["name"][$i]);

		if($extension == "zip")
			$files["zip"][] = $i;
		elseif($extension == "contact")
			$files["contact"] = $i;
		elseif($extension == "vcf")
			$files["vcf"][] = $i;
	}

	$contents["contact"] = array();
	$contents["vcf"] = array();

	foreach($files["contact"] as $contactfile) {
		$contents["contact"][] = file_get_contents($_FILES["contacts"]["tmp_name"][$contactfile]);
	}

	foreach($files["vcf"] as $contactfile) {
                $contents["vcf"][] = file_get_contents($_FILES["contacts"]["tmp_name"][$contactfile]);
        }


	foreach($files["zip"] as $zipfile) {
		$zip = new ZipArchive();
		$zip->open($_FILES["contacts"]["tmp_name"][$zipfile]);

		for ($i = 0; $i < $zip->numFiles; $i++) {
			$extension = getExtension($zip->getNameIndex($i));

	                if($extension == "contact")
        	                $contents["contact"][] = $zip->getFromIndex($i);
                	elseif($extension == "vcf")
                        	$contents["vcf"][] = $zip->getFromIndex($i);
		}

		$zip->close();
	}

	$images = array();

	foreach($contents["contact"] as $contact) {
		$image = array();
		$image["name"] = preg_replace('=.*?<c:FormattedName>(.*?)</c:FormattedName>.*=si',"\\1", $contact);
		$image["imgb64"] = preg_replace('=.*?<c:Value c:ContentType\="binary".*?>(.*?)</c:Value>.*=si',"\\1", $contact);

		$images[] = $image;
	}

	foreach($contents["vcf"] as $vcf) {
		preg_match_all('=FN:(.*?)\n=si', $vcf, $names);
		$count = preg_match_all('=PHOTO.*?:(.*?)\n[A-Z]=si', $vcf, $imgb64s);

		for ($i = 0; $i < $count; $i++) {
	                $images[] = array("name" => $names[1][$i], "imgb64" => $imgb64s[1][$i]);
		}
        }

?><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<html>
 <head>
  <title>Windows Contact to Image Converter</title>
 </head>
 <body onload="document.getElementsByName('base64finisher')[0].submit()">
<div id="content"> 
<h1>Windows Contact to Image Converter</h1>

<form action="b64img.php" method="post" name="base64finisher">
<p>Alright, we extracted the images from the files as base64. We now need to convert them to images.
If you do not have JavaScript, please click "Convert!" again.</p>

<?php
foreach ($images as $image) { ?>
	<textarea name="base64[]" style="display:none"><?php echo $image["imgb64"]; ?></textarea>
	<input name="names[]" type="text" style="display:none" value="<?php echo $image["name"]; ?>" />
<?php } ?>

<input name="convert" type="submit" value="Convert!" />
</div>
</form>
</body>
</html>

<?php

}
else
{

echo '<?xml version="1.0" ?>';
?>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
	<head>
		<title>/dev/nulll - Windows Contact to Image Converter</title>
		<script src="scripts.js" type="text/javascript"></script>
		<link rel="stylesheet" type="text/css" href="style.css">
		<meta http-equiv="content-type" content="text/html; charset=UTF-8">
		<link rel="shortcut icon" href="/favicon.png" type="image/png">

		<link rel="icon" href="/favicon.png" type="image/png">
	</head>
	<body><div id="content">

<header>
  <a href="http://dev.0l.de"><img src="http://dev.0l.de/_media/nulll_small.png" alt="0l" /></a>
  <h1>Windows Contact to Image Converter</h1>
</header>

<form action="<?php echo $_SERVER["PHP_SELF"]; ?>" name="base" method="post" target="ifr" enctype="multipart/form-data">
<p>You can either choose contact files or a zip file containing contact files.</p>

<div id="files">
<input type="file" name="contacts[]" id="focus" />
</div><br />
<a href="#" onclick="addUploader()">Add another upload field</a>
<br /><br />
<input name="convert" type="submit" value="Convert!" />
</form>

<iframe name="ifr" id="ifr"></iframe>

<footer>
  <p>by <a href="http://www.michaschwab.de">Micha Schwab</a> - <a href="http://dev.0l.de/tools/contactimg">help</a></p>

  <a href="#" onclick="document.getElementById('iPhoneExport').style.display='block'">You can also use this tool to get the contact photos you made with your iPhone</a>
<div id="iPhoneExport" style="display:none">
<p>In iTunes, define the contact sync setting so that it exports your contacts to the Windows contacts.
You will then find the .contact files somewhere in your profile files, ready to upload them here.</p>
 </footer>


</div>
</body>
</html>
<?php }
