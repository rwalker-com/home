# ~/.bash_logout

ps | while read -r pid tty time cmd; do
  [[ $cmd == dbus-launch ]] && kill -9 $pid
done
