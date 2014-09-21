# Written by Leo Xiong<hello@leoxiong.com> on 4/10/2014
#
# Unsigned to ASCII
# utoa(unsigned x)
#
# Notes:
# 	Follows __cdecl
#
# $1 - address of asciiz
# $2 - x
# $3 - tmp

.text
.global utoa
utoa:
.bss
	.space 11			# length of 2^32-1 as a string + 1 for the null terminator
asciiz:
.text
	# Allocate space on stack to backup the registers we're using
	subui $sp, $sp, 2
	sw $2, 0($sp)
	sw $3, 1($sp)

	la $1, asciiz		# load *asciiz
	lw $2, 2($sp)		# load x param

	addu $3, $0, $0
	sw $3, asciiz($0)	# terminate asciiz with null

utoa_shift_right:
	# Get least significant digit
	remi $3, $2, 10		# x % 10

	# Prepend least significant digit into output
	addui $3, $3, 48	# add 48 (0 in ascii) to the result
	subui $1, $1, 1		# move up back the asciiz (since we're filling from right to left)
	sw $3, 0($1)		# write to asciiz

	# Shift x right (essentially >> with base 10)
	divui $2, $2, 10	# floor division

	# If we've processed every digit, fall through to return
	bnez $2, utoa_shift_right

utoa_return:
	# Restore non-volatile registers and unallocate space on stack
	lw $2, 0($sp)
	lw $3, 1($sp)
	addui $sp, $sp, 2

	# Bye bye
	jr $ra
