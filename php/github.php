<?php
/**
 * Github migration script
 *
 * @author Steffen Vogel <post@steffenvogel.de>
 * @copyright 2021, Steffen Vogel
 * @license http://opensource.org/licenses/gpl-license.php GNU Public License
 */

// Configuration
$rootDir = getcwd();
$exclude = array('volkszaehler.git');

$ghUser = 'yourusername';
$ghPassword = 'yourpassword';

$files = scandir($rootDir);

if (!isset($_ENV['TERM'])) {
	die('This script is intended to be used from the command line!');
}

if (file_exists('gitweb.projects')) {
	$public = file('gitweb.projects', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
}
else {
	$public = array();
}

$ch = curl_init();

curl_setopt($ch, CURLOPT_URL, 'https://api.github.com/user/repos');
curl_setopt($ch, CURLOPT_USERPWD, $ghUser . ':' . $ghPassword);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);

foreach ($files as $dir) {
	if (is_dir($dir) && !in_array($dir, $exclude) && substr($dir, -4) == '.git') {
		chdir($dir);

		$repoTitle = substr($dir, 0, -4);
		$repoDesc = file_get_contents('description');

		echo 'Creating repo: ' . $repoTitle . PHP_EOL;

		$request = array(
			'name' => $repoTitle,
			'description' => $repoDesc,
			'public' => in_array($dir, $public) || count($public) == 0,
			'has_issues' => false,
			'has_wiki' => false
		);

		curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($request));

		$response = json_decode(curl_exec($ch), true);
		print_r($response);

		passthru('git remote add github ' . $response['ssh_url']);
		passthru('git push --all github');

		chdir($rootDir);

		//break; // for debugging
	}
}

curl_close($ch);

?>
