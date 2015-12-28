function ssh
    while not lpass ls > /dev/null
        lpass login supereman16@gmail.com
    end
    set pass (lpass show think-laptop@id_rsa | tail -1 | cut -d ' ' -f 2)
    sshpass -p "$pass" /usr/bin/ssh $argv
end
