

for file in `git status |grep modified|awk '{print $2}'`;
do 
	sed -i 's/[ \t]*$//' $file	
done 


