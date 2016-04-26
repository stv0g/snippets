<?php
set_time_limit(1800);

// Bootstrap Drupal
require 'includes/bootstrap.inc';
drupal_bootstrap(DRUPAL_BOOTSTRAP_FULL);

// Construct the new node object.
$node = new stdClass();


$link = mysql_connect('localhost', 'user', 'password');
mysql_select_db('database', $link);
$result = mysql_query('SELECT * FROM import_nodes', $link) OR die(mysql_error());

echo "Starting... Process:<br />";
flush();
$i = 0;

while ($row = mysql_fetch_assoc($result)) {

  // Your script will probably pull this information from a database.
  $node->title = mb_convert_encoding ( html_entity_decode($row['short']), "UTF-8", "ISO-8859-1" ); #"My imported node";
  $node->body = $row['text'];
  $node->teaser = substr(strip_tags($node->body),0,600);
  $node->type = 'story';   // Your specified content type
  $node->created = $row['created']; #time();
  $node->changed = $node->created;
  $node->status = 1;
  $node->promote = 1;
  $node->sticky = 0;
  $node->format = 1;       // Filtered HTML
  $node->uid = 1;          // UID of content owner
  $node->language = 'de';
  // If known, the taxonomy TID values can be added as an array.
  $node->taxonomy = array($row['tid']);
  
  node_save($node);
  $i++;
  # echo $node->title;
  unset($node);
  $node = new stdClass();
  
  if ($i % 100 === 0) { echo $i . ".."; flush(); }

}

echo "<br /><br />done";
?>

