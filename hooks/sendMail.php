<?php

//------------------------------------------------------------------------------/
// SendMail example in php
//------------------------------------------------------------------------------/
/**
 * This is an example hook for logChangeNotify bash script.
 * 
 * It showcases how one can send a mail to the admin using php.
 */



/**
 * This function is actually a proxy to the "error" method
 * of the logChangeNotify script.
 */
function error($m)
{
    echo 'error:' . $m . PHP_EOL;
}


/**
 * This is a basic send mail method.
 * You probably want to replace it with one of yours there.
 */
function sendMail($to, $subject, $message)
{
    $headers = 'From: webmaster@example.com' . "\r\n" .
        'Reply-To: webmaster@example.com' . "\r\n" .
        'X-Mailer: PHP/' . phpversion();

//    echo "send mail to $to";
    mail($to, $subject, $message, $headers);
}


// This is the env variable exported by the logChangeNotify script
$diffFile = $_SERVER['LOG_CHANGE_NOTIFY_DIFF'];


if (file_exists($diffFile)) {
    /**
     * Get rid of empty lines
     */
    $lines = array_filter(file($diffFile), function ($v) {
        if ('' === trim($v)) {
            return false;
        }
        return true;
    });


    /**
     * Sending the mail using an application function...
     */
    $date = date("Y-m-d H:i:s");
    $message = implode(PHP_EOL, $lines);
    sendMail(
        'admin@mysite.com',
        "mySite: Oops, the error file has been updated!",
        <<<EEE
Date: $date     
Message: $message
EEE
    );


}
else {
    error("diff file doesn't $diffFile");
}