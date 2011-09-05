find  .                                                                \
	-path "$LNX/arch/*" ! -path "$LNX/arch/arm*" -prune -o               \
	-path "$LNX/include/asm-*" ! -path "$LNX/include/asm-arm*" -prune -o \
	-path "$LNX/tmp*" -prune -o                                           \
	-path "$LNX/Documentation*" -prune -o                                 \
	-path "$LNX/scripts*" -prune -o                                       \
	-path "$LNX/drivers*" -prune -o                                       \
    -name "*.[chxsS]" -print >./cscope.files

	
cscope -b -q -k
ctags -R *
