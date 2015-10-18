#!/bin/bash

#----------------------------------------
# LogChangeNotify -- lingTalfi -- 2015-10-18
#----------------------------------------


# logchangenotify -f file [-m  mirror] [-d diff] [-h hooks] [-v]
# 
# - file: the log file to watch. It must exist
# - mirror: the mirror path.
#               By default, it's the same as the file path, with the suffix ".mirror" appended.
# - diff: the diff path.
#               By default, it's the same as the file path, with the suffix ".diff" appended.
# - hooks: the directory containing the hooks.
#               By default, it's the same as the file path, with the suffix ".hooks.d" appended.
#                  
#               A hook is being executed based on its file extension.
#               Accepted languages are:  
#                   - bash (.sh)  
#                   - php (.php)  
#                   - ruby (.rb)  
#                   - python (.py)  
#                   - perl (.pl)  
# - v: verbose, use this option to have a more verbose output.                 
#                 
# Hook scripting
# ----------------------                
#                 
# Inside a hook, the following rules appy:
# 
# - anything that is printed will be printed as is on stdOut.
#         Except for a line that starts with 'error:'; this line would be send to the error core function of the logChangeNotify script.
#         This is the only way hook authors can gain access to the error method of the logChangeNotify script, which might be useful
#         if you care about redirecting the (logChangeNotify) stdErr file descriptor. 
#         
# - logChangeNotify gives you one variable: LOG_CHANGE_NOTIFY_DIFF, which is accessible from your script environment
#     (for instance, $_SERVER['LOG_CHANGE_NOTIFY_DIFF'] in php),
#     and which value is the path to the diff file.
#     The hooks should parse the diff file and do something with it, because after all the hooks have been executed,
#     the diff file is removed by the logChangeNotify script.
# 
# 




_programName=logchangenotify
logFile=""
mirror=""
diff=""
hooksDir=""
verbose=0





 
error (){
    echo "${_programName}: $1" >&2
    if [ -n "$2" ]; then
        help
    fi
    exit 1
} 

help (){
    echo "Usage: $_programName -f file [-m  mirror] [-d diff] [-h hooks] [–v]"
} 


log(){
    if [ "$verbose" -ge 1 ]; then
        echo -e "\e[34m${_programName}(v):\e[0m $1"
    fi
}

diffRotation(){
    
    # assuming first lines are identical
    nbLinesMirror=$(cat -n "$mirror" | tail -n 1 | cut -f1 | xargs)
    if [ -z "$nbLinesMirror" ]; then
        nbLinesMirror=0
    fi
    
    nbLinesLogFile=$(cat -n "$logFile" | tail -n 1 | cut -f1 | xargs)
    if [ -z "$nbLinesLogFile" ]; then
        nbLinesLogFile=0
    fi
        
    diffLine=$(( nbLinesLogFile - nbLinesMirror ))
    log "The logFile contains $diffLine more lines than the mirror file"
    
    tailStart=$((nbLinesMirror + 1))
  
    if [ "$nbLinesLogFile" -gt "$nbLinesMirror" ]; then
        log "putting the extra lines in the diff file"
        cat "$logFile" | tail -n +"$tailStart" > "$diff"
        hooks
    fi
    
}
executeHook(){
    ext=${1##*.}
    export "LOG_CHANGE_NOTIFY_DIFF"="$diff"
    log "executing hook: $1"
    
    case "$ext" in
        sh)
            __lines=$(bash "$1")
        ;;
        php)
            __lines=$(php -f "$1")
        ;;
        py)
            __lines=$(python "$1")
        ;;
        rb)
            __lines=$(ruby "$1")
        ;;
        pl)
            __lines=$(perl "$1")
        ;;
        *)  
            error "Unknown extension $ext"
        ;;
    esac
    
    processScriptOutput "$__lines"
    
}
export -f executeHook


processScriptOutput () # ( vars )
{
    while read line
    do
        if [ "error:" = "${line:0:6}" ]; then
            error "${line:6}"
        else
            if [ -n "$line" ]; then
                echo "$line"
            fi
        fi
    done <<< "$1"
}


hooks(){

    if [ -z "$hooks" ]; then
        hooks="$logFile.hooks.d"
        if [ ! -d "$hooks" ]; then
            mkdir "$hooks"
        fi
    fi
    if [ -d "$hooks" ]; then
        log "executing hooks"
        find "$hooks" -type f \( -name "*.sh" -or -name "*.php" -or -name "*.py" -or -name "*.rb" -or -name "*.pl" \) | while read file; do 
             executeHook "$file"
        done 
        
        # now that all hooks have been executed, let's remove the diff file
        rm "$diff"
        
        # we also want to update the mirror with the value of the logFile.
        cp -f "$logFile" "$mirror"
        if [ 0 -eq $? ]; then
            log "Copied logFile to mirror successfully"
        else
            error "Couldn't copy logFile to mirror"
        fi
        
         
    else
        error "hooks directory does not exist or couldn't be created: $hooks"
    fi
}

while getopts :d:f:h:m:v opt; do
    case "$opt" in
        d) diff="$OPTARG" ;;
        f) logFile="$OPTARG" ;;
        h) hooksDir="$OPTARG" ;;
        m) mirror="$OPTARG" ;;
        v) verbose=1 ;;
    esac
done



# Check that log file and log dir are created
if [ -n "$logFile" ]; then
    if [ -f "$logFile" ]; then

        if [ -z "$mirror" ]; then
            mirror="$logFile.mirror"
        fi
        if [ ! -f "$mirror" ]; then
            touch "$mirror"
        fi
        
        
        if [ -z "$diff" ]; then
            diff="$logFile.diff"
        fi
        if [ ! -f "$diff" ]; then
            touch "$diff"
        fi
        
        
        
        if [ -f "$mirror" ]; then
            if [ -f "$diff" ]; then
            
            
                log "Config ok with logFile: $logFile, mirror: $mirror, diff: $diff"
            
                diffRotation            
            else
                error "diff file does not exist or couldn't be created: $diff"
            fi             
        else
            error "mirror file does not exist or couldn't be created: $mirror"
        fi 
    else
        error "logFile is not a file: $logFile"
    fi
else
    error "logFile not defined" 1
fi



