<?php
header('Content-Type: image/png');
putenv('GDFONTPATH=' . realpath('.'));
$img = imagecreate((int) 4 * $_GET['imgsize'], (int) 3 * $_GET['imgsize']);
$bg_col = imagecolorallocate($img, 255, 255, 255 );
$text_col = imagecolorallocate($img, 0, 0, 0);
imagettftext($img, (int) $_GET['fontsize'], (int) $_GET['angle'], (int) $_GET['x'], (int) $_GET['y'], $text_col, (int) $_GET['font'] . '.ttf', $_GET['text']);
imagepng($img);
imagedestroy($img);
?>