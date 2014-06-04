
sshpass -p root ssh root@192.168.0.2 "nohup /usr/lib/systemd/scripts/x11vnc-launcher.sh "



sleep 4
java -jar /home/mmes/tools/tightvnc-jviewer.jar&
