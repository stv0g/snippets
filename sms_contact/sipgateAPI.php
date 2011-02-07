<?php
/**
 * A PHP wrapper for sipgateAPI aka SAMURAI
 *
 * This is a private project.
 * It uses the API provided by sipgate, but sipgate can not and will not support any problems with this software.
 * You can find the API (including documentation) here: http://www.sipgate.de/api
 *
 *
 * @author Christian Schmidt
 * @license
 * @copyright Copyright 2007, Christian Schmidt
 *
 * @package sipgateAPI
 */

/**
 * Include Exception handling
 */
require_once 'sipgateAPI_Exception.php';


/**
 * Implements the samurai functionality for PHP programers. So you don't have to mess around with XML-RPC<br />
 * Requires "XML-RPC for PHP" (http://phpxmlrpc.sourceforge.net)
 *
 * This is a private project.
 * It uses the API provided by sipgate, but sipgate can not and will not support any problems with this software.
 * You can find the API (including documentation) here: http://www.sipgate.de/api
 *
 * @package sipgateAPI
 *
 * @version 0.1
 * @author Christian Schmidt
 */
class sipgateAPI
{
    const ClientVersion	= 0.1;
    const ClientName	= 'sipgateAPI with PHP';
    const ClientVendor	= 'Christian Schmidt';

    const SIP_URI_prefix = 'sip:';
    const SIP_URI_host = '@sipgate.de';

    private $client = null;
    private $url;
    private $debug;


    /**
     * Checks if XML-RPC for PHP is included
     *
     * @throws sipgateAPI_Exception when XML-RPC for PHP is not available
     */
    public function __construct($username, $password, $debug = FALSE)
    {
        // Check if xmlrpc is included
        if (!class_exists("xmlrpc_client")) {
            throw new sipgateAPI_Exception ('You need "xmlrpc for PHP" - Please download at http://phpxmlrpc.sourceforge.net');
        };

        $this->debug = $debug;

        if ( !empty($username) AND !empty($password) ) {
            $this->getClient($username, $password);
        }
        else {
            throw new sipgateAPI_Exception('Provide valid credentials');
        };

        return $this->client;
    }



    /**
     * configures a client to connect to XML-RPC server
     *
     * @param string $username Your sipgate username - the one you use on the website, NOT your SIP-ID
     * @param string $password
     *
     * @return object xmlrpc-client
     */
    private function getClient($username, $password)
    {
        if (null === $this->client) {

            // Build URL
            $this->url = "https://" . urlencode($username) . ":" . urlencode($password);
            if (self::isTeam($username)) {
               $this->url .= "@api.sipgate.net:443/RPC2";

            } else {
               $this->url .= "@samurai.sipgate.net:443/RPC2";
            }

            // create client
            $this->client = new xmlrpc_client($this->url);

            if ($this->debug) {
                $this->client->setDebug(2);
            }

            $this->client->setSSLVerifyPeer(FALSE);
        }

        return $this->client;

    } // function setClient


    private function isTeam($username)
    {
        return !FALSE == strpos($username, '@');
    }

    /**
     * implements <i>samurai.BalanceGet</i>
     *
     * @param void
     *
     * @return array
     *
     * @throws sipgateAPI_Server_Exception on Server responses != 200 OK
     *
     */
    public function getBalance()
    {
        //        // checks if method is supported
        //        if ( ! $this->methodSupported(__FUNCTION__) ) {
        //            throw new sipgateAPI_Exception("Method not supported", 400);
        //        }

        // create message
        $m = new xmlrpcmsg('samurai.BalanceGet');

        // send message
        $r = $this->client->send($m);

        if (!$r->faultCode()) {
            $php_r = php_xmlrpc_decode($r->value());
            unset($php_r["StatusCode"]);
            unset($php_r["StatusString"]);
            return $php_r;
        }
        else {
            throw new sipgateAPI_Server_Exception($r->faultString(), $r->faultCode());
        }
    }


    /**
     * sending SMS
     *
     * Sending a text message to a (mobile) phone. Message will be cut off after 160 characters
     *
     * @param string $to mobile number, example: 491701234567
     * @param string $message cut off after 160 chars
     * @param string $time unix timestamp in UTC
     *
     * @return
     */
    public function sendSMS($to, $message, $time = NULL, $from = NULL)
    {
        $remote = self::SIP_URI_prefix . $to . self::SIP_URI_host;
        $local = (isset($from)) ? (self::SIP_URI_prefix . $from . self::SIP_URI_host) : NULL;

        $message = substr($message, 0, 160);

        $this->samurai_SessionInitiate($local, $remote, "text", $message, $time);
    }





    /**
     * sending a PDF file as fax
     *
     * @param string $to fax number, example: 492111234567
     * @param string $file
     * @param string $time unix timestamp in UTC
     *
     * @return string Returns SessionID
     */
    public function sendFAX($faxnumber, $file, $time = NULL)
    {
        $number = self::SIP_URI_prefix . $faxnumber . self::SIP_URI_host;

        $file = realpath($file);

        if ( !file_exists($file) ) {
            throw new Exception("PDF file does not exist");
        }
        elseif ( strtolower(pathinfo($file, PATHINFO_EXTENSION)) != 'pdf' ) {
            throw new Exception("No PDF file");
        };


        $pdf_base64 = base64_encode(file_get_contents($file));
        $r = $this->samurai_SessionInitiate(NULL, $number, "fax", $pdf_base64, $time);

        return $r;
    }

    /**
     * implements <i>samurai.SessionInitiate</i>
     *
     *@param string $LocalUri as SIP-URI
     *@param string $RemoteUri as SIP-URI
     *@param string $TOS Type of service as defined in $availableTOS
     *@param string $Content depends on TOS
     *@param dateTime $schedule as unix timestamp
     *
     * @return string SessionID, if available
     *
     * @throws sipgateAPI_Server_Exception on Server responses != 200 OK
     */
    protected function samurai_SessionInitiate($LocalUri, $RemoteUri, $TOS, $Content, $Schedule = NULL)
    {
        if ( isset($LocalUri) ) {
            $val_a["LocalUri"] = new xmlrpcval($LocalUri);
        };

        if ( isset($RemoteUri) ) {
            $val_a["RemoteUri"] = new xmlrpcval($RemoteUri);
        }
        else {
            throw new sipgateAPI_Exception("No RemoteUri");
        };

        if ( isset($TOS) ) {
            $val_a["TOS"] = new xmlrpcval($TOS);
        }
        else {
            throw new sipgateAPI_Exception("No valid TOS");
        };

        if ( isset($Content) ) {
            $val_a["Content"] = new xmlrpcval($Content);
        };

        if ( isset($Schedule) ) {
            $val_a["Schedule"] = new xmlrpcval(iso8601_encode($Schedule), "dateTime.iso8601");
        };

        $val_s = new xmlrpcval();
        $val_s->addStruct($val_a);
        $v = array();
        $v[] = $val_s;

        // create message
        $m = new xmlrpcmsg('samurai.SessionInitiate', $v);

        // send message
        $r = $this->client->send($m);


        if (!$r->faultCode()) {
            $php_r = php_xmlrpc_decode($r->value());
            return $php_r["SessionID"];
        }
        else {
            throw new sipgateAPI_Server_Exception($r->faultString(), $r->faultCode());
        }
    }
}
