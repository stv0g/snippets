<?php
/*
Plugin Name:  Facebook like Hyperlink Preview
Plugin URI:   http://0l.de/projects/wordpress/plugins/linkpreview
Description:  Place an overview of your post embedded links below your post
Version:      0.1
Author:       Steffen Vogel
Author URI:   https://www.steffenvogel.de
Author Mail:  post@steffenvogel.de
Copyright:    2021, Steffen Vogel
*/

/* Use the admin_menu action to define the custom boxes */
add_action('admin_menu', 'linkpreview_add_custom_box');

/* Use the save_post action to do something with the data entered */
add_action('save_post', 'linkpreview_save_postdata');

/* Adds a custom section to the "advanced" Post and Page edit screens */
function linkpreview_add_custom_box() {
	if( function_exists( 'add_meta_box' )) {
		add_meta_box( 'linkpreview_links', __('Link Summary', 'linkpreview'), 'linkpreview_inner_custom_box', 'post', 'advanced', 'high');
		add_meta_box( 'linkpreview_links', __('Link Summary', 'linkpreview'), 'linkpreview_inner_custom_box', 'page', 'advanced', 'high');
   }
}
   
/* Prints the inner fields for the custom post/page section */
function linkpreview_inner_custom_box() {
	global $post;
	
	// Use nonce for verification
	echo '<input type="hidden" name="linkpreview_noncename" id="linkpreview_noncename" value="' . 
	wp_create_nonce( plugin_basename(__FILE__) ) . '" />';
	
	$links = get_post_meta($post->ID, 'link');
	
	echo '<table>';

	echo '<tr><td><input type="text" name="linkpreview_links[]" /></td></tr>';
	
	foreach ($links as $link) {
		echo '<tr><td><input type="text" name="linkpreview_links[]" value="' . $link . '" /></td></tr>';	
	}
	
	echo '</table>';
}

/* When the post is saved, saves our custom data */
function linkpreview_save_postdata( $post_id ) {
  // verify this came from the our screen and with proper authorization,
  // because save_post can be triggered at other times
  if ( !wp_verify_nonce( $_POST['linkpreview_noncename'], plugin_basename(__FILE__) )) {
    return $post_id;
  }

  // verify if this is an auto save routine. If it is our form has not been submitted, so we dont want
  // to do anything
  if ( defined('DOING_AUTOSAVE') && DOING_AUTOSAVE ) 
    return $post_id;

  
  // Check permissions
  if ( 'page' == $_POST['post_type'] ) {
    if ( !current_user_can( 'edit_page', $post_id ) )
      return $post_id;
  } else {
    if ( !current_user_can( 'edit_post', $post_id ) )
      return $post_id;
  }

  // OK, we're authenticated: we need to find and save the data
  delete_post_meta($post_id, 'link');

  $links = $_POST['linkpreview_links'];
  
  foreach ($links as $link) {
  	  if (!empty($link))
  	  	  add_post_meta($post_id, 'link', $link);
  }


   return $mydata;
}


?>
