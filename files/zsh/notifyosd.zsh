# commands to ignore
cmdignore=(ncdu htop tmux top vim vimserv nvim emacs e v)

# set gt 0 to enable GNU units for time results
gnuunits=0

# end and compare timer, notify if needed
function notifyosd-precmd() {
    retval=$?
    if [[ ${cmdignore[(r)$cmd_basename]} == $cmd_basename ]]; then
        return
    else
        if [ ! -z "$cmd" ]; then
            cmd_end=`date +%s`
            ((cmd_secs=$cmd_end - $cmd_start))
        fi
        if [ $retval -gt 0 ]; then
            cmdstat="with warning"
        else
            cmdstat="successfully"
        fi
        if [ ! -z "$cmd" -a $cmd_secs -gt 10 ]; then
            if [ $gnuunits -gt 0 ]; then
                cmd_time=$(units "$cmd_secs seconds" "centuries;years;months;weeks;days;hours;minutes;seconds" | \
                sed -e 's/\ +/\,/g' -e s'/\t//')
            else
                cmd_time="$cmd_secs seconds"
            fi

            if [[ "$OSTYPE" == darwin* ]]; then
                terminal-notifier -message "'$cmd' took $cmd_time" -subtitle "$cmd_basename completed $cmdstat"
            else
                notify-send -i utilities-terminal --hint=int:transient:1 "$cmd_basename completed $cmdstat" "\"$cmd\" took $cmd_time"
            fi
        fi
        unset cmd
    fi
}

# make sure this plays nicely with any existing precmd
precmd_functions+=( notifyosd-precmd )

# get command name and start the timer
function notifyosd-preexec() {
    cmd=$1
    cmd_basename=${${cmd:s/sudo //}[(ws: :)1]}
    cmd_start=`date +%s`
}

# make sure this plays nicely with any existing preexec
preexec_functions+=( notifyosd-preexec )
