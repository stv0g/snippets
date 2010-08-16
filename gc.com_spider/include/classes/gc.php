<?php
class GC {
	
	private $login_url = 'http://www.geocaching.com/login/default.aspx?RESET=Y&redir=http%3a%2f%2fwww.geocaching.com%2fmap%2fdefault.aspx';
	private $url = 'http://www.geocaching.com/map/default.aspx';
	private $agent = 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4) Gecko/20030624 Netscape/7.1 (ax)';
	private $reffer = 'http://www.geocaching.com/map/default.aspx';
	private $cookies = 'cookie.txt';
	private $request_header = array('delta: true',
									'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
									'Accept-Language: de-de,de;q=0.8,en-us;q=0.5,en;q=0.3',
									'Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7',
									'Accept-Encoding: gzip,deflate',
									'Keep-Alive: 300',
									'Connection: keep-alive',
									'Cache-Control: no-cache',
									'Content-Type: application/x-www-form-urlencoded; charset=UTF-8');
	private $user; // TODO implement login
	private $pw;
	
	public $viewstate;
	
	function __construct($user, $pw) {
		$fp = fopen($this->cookies, "w") or die("Unable to open cookie file for write!");
		fclose($fp);
		
		$this->user = $user;
		$this->pw = $pw;
				
		$this->viewstate = $this->login();

		echo $this->viewstate;
		
		//$this->viewstate = $this->getViewstate();

		//echo $this->viewstate;
	}
	
	function getValue($token, $doc) {
		return $doc->getElementById($token)->getAttribute('value');
	}
	
	function login() {
		$post  = 'Button1=Login';
		$post .= '&__VIEWSTATE=' . urlencode($this->viewstate);
		$post .= '&myUsername=' . $this->user;
		$post .= '&myPassword=' . $this->pw;
		
		$ch = curl_init();
		curl_setopt($ch, CURLOPT_URL, $this->login_url);
		curl_setopt($ch, CURLOPT_AUTOREFERER, true);
		curl_setopt($ch, CURLOPT_FOLLOWLOCATION, 1);
		curl_setopt($ch, CURLOPT_USERAGENT, $this->agent);
		curl_setopt($ch, CURLOPT_HEADER, false);
		curl_setopt($ch, CURLOPT_POST, true);
		curl_setopt($ch, CURLOPT_POSTFIELDS, $post);
		curl_setopt($ch, CURLOPT_COOKIEJAR, $this->cookies);
		curl_setopt($ch, CURLOPT_COOKIEFILE, $this->cookies);
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
		curl_setopt($ch, CURLOPT_HTTPHEADER, $this->request_header);
		
		
		$result = curl_exec($ch);
		
		$doc = new DOMDocument();
		$doc->loadHTML($result);
		curl_close($ch);
		
		return $this->getValue('__VIEWSTATE', $doc);
	}
	
	function getViewstate() {
		$ch = curl_init();
		curl_setopt($ch, CURLOPT_URL, $this->url);
		curl_setopt($ch, CURLOPT_USERAGENT, $this->agent);
		curl_setopt($ch, CURLOPT_HEADER, false);
		curl_setopt($ch, CURLOPT_COOKIEFILE, $this->cookies);
		curl_setopt($ch, CURLOPT_COOKIEJAR, $this->cookies);
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
		curl_setopt($ch, CURLOPT_HTTPHEADER, $this->request_header);
		
		
		$result = curl_exec($ch);
		
		$doc = new DOMDocument();
		$doc->loadHTML($result);
		curl_close($ch);
		
		return $this->getValue('__VIEWSTATE', $doc);
	}
	
	function getData($bbox) {
		$post  = 'eo_cb_id=ctl00_ContentBody_cbAjax';
		$post .= '&eo_cb_param=' . rawurlencode('{"c": 1, "m": "", "d": "' . $bbox[3] . '|' . $bbox[1] . '|' . $bbox[2] . '|' . $bbox[0] . '"}');
		$post .= '&__eo_obj_states=';
		$post .= '&__VIEWSTATE=' . urlencode($this->viewstate);
		$post .= '&eo_version=5.0.51.2';
		$post .= '&=&=&=2&=3&=4&=5&=1858&=6&=8&=11&=137&=13&=453';
		$post .= '&__EVENTTARGET=';
		$post .= '&__EVENTARGUMENT=';
		$post .= '&__EVENTVALIDATION=';
		
		$ch = curl_init();
		curl_setopt($ch, CURLOPT_URL, $this->url);
		curl_setopt($ch, CURLOPT_USERAGENT, $this->agent);
		curl_setopt($ch, CURLOPT_POST, true);
		curl_setopt($ch, CURLOPT_POSTFIELDS, $post);
		curl_setopt($ch, CURLOPT_HEADER, false);
		curl_setopt($ch, CURLOPT_COOKIEJAR, $this->cookies);
		curl_setopt($ch, CURLOPT_COOKIEFILE, $this->cookies);
		curl_setopt($ch, CURLOPT_REFERER, $this->reffer);
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
		curl_setopt($ch, CURLOPT_HTTPHEADER, $this->request_header);
		
		$result = curl_exec($ch);
		curl_close($ch);
		
		// sample data
		//$result = '<Data><Output><![CDATA[<!--dummy-->]]></Output><ViewState><![CDATA[/wEPDwULLTIxMTYyMzE0NDkPZBYCZg9kFgICAw9kFghmDxYCHgRUZXh0BRZZb3UgYXJlIG5vdCBsb2dnZWQgaW4uZAIBDw8WBB4LTmF2aWdhdGVVcmwFb2h0dHA6Ly93d3cuZ2VvY2FjaGluZy5jb20vbG9naW4vZGVmYXVsdC5hc3B4P1JFU0VUPVkmcmVkaXI9aHR0cCUzYSUyZiUyZnd3dy5nZW9jYWNoaW5nLmNvbSUyZm1hcCUyZmRlZmF1bHQuYXNweB8ABQZMb2cgaW5kZAIED2QWAgIBDw9kD2QFDERRSUJBQUFBQUFBPWQCDw8WAh8ABQQyMDA4ZGSgx1xB1qwBoBnjdbXkBE9V7+VXRw==]]></ViewState><EventValidation><![CDATA[]]></EventValidation><CultureCodeI><![CDATA[eo_culture_i=null;]]></CultureCodeI><CultureCode><![CDATA[eo_culture=null;]]></CultureCode><ExtraData><![CDATA[{"cs": {"li": false, "dist": 2.5261767481458, "pm": false, "count": 24, "c": 1, "et": 0.00268798219538193, "cc": [{"lat": 47.680333, "id": 144506, "lon": -122.328333, "gc": "GCJM5D", "ctid": 3, "f": false, "o": false, "ia": true, "nn": "Crossing Green Lake"}, {"lat": 47.66885, "id": 181187, "lon": -122.333083, "gc": "GCKWAN", "ctid": 2, "f": false, "o": false, "ia": false, "nn": "Coffee House Hotspot"}, {"lat": 47.666667, "id": 186020, "lon": -122.325, "gc": "GCM1BJ", "ctid": 8, "f": false, "o": false, "ia": true, "nn": "Small Town Connection"}, {"lat": 47.668133, "id": 186526, "lon": -122.3263, "gc": "GCM1WX", "ctid": 2, "f": false, "o": false, "ia": true, "nn": "Upper Wallingford Play"}, {"lat": 47.666617, "id": 242963, "lon": -122.3477, "gc": "GCNYKE", "ctid": 2, "f": false, "o": false, "ia": true, "nn": "Totally Tubular II"}, {"lat": 47.683333, "id": 285372, "lon": -122.35, "gc": "GCQBQF", "ctid": 8, "f": false, "o": false, "ia": true, "nn": "Seattle Sudoku"}, {"lat": 47.671417, "id": 304669, "lon": -122.346633, "gc": "GCR0TZ", "ctid": 3, "f": false, "o": false, "ia": true, "nn": "Totally Tubular V"}, {"lat": 47.677783, "id": 331269, "lon": -122.35465, "gc": "GCRXG1", "ctid": 2, "f": false, "o": false, "ia": true, "nn": "EEOC"}, {"lat": 47.67875, "id": 336099, "lon": -122.345267, "gc": "GCT2GV", "ctid": 2, "f": false, "o": false, "ia": true, "nn": "Frederick"}, {"lat": 47.672883, "id": 338198, "lon": -122.337583, "gc": "GCT4PH", "ctid": 3, "f": false, "o": false, "ia": true, "nn": "Trees of Greenlake: Tremuloides"}, {"lat": 47.671367, "id": 338702, "lon": -122.3431, "gc": "GCT57T", "ctid": 3, "f": false, "o": false, "ia": true, "nn": "Trees of Greenlake: Atlantica"}, {"lat": 47.6744, "id": 343930, "lon": -122.335317, "gc": "GCTANE", "ctid": 3, "f": false, "o": false, "ia": true, "nn": "Trees of Greenlake: The Empress"}, {"lat": 47.670583, "id": 346015, "lon": -122.3532, "gc": "GCTCVP", "ctid": 2, "f": false, "o": false, "ia": true, "nn": "I can smell zoo!"}, {"lat": 47.680833, "id": 354084, "lon": -122.345833, "gc": "GCTN80", "ctid": 8, "f": false, "o": false, "ia": true, "nn": "Pennies From Heaven"}, {"lat": 47.675, "id": 377231, "lon": -122.341667, "gc": "GCVEAN", "ctid": 8, "f": false, "o": false, "ia": true, "nn": "Bottom of Green Lake"}, {"lat": 47.683333, "id": 458813, "lon": -122.35, "gc": "GCY67B", "ctid": 8, "f": false, "o": false, "ia": true, "nn": "Silly Sally"}, {"lat": 47.672983, "id": 572744, "lon": -122.32205, "gc": "GC120RH", "ctid": 2, "f": false, "o": false, "ia": true, "nn": "Ceci n\'est pas un parc"}, {"lat": 47.67745, "id": 656596, "lon": -122.332333, "gc": "GC14V1E", "ctid": 2, "f": false, "o": false, "ia": true, "nn": "Green Lake Grove"}, {"lat": 47.666667, "id": 675819, "lon": -122.333333, "gc": "GC15F1H", "ctid": 8, "f": false, "o": false, "ia": true, "nn": "Google This!"}, {"lat": 47.66926, "id": 696765, "lon": -122.35699, "gc": "GC165V7", "ctid": 2, "f": false, "o": false, "ia": true, "nn": "Cornered"}, {"lat": 47.669, "id": 741527, "lon": -122.354033, "gc": "GC17ND5", "ctid": 8, "f": false, "o": false, "ia": true, "nn": "Z00-Logical Park"}, {"lat": 47.66765, "id": 751673, "lon": -122.343583, "gc": "GC180ZE", "ctid": 2, "f": false, "o": false, "ia": true, "nn": "Woodland Park Cheez"}, {"lat": 47.670483, "id": 784515, "lon": -122.333983, "gc": "GC1944W", "ctid": 2, "f": false, "o": false, "ia": true, "nn": "Triangle Park 2"}, {"lat": 47.6756, "id": 887921, "lon": -122.3542, "gc": "GC1CJQH", "ctid": 2, "f": false, "o": false, "ia": true, "nn": "The Red Bench"}]}}]]></ExtraData></Data>';

		$xml = new SimpleXMLElement($result);
		$json = $xml->ExtraData;

		if(function_exists('json_decode'))
			return json_decode($json, true);
		else
			return NULL;
	}
}

?>