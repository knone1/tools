
echo "Copy asound.state..."
sshpass -p ubuntu scp asound.state ubuntu@192.168.10.4:/home/ubuntu/
sshpass -p ubuntu ssh ubuntu@192.168.10.4 "sudo cp asound.state /var/lib/alsa/asound.state"

echo "Copy .asoundrc"
sshpass -p ubuntu scp ./asoundrc ubuntu@192.168.10.4:/home/ubuntu/.asoundrc

