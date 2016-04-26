<?php

class LinkInfo {
	protected $info;
	protected $state = -1;	// 0 => initialized, 1 => fetched, 2 => parsed

	protected $ch;
	protected $doc;

	protected $metaAttributes = array('author', 'description', 'keywords', 'date', 'generator');
	protected $otherTagNames = array('h1', 'h2', 'h3');

	protected $ua = 'Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3';

	public function __construct($url) {
		$this->info['originalUrl'] = $url;
	}

	public function __get($member) {
		if ($this->state < 2) {
			$this->parse();
		}
		return $this->info[$member];
	}

	public function __isset($member) {
		return isset($this->info[$member]);
	}

	public function get() {
		if ($this->state < 2) {
			$this->parse();
		}
		return $this->info;
	}

	protected function init() {
		if (!empty($this->info['originalUrl'])) {	// TODO: implement url regex checks
			$this->ch = curl_init();
			curl_setopt($this->ch, CURLOPT_URL, $this->info['originalUrl']);
			curl_setopt($this->ch, CURLOPT_HEADER, false);
			curl_setopt($this->ch, CURLOPT_CONNECTTIMEOUT, 1);
			curl_setopt($this->ch, CURLOPT_FOLLOWLOCATION, true);
			curl_setopt($this->ch, CURLOPT_RETURNTRANSFER, true);
			curl_setopt($this->ch, CURLINFO_HEADER_OUT, true);
			curl_setopt($this->ch, CURLOPT_USERAGENT, $this->ua);
			echo 'request: ' . $this->info['originalUrl'] . '<br />';

			$this->state = 0;
		}
		else {
			throw new Exception('LinkInfo: invalid url: ' . $this->info['originalUrl']);
		}
	}

	public function fetch() {
		if ($this->state < 0) {
			$this->init();
		}

		$html = curl_exec($this->ch);
		if (!$html) {
			throw new Exception(curl_error($this->ch));
		}

		$contentType = curl_getinfo($this->ch, CURLINFO_CONTENT_TYPE);

		preg_match( '=^([\w/+-]+)(;\s+charset\=(\S+))?=i', $contentType, $matches );
		if ( isset( $matches[1] ) )
			$this->info['mime'] = $matches[1];
		if ( isset( $matches[3] ) )
			$this->info['charset'] = strtoupper($matches[3]);

		$this->info['effectiveUrl'] = curl_getinfo($this->ch, CURLINFO_EFFECTIVE_URL);
		$this->info['effectiveUrlParsed'] = parse_url($this->info['effectiveUrl']);

		$this->doc = new DOMDocument();
		@$this->doc->loadHTML($html);
		curl_close($this->ch);

		$this->state = 1;
	}

	public function parse() {
		if ($this->state < 1) {
			$this->fetch();
		}

		$head = $this->doc->getElementsByTagName('head')->item(0);
		$body = $this->doc->getElementsByTagName('body')->item(0);

		// title & base
		$this->info['title'] = $this->escapeTagValue($head->getElementsByTagName('title')->item(0)->nodeValue);

		if ($head->getElementsByTagName('base')->length > 0) {
			$this->info['baseUrl'] = $head->getElementsByTagName('base')->item(0)->getAttribute('href');
			$this->info['baseUrlParsed'] = parse_url($this->info['baseUrl']);
		}

		// other tags
		foreach ($this->otherTagNames as $tn) {
			$this->info[$tn] = array();

			foreach ($body->getElementsByTagName($tn) as $t) {
				$this->info[$tn][] = $this->escapeTagValue($t->nodeValue);
			}
		}

		// meta tags
		$metaTags = $head->getElementsByTagName('meta');
		foreach ($metaTags as $mt) {
			if (in_array($mt->getAttribute('name'), $this->metaAttributes)) {
				$this->info[$mt->getAttribute('name')] = $mt->getAttribute('content');
			}
		}

		// keywords
		$this->info['keywordsSeperated'] = explode(',', $this->info['keywords']);
		$this->info['keywordsSeperated'] = array_map('trim', $this->info['keywordsSeperated']);
		$this->info['keywordsSeperated'] = array_filter($this->info['keywordsSeperated']);

		// favicon
		foreach ($head->getElementsByTagName('link') as $link) {
			if (in_array($link->getAttribute('rel'), array('shortcut icon', 'icon')))
				$ico = $link->getAttribute('href');
		}

		if (!isset($ico)) {
			$ch = curl_init();
			curl_setopt($ch, CURLOPT_URL, $this->info['effectiveUrlParsed']['scheme'] . '://' . $this->info['effectiveUrlParsed']['host'] . '/favicon.ico');
			curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
			curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
			curl_setopt($ch, CURLOPT_USERAGENT, $this->ua);
			curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 1);
			echo 'request: ' . $this->info['effectiveUrlParsed']['scheme'] . '://' . $this->info['effectiveUrlParsed']['host'] . '/favicon.ico' . '<br />';

			try {
				if (curl_exec($ch)) {
					if (curl_getinfo($ch, CURLINFO_SIZE_DOWNLOAD) > 0 && preg_match('=^image/=', curl_getinfo($ch, CURLINFO_CONTENT_TYPE))) {
						$ico = curl_getinfo($ch, CURLINFO_EFFECTIVE_URL);
					}
					curl_close($ch);
				}
			} catch (Exception $e) { };
		}

		if (isset($ico)) {
			$this->info['favicon'] = $this->toAbsoluteUrl(parse_url($ico), $this->info['effectiveUrlParsed'], $this->info['baseUrlParsed']);
		}

		// images from html code
		$images = array();
		foreach ($body->getElementsByTagName('img') as $img) {
			$images[] = $img->getAttribute('src');
		}

		// site specific images
		if (preg_match('=youtube\.com/watch\?v\=([a-zA-Z0-9]+)=', $this->info['effectiveUrl'], $matches)) {
			$images[] = 'http://img.youtube.com/vi/' . $matches[1] . '/0.jpg';
		}

		array_unique($images);

		$this->info['images'] = array();
		foreach ($images as $n => $img) {
			$url = $this->toAbsoluteUrl(parse_url($img), $this->info['effectiveUrlParsed'], $this->info['baseUrlParsed']);
			echo $url . '<br />';
			$size = getimagesize($url);

			if ($size)
				$this->info['images'][] = array('url' => $url, 'size' => $size);
		}

		array_filter($this->info['images'], function($image) {
			return	$image['size'][0] * $image['size'][1] > 3500 &&
					in_array($image['size'][2], array(IMAGETYPE_GIF, IMAGETYPE_JPEG, IMAGETYPE_PNG, IMAGETYPE_BMP, IMAGETYPE_TIFF_II, IMAGETYPE_TIFF_MM));
		});

		usort($this->info['images'], function($a, $b) {
			$a = $a['size'][0] * $a['size'][1];
			$b = $b['size'][0] * $b['size'][1];

			return $b - $a;
		});

		$this->state = 2;
	}

	protected function escapeTagValue($value) {
		$value = mb_convert_encoding($value, 'UTF-8', array($this->info['charset'] , 'auto'));
		$value = strip_tags($value);
		$value = preg_replace('=(\s){2,}=', ' ', $value);
		$value = trim($value);
		$value = html_entity_decode($value, ENT_COMPAT);

		return $value;
	}

	protected function toAbsoluteUrl($url, $effectiveUrl, $baseUrl = NULL) {
		if (empty($url['scheme'])) {								// missing scheme
			if ($url['path'][0] == '/' && empty($url['host'])) {	// absolute
				$absUrl = $effectiveUrl['scheme'] . '://' . $effectiveUrl['host'];
			}
			else {										// relative
				if (isset($baseUrl)) {
					$absUrl = $baseUrl['scheme'] . '://' . $baseUrl['host'] . $baseUrl['path'];
				}
				else {
					$absUrl = $effectiveUrl['scheme'] . '://' . $effectiveUrl['host'] . $effectiveUrl['path'] . '/';
				}
			}
		}
		else {
			$absUrl = $url['scheme'] . '://' . $url['host'];
		}

		$absUrl .= $url['path'];

		if (!empty($url['query']))
			$absUrl .= '?' . $url['query'];

		if (!empty($url['fragment']))
			$absUrl .= '#' . $url['fragment'];

		return $absUrl;
	}
}

?>
