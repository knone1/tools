
sudo echo ""

cd /sys/kernel/debug/tracing
sudo  echo function > current_tracer
sudo  echo 1 > ./tracing_enabled
sudo echo 1 > tracing_on
sleep 2
sudo echo 0 > tracing_on
cp /sys/kernel/debug/trace /home/mmes/VMSHARE/PYTRACE/t.txt