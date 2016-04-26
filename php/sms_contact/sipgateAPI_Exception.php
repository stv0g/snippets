<?php
/**
 * 
 * @author Christian Schmidt
 * @license 
 * @copyright Copyright &copy; 2007, Christian Schmidt
 *
 * @package sipgateAPI
 * @subpackage sipgateAPI_Exception 
 */

/**
 * Extends PHP5 Exception handling
 * 
 * @package sipgateAPI
 * @subpackage sipgateAPI_Exception
 */
class sipgateAPI_Exception extends Exception 
{
	
}

/**
 * Throws Exeptions on server responses != "200 OK" 
 * @package sipgateAPI
 * @subpackage sipgateAPI_Exception
 */
class sipgateAPI_Server_Exception extends sipgateAPI_Exception 
{
	
}
