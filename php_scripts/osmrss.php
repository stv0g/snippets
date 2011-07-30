<?php

header ('Content-Type: application/rss+xml; charset=UTF-8');

// urls
$apiUrl = 'http://api.openstreetmap.org/api/0.6';
$historyUrl = 'http://openstreetmap.org/history';
$browseUrl = 'http://openstreetmap.org/browse/changeset/';
$options = $_SERVER['QUERY_STRING'];
$bots = array('bot', 'xylome', 'thomas1904');
$filters = explode(',', $_GET['filter']);

// set tz
date_default_timezone_set('UTC');

// load changesets from osm api
$ch = curl_init($apiUrl . '/changesets?' . $options);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
$content = curl_exec($ch);
curl_close($ch);

// parse changesets
$xml = new DOMDocument();
$xml->loadXML($content);

// initialize rss feed
$rss = new DOMDocument('1.0', 'UTF-8');
$rss->formatOutput = true;

$docEl = $rss->createElement('rss');
$docEl->setAttribute('version', '2.0');
$rss->appendChild($docEl);

$channel = $rss->createElement('channel');
$docEl->appendChild($channel);

$channel->appendChild($rss->createElement('title', 'OSM Changeset Newsfeed'));
$channel->appendChild($rss->createElement('description', 'Keep up to date in your area!'));
$channel->appendChild($rss->createElement('link', $historyUrl . '?' . htmlspecialchars($options)));

// generate rss feed
$changesets = $xml->getElementsByTagName('changeset');
foreach ($changesets as $changeset) {
	$add = true;
	if (in_array('bots', $filters)) {
		foreach ($bots as $bot) {
			if (strpos($changeset->getAttribute('user'), $bot) !== false) {
				$add = false;
			}
		}
	}
		
	if ($add) {
		$item = $rss->createElement('item');

		unset($tag);
		foreach ($changeset->childNodes as $child) {
			if (get_class($child) == 'DOMElement') {
				$tag[$child->getAttribute('k')] = htmlspecialchars($child->getAttribute('v'));
			}
		}

		$ts = strtotime(($changeset->getAttribute('closed_at')) ? $changeset->getAttribute('closed_at') : $changeset->getAttribute('created_at'));
		$date = date('D, d M Y H:i:s', $ts);

		$item->appendChild($rss->createElement('title', (($changeset->getAttribute('open') == 'true') ? '[Editing] ' : '') . $changeset->getAttribute('user') . ((@$tag['comment']) ? ': ' . @$tag['comment'] : '') . (($tag['created_by']) ? ': ' . $tag['created_by'] : '')));
		$item->appendChild($rss->createElement('link', $browseUrl . $changeset->getAttribute('id')));
		$item->appendChild($rss->createElement('guid', $apiUrl . '/changeset/' . $changeset->getAttribute('id')));
		$item->appendChild($rss->createElement('pubDate', $date));

		$channel->appendChild($item);
	}
}

echo $rss->saveXML();

?>
