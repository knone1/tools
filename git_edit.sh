
pop()
{
	echo "poping.. to $1"
	rm -rf ./.git_edit
	git format-patch $1..HEAD -o ./.git_edit/
	git reset --hard $1
}

push()
{
	echo "pushing..."
	git am ./.git_edit/*
}

if [ $1 = "pop" ]; then
	pop $2
fi
if [ $1 = "push" ]; then
	push
fi







