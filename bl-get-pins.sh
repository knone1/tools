sshpass -p ubuntu ssh ubuntu@192.168.10.4  "rm ~/pins.txt"

sshpass -p ubuntu ssh ubuntu@192.168.10.4 "cat /sys/kernel/debug/pinctrl/44e10800.pinmux/pins > ~/pins.txt"
sshpass -p ubuntu scp ubuntu@192.168.10.4:/home/ubuntu/pins.txt .
