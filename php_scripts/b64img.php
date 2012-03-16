<?php

class ImageCreateException extends Exception { }
class DecodeException extends Exception { }
class NoImagesException extends Exception
{
  protected $reasons = array();
  public function __construct ($reasons)
  {
    $this->reasons = $reasons;
  }
  public function getReasons()
  {
    return $this->reasons;
  }
}

if (!empty($_POST['base64']))
{
  $contents = array();
  $errors = array();
  $inputs = array();
  
  $count = count($_POST['base64']);
  
  for ($i = 0; $i < $count; $i++)
  {
    $inputs[$i] = array("base64" => $_POST['base64'][$i], "name" => $_POST['names'][$i]);
  }
  
  try
  {
    foreach($inputs as $input)
    {
      try
      {
        $img_decoded = base64_decode($input['base64']);
        
        if(empty($img_decoded))
        {
          throw new DecodeException("Could not get base64 string");
        }
        
        if (!@imagecreatefromstring($img_decoded))
        {
          throw new ImageCreateException();
        }

        $contents[] = array("decoded" => $img_decoded, "name" => $input["name"]);
      }
      catch (Exception $e)
      {
        $errors[] = $e;
      }
    }
    
    if(!empty($contents))
    {
      $count = count($contents);
      
      if($count == 1)
      {
        $im = imagecreatefromstring($contents[0]["decoded"]);
        
        header("Content-Type: image/png");
        header("Cache-Control: no-cache, must-revalidate");
        header("Expires: Sat, 26 Jul 1997 05:00:00 GMT");
        imagepng($im);
        
      }
      else
      {
        $file = tempnam("tmp", "zip");
        
        $zip = new ZipArchive();
        $zip->open($file, ZipArchive::OVERWRITE);
        
        for($i = 0; $i < $count; $i++)
        {
          $filename = empty($contents[$i]["name"]) ? "image_{$i}" : $contents[$i]["name"];
          $zip->addFromString($filename . ".png", $contents[$i]["decoded"]);
        }
        
        if(!empty($errors))
        {
          $errorstring = print_r($errors, true);
          
          $info  = "In total, " . count($errors) . " errors occurred:\r\n\r\n";
          
          $info .= "- " . substr_count($errorstring, "DecodeException") . " times, decoding the string didnt work\r\n";
          $info .= "- " . substr_count($errorstring, "ImageCreateException") . " times, creating the image didnt work";
          
          $zip->addFromString("errors.txt", $info);
        }
        
        $zip->close();
        
        header("Cache-Control: no-cache, must-revalidate");
        header("Expires: Sat, 26 Jul 1997 05:00:00 GMT");
        header("Content-Type: application/zip");
        header("Content-Length: " . filesize($file));
        header("Content-Disposition: attachment; filename=\"images.zip\"");
        readfile($file);

        unlink($file);
      }
    }
    else
    {
      throw new NoImagesException($errors);
    }
  }
  catch (DecodeException $e)
  {
    echo "Could not decode the given string.";
  }
  catch (ImageCreateException $e)
  {
    echo "Could not create an image from the decoded string. The base64 string is invalid or does not contain an image.";
  }
  catch (NoImagesException $e)
  {
    echo "No images found. The following errors occurred:";
    echo "<pre>" . print_r($e->getReasons(), true) . "</pre>";
  }
  catch (Exception $e)
  {
    print_r($e);
  }
}
else
{


echo '<?xml version="1.0" ?>';
?>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
	<title>/dev/nulll - Base 64 to Image Converter</title>
	<script src="scripts.js" type="text/javascript"></script>
	<link rel="stylesheet" type="text/css" href="style.css">
	<meta http-equiv="content-type" content="text/html; charset=UTF-8">
	<link rel="shortcut icon" href="/favicon.png" type="image/png">

	<link rel="icon" href="/favicon.png" type="image/png">
</head>
<body>
<div id="content">

<header>
  <a href="http://0l.de"><img src="http://0l.de/_media/nulll_small.png" alt="0l" /></a>
  <h1>Base 64 to Image Converter</h1>
</header>

<form action="<?php echo $_SERVER["PHP_SELF"]; ?>" method="post">

<div id="basestrings">
<textarea name="base64[]" rows="10" id="focus" style="width:100%"></textarea><br />Name (optional): <input name="names[]" type="text" size="30" />
</div><br />

<a href="#" onclick="addTextArea()">Add another input field</a>
<br /><br />

<input name="convert" type="submit" value="Convert!" />
</form>

<footer>
  <p>by <a href="http://www.michaschwab.de">Micha Schwab</a> - <a href="http://0l.de/tools/base64img">help</a></p>
 </footer>


</div>
</body>
</html>


<?php }
