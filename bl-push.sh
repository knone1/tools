FILE=$1

sshpass -p ubuntu ssh ubuntu@192.168.10.4  "rm ~/$FILE"

sshpass -p ubuntu scp $FILE ubuntu@192.168.10.4:$FILE
