
set(){
echo "wlan down..."
sudo ifconfig wlan0 down
echo "monitor mode..."
sudo iwconfig wlan0 mode monitor
echo "channel..."$1
sudo iwconfig wlan0 channel $1

echo "wlan up "
sudo ifconfig wlan0 up
}

unset(){

echo "wlan down..."
sudo ifconfig wlan0 down
echo "managed mode..."
sudo iwconfig wlan0 mode managed
echo "wlan up "
sudo ifconfig wlan0 up

}

# parse commandline options
while [ ! -z "$1" ]; do
  case $1 in
        -s)set $2;;
	-u)unset;;
  esac
  shift
done



