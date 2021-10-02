#!/bin/bash

rm -f /tmp/{dropbear-limit.txt,user-list.txt,user-limit.txt}
touch /tmp/{dropbear-limit.txt,user-list.txt,user-limit.txt}

limit=$(cat /donb/script-3/limit)

while true; do
        unset data
        data=($(ps aux | grep -i dropbear | awk '{print $2}'))

        for pid in "${data[@]}"; do
                num=$(cat /var/log/auth.log | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$pid\]" | wc -l)
                user=$(cat /var/log/auth.log | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$pid\]" | awk '{print $10}')
                if [ $num -eq 1 ]; then
                        echo -e "$user\t$pid" | xargs >> /tmp/dropbear-limit.txt
                fi
        done

        cat /tmp/dropbear-limit.txt | awk '{print $1}' | sort | uniq -c > /tmp/user-list.txt

        while read login; do
                user=$(echo $login | awk '{print $2}')
                total=$(echo $login | awk '{print $1}')
                pid=$(cat /tmp/dropbear-limit.txt | grep -i $user | awk '{print $2}')

                if [[ $total -gt $limit ]]; then
                        echo $user >> /tmp/user-limit.txt
                        echo -e "Killed user '$user' ($total logins)."
                        for (( c=1; c<=$total; c++ )); do
                                pid_kill=$(echo $pid | cut -d " " -f $c)
                                kill $pid_kill
                                echo -e "$(date +'%d/%m/%Y %T')\t${user}\t${pid_kill}" >> /donb/script-3/multi-login.log
                        done
                fi
        done < /tmp/user-list.txt

        sleep 15

        rm -f /tmp/{dropbear-limit.txt,user-list.txt}
        touch /tmp/{dropbear-limit.txt,user-list.txt}

        data=($(ps aux | grep -i dropbear | awk '{print $2}'))

        for pid in "${data[@]}"; do
                num=$(cat /var/log/auth.log | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$pid\]" | wc -l)
                user=$(cat /var/log/auth.log | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$pid\]" | awk '{print $10}')
                if [ $num -eq 1 ]; then
                        echo -e "$user\t$pid" | xargs >> /tmp/dropbear-limit.txt
                fi
        done

        cat /tmp/dropbear-limit.txt | awk '{print $1}' | sort | uniq -c > /tmp/user-list.txt

        while read login; do
                user=$(echo $login | awk '{print $2}')
                total=$(echo $login | awk '{print $1}')
                pid=$(grep -i $user /tmp/dropbear-limit.txt | awk '{print $2}')

                if [[ $total -gt $limit ]]; then
                        if grep -qw "$user" /tmp/user-limit.txt; then
                                passwd -l $user
                                echo -e "Locked user '$user' ($total logins)."
                                for (( c=1; c<=$total; c++ )); do
                                        pid_kill=$(echo $pid | cut -d " " -f $c)
                                        kill $pid_kill
                                        echo -e "$(date +'%d/%m/%Y %T')\t${user}\t${pid_kill}" >> /donb/script-3/multi-login.log
                                done
                                echo -e "$(date +'%d/%m/%Y %T')\t${user}" >> /donb/script-3/user-lock.log
                        fi
                fi
        done < /tmp/user-list.txt

        rm -f /tmp/{dropbear-limit.txt,user-list.txt,user-limit.txt}
        touch /tmp/{dropbear-limit.txt,user-list.txt,user-limit.txt}
        sleep 15
done