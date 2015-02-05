

for file in `find ./sound/soc/ -name "*.ko"`
do
echo "Pushing $file..."
sshpass -p ubuntu scp $file ubuntu@192.168.10.4:/lib/modules/3.14.19+/kernel/$file
done

sshpass -p axelh ssh axelh@192.168.10.4 "sync"


