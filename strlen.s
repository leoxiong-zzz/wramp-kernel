# Written by Leo Xiong<hello@leoxiong.com> on 10/4/2014
#
# String length
# strlen(*asciiz)

.text
.global strlen
strlen:
	# Allocate space on stack to backup registeres we're using
	subui $sp, $sp, 1
	sw $2, 0($sp)

	# Initialize registers
	lw $1, 1($sp)

strlen_next:
	# Get next char
	lw $2, 0($1)
	beqz $2, strlen_return
	addui $1, $1, 1
	j strlen_next

strlen_return:
	lw $2, 1($sp)
	subu $1, $1, $2
	# Restore non-volatile registers and unallocate spcae on stack
	lw $2, 0($sp)
	addui $sp, $sp, 1

	# Toodles
	jr $ra
