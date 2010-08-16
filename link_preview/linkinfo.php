<?php

class LinkInfo {
	private $info;
	private $state = -1;	// 0 => initialized
							// 1 => fetched
							// 2 => parsed
					
	private $ch;
	private $doc;
	
	private $metaAttributes = array('author', 'description', 'keywords', 'date', 'generator');
	private $otherTagNames = array('h1', 'h2', 'h3');
	
	private $ua = 'Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3';
	
	function __construct($url) {
		$this->info['originalUrl'] = $url;
	}
	
	function __get($member) {
		if ($this->state < 2) {
			$this->parse();
		}
		
		return $this->info[$member];
	}
	
	function __isset($member) {
		return isset($this->info[$member]);
	}
	
	function get() {
		if ($this->state < 2) {
			$this->parse();
		}
		
		return $this->info;
	}
	
	private function init() {
		if (!empty($this->info['originalUrl'])) {	// TODO: implement url regex checks
			$this->ch = curl_init();
			curl_setopt($this->ch, CURLOPT_URL, $this->info['originalUrl']);
			curl_setopt($this->ch, CURLOPT_HEADER, false);
			curl_setopt($this->ch, CURLOPT_FOLLOWLOCATION, true);
			curl_setopt($this->ch, CURLOPT_RETURNTRANSFER, true);
			curl_setopt($this->ch, CURLINFO_HEADER_OUT, true);
			curl_setopt($this->ch, CURLOPT_USERAGENT, $this->ua);
		
			$this->state = 0;
		}
		else {
			die('cannot init linkinfo instance: invalid url');
		}
	}

	function fetch() {
		if ($this->state < 0) {
			$this->init();
		}
		
		$html = curl_exec($this->ch) or die(curl_error($this->ch));
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
	
	
	function parse() {
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
			
			foreach ($body->getElementsByTagName($tn) as $t)
				$this->info[$tn][] = $this->escapeTagValue($t->nodeValue);  
		}
		
		// meta tags
		$metaTags = $head->getElementsByTagName('meta');
		foreach ($metaTags as $mt) {
			if (in_array($mt->getAttribute('name'), $this->metaAttributes)) {
				$this->info[$mt->getAttribute('name')] = $mt->getAttribute('content');
			}
		}
		
		// keywords
		$this->info['keywordsSeperated'] = array();
		$this->info['keywordsSeperated'] = explode(',', $this->info['keywords']);
		$this->info['keywordsSeperated'] = array_map('trim', $this->info['keywordsSeperated']);
		$this->info['keywordsSeperated'] = array_filter($this->info['keywordsSeperated']);
		
		// favicon
		$ch = curl_init();
		curl_setopt($ch, CURLOPT_URL, $this->info['effectiveUrlParsed']['scheme'] . '://' . $this->info['effectiveUrlParsed']['host'] . '/favicon.ico');
		curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
		curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3');

		if (curl_exec($ch)) {
			if (curl_getinfo($ch, CURLINFO_SIZE_DOWNLOAD) > 0 && preg_match('=^image/=', curl_getinfo($ch, CURLINFO_CONTENT_TYPE)))
				$ico = '/favicon.ico';
			
			curl_close($ch);
		}
		
		foreach ($head->getElementsByTagName('link') as $link) {
			if (in_array($link->getAttribute('rel'), array('shortcut icon', 'icon')))
				$ico = $link->getAttribute('href');
		}
		
		if (isset($ico))
			$this->info['favicon'] = $this->toAbsoluteUrl(parse_url($ico), $this->info['effectiveUrlParsed'], $this->info['baseUrlParsed']);
		
		// images from html code
		$images = array();
		foreach ($body->getElementsByTagName('img') as $img) {
			$images[] = $img->getAttribute('src');
		}
		
		// site specific images
		if (preg_match('=youtube\.com/watch\?v\=([a-zA-Z0-9]+)=', $this->info['effectiveUrl'], $matches)) {
			$images[] = 'http://img.youtube.com/vi/' . $matches[1] . '/0.jpg';
		}
		
		$this->info['images'] = array();
		foreach ($images as $n => $img) {
			$url = $this->toAbsoluteUrl(parse_url($img), $this->info['effectiveUrlParsed'], $this->info['baseUrlParsed']);
			$size = getimagesize($url);
			
			if ($size)
				$this->info['images'][] = array('url' => $url, 'size' => $size);
		}
		
		array_unique($this->info['images']);
		
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
	
	private function escapeTagValue($value) {
		$value = mb_convert_encoding($value, 'UTF-8', array($this->info['charset'] , 'auto'));
		$value = strip_tags($value);
		$value = preg_replace('=(\s){2,}=', ' ', $value);
		$value = trim($value);
		$value = html_entity_decode($value, ENT_COMPAT);
	
		return $value;
	}
	
	private function toAbsoluteUrl($url, $effectiveUrl, $baseUrl = '') {
		if (empty($url['scheme'])) {													// missing scheme
			if ($url['path'][0] == '/' && empty($url['scheme']) && empty($url['host'])) {	// absolute
				$absUrl = $effectiveUrl['scheme'] . '://' . $effectiveUrl['host'];
			}
			else {																		// relative
				if (!empty($baseUrl)) {					
					if (!empty($baseUrl['scheme']) && !empty($baseUrl['host']))
						$u .= $baseUrl['scheme'] . '://' . $baseUrl['host'];
					
					$absUrl = $u . dirname($baseUrl['path']) . '/';
				}
				else
					$absUrl = $effectiveUrl['scheme'] . '://' . $effectiveUrl['host'] . dirname($effectiveUrl['path']) . '/';
			}
		}
		else {
			$absUrl = $url['scheme'] . '://' . $url['host'];
		}
		
		$absUrl .= pathinfo($url['path'], PATHINFO_DIRNAME) . '/';
		$absUrl .= rawurlencode(pathinfo($url['path'], PATHINFO_BASENAME));
		
		if (!empty($url['query']))
			$absUrl .= '?' . $url['query'];
		
		if (!empty($url['fragment']))
			$absUrl .= '#' . $url['fragment'];
		
		return $absUrl;
	}
}

?>
