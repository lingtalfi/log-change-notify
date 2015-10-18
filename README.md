Log Change Notify
======================
2015-10-18





What is it?
----------------

It's a bash script which detects when a log file is updated, and takes actions upon that change.

Concretely, you can monitor your application error log (every minute for instance with cron),
and send you an email if the log has increased in size.
Therefore, error logs are the main target of this script.


Features
-------------
- you can script multiple hooks (not just one), the following scripting languages are supported:

    - bash
    - php
    - python
    - ruby
    - perl
        
- cron friendly
- easy setup
- lightweight (about 200 lines of code) 



How does it work?
--------------------

![ log change notify ](http://s19.postimg.org/kzw2mvwyr/log_change_notify.jpg)

There is a logFile, which is probably your application error log file (or a php error log file for instance).<br>
Basically, the script creates a mirror of your logFile, and every time you run it, it compares the mirror to the logFile.<br>
If the logFile is not identical to the mirror file, the script puts the difference to a diff file, and call the hooks.<br>
With the hooks, you've got the opportunity to parse the diff file and send you an email, or any other action that you would like.
 
 
Command Line Usage
----------------------

```yaml
logchangenotify -f file [-m  mirror] [-d diff] [-h hooks] [-v]
```


- file: the log file to watch. It must exist
- mirror: the mirror path.
              By default, it's the same as the file path, with the suffix ".mirror" appended.
- diff: the diff path.
              By default, it's the same as the file path, with the suffix ".diff" appended.
- hooks: the directory containing the hooks.
    By default, it's the same as the file path, with the suffix ".hooks.d" appended.
     
    A hook is being executed based on its file extension.
    Accepted languages are:
      
    - bash (.sh)  
    - php (.php)  
    - ruby (.rb)  
    - python (.py)  
    - perl (.pl)  
        
- v: verbose, use this option to have a more verbose output.                 


Examples
------------

```bash
# minimal example
> logchangenotify -f myapp.log 

# Specifying the mirror file
> logchangenotify -f myapp.log -m mirror.txt

# Specifying the diff file
> logchangenotify -f myapp.log -m mirror.txt -d diff.txt


# Specifying the hooks directory
> logchangenotify -f myapp.log -m mirror.txt -d diff.txt -h hooks

# using a more verbose output
> logchangenotify -f myapp.log -m mirror.txt -d diff.txt -h hooks -v 


```



                
Hook scripting
----------------------                
                
Inside a hook, the following rules appy:

- anything that is printed will be printed as is on stdOut.<br>
        Except for a line that starts with 'error:'; this line would be send to the error core function of the logChangeNotify script.<br>
        This is the only way hook authors can gain access to the error method of the logChangeNotify script, which might be useful
        if you care about redirecting the (logChangeNotify) stdErr file descriptor. 
        
- logChangeNotify gives you one variable: **LOG_CHANGE_NOTIFY_DIFF**, which is accessible from your script environment
    (for instance, $_SERVER['LOG_CHANGE_NOTIFY_DIFF'] in php),
    and which value is the path to the diff file.<br>
    The hooks should parse the diff file and do something with it, because after all the hooks have been executed,
    the diff file is removed by the logChangeNotify script.


Bonus
---------

There is an example [sendMail.php](https://github.com/lingtalfi/log-change-notify/blob/master/hooks/sendMail.php) script example in the hooks directory of this repo.
