<?php
error_reporting(E_ALL ^ E_NOTICE);
header('Content-type: text/html; charset=UTF-8');
?>
<html>
	<head>
		<style type="text/css">
			body {
				font-family: "lucida grande", tahoma, verdana, arial, sans-serif;
				font-size: 11px;
			}

			a  {
				color: #3B5998;
				text-decoration: none;
			}

			a img {
				border: 0;
			}

			.link {
				padding: 5px;
			}

			.link-container {
				width: 450px;
			}

			.link-title {
				font-weight: bold;
			}

			.link + hr {
				border: 1px solid #606060;
				clear: both;
			}

			.link-icon {
				height: 16px;
				width: 16px;
				margin: 0 4px -3px 0;
			}

			.link > a > img {
				max-height: 250px;
				max-width: 120px;
				float: left;
				margin-right: 10px;
				margin-bottom: 5px;
			}

			.link > div {
				line-height: 14px;
				color: #808080;
			}

			.link-keywords > span {
				color: black;
			}
		</style>
		<title>LinkPreview Test</title>
	</head>
	<body>
		<h1>Link Preview Test</h1>
		<div class="link-container">
<?php

function limit($text, $chars = 400, $whitespace = ' ') {
	$arr = explode($whitespace, $text);

	while (strlen($limited) < $chars)
		$limited .= array_shift($arr) . ' ';

	if (strlen($text) > strlen($limited))
		$limited .= '...';

	return $limited;
}

include 'linkinfo.php';

$urls = array(
		'http://google.de',
		'http://de.wikipedia.org/wiki/Favicon',
		'http://code.google.com/p/kaytwo-i18n/source/browse/trunk/de_DE/de_DE.po',
		'http://katalyse.de/dokuwiki/doku.php?id=edv:passwoerter',
		'http://katalyse.de/',
		'http://www.youtube.com/watch?v=Ioz4lq2lS0E',
		'http://de.selfhtml.org/css/formate/zentrale.htm',
		'http://www.reichelt.de',
		'http://de2.php.net/manual/en/function.str-split.php',
		'http://www.umweltlexikon-online.de/fp/archiv/RUBernaehrunglebensmittel/Brocaindex.php',
		'http://cfranke.com'
);

foreach ($urls as $url) {
	$li = new LinkInfo($url);

	echo '<div class="link">';

	if (!empty($li->images[0]))
		echo '<a class="link-image" target="_blank" href="' . $li->effectiveUrl . '">
				<img src="' . $li->images[0]['url'] . '">
			</a>';

	echo '<div>
			<a class="link-title" target="_blank" href="' . $li->effectiveUrl . '">' . ((empty($li->title)) ? $li->effectiveUrl :  $li->title) . '</a><br />
			<a class="link-domain" target="_blank" href="' . $li->effectiveUrlParsed['scheme'] . '://' . $li->effectiveUrlParsed['host'] . '">';

	if (!empty($li->favicon))
		echo '<img class="link-icon" src="' . $li->favicon . '" />';

	echo $li->effectiveUrlParsed['host'] . '
			</a>
		</div>';

	if (!empty($li->description))
		echo '<div class="link-description">
			' . limit($li->description) . '
		</div>';

	if (!empty($li->keywordsSeperated))
		echo '<div class="link-keywords"><span>Keywords: </span>' . implode(', ', array_slice($li->keywordsSeperated, 0, 10)) . '</div>';

echo '</div>
<hr />';

//echo '<pre>'; print_r($li); echo '</pre>';

}

?>
		</div>
	</body>
</html>

