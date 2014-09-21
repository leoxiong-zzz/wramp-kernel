# Written by Leo Xiong<hello@leoxiong.com> on 4/10/2014
#
# printf-ish
# printf(*format, arg1, arg2, ...)
#
# Easily expandable printf function.
#
# Dependencies:
# 	atou.s		- uint ascii to uint binary
# 	utoa.s		- uint binary to uint ascii
# 	strlen.s	- string length
#
# --------------------------------------------------
#
# $1 - return value
#
# $2 - format address index
# $3 - char in format
#
# $4 - vararg index
# $5 - value of next vararg (could be anything, asciiz, uint, pointers, etc)
#
# $6 - tmp ('long term')
# $7 - tmp ('short term')

.text
.global printf
printf:
	# Allocate space on stack to backup registers we're using
	subui $sp, $sp, 7
	sw $2, 0($sp)
	sw $3, 1($sp)
	sw $4, 2($sp)
	sw $5, 3($sp)
	sw $6, 4($sp)
	sw $7, 5($sp)
	sw $ra, 6($sp)

	# Initialize registers
	lw $2, 7($sp)			# $2 = *format
	addui $4, $sp, 8		# $4 = bottom of stackframe

printf_next:
	# Parse next char and determine what to do
	jal printf_get_next_char

	# Test for null
	sequi $7, $3, 0
	bnez $7, printf_return

	# Test for format specifier prefix
	sequi $7, $3, '%'
	bnez $7, printf_format

	# Just a normal char, print it
	j printf_write

printf_format:
	# Determine specifier
	jal printf_get_next_char

	# Test for unsigned int
	seqi $7, $3, 'u'
	bnez $7, printf_format_uint

	# Test for left pad 0
	seqi $7, $3, '0'
	bnez $7, printf_format_lpad_0

	# Test for escaping %
	seqi $7, $3, '%'
	bnez $7, printf_format_escape

	# Unknown format
	j printf_format_unknown

printf_format_uint:
	# Print uint
	jal printf_get_next_vararg
	# Convert uint to ascii
	subui $sp, $sp, 1
	sw $5, 0($sp)
	jal utoa				# call utoa(vararg_uint)

	# Print ascii result from utoa
	sw $1, 0($sp)
	jal printf
	addui $sp, $sp, 1

	j printf_next

printf_format_lpad_0:
	# Get length of next vararg, length in $1
	jal printf_get_next_vararg
	subui $sp, $sp, 1
	sw $5, 0($sp)
	jal utoa
	sw $1, 0($sp)
	jal strlen
	addui $sp, $sp, 1

	# Get length to pad (single digit will suffice for the purposes of this lab), length in $6
	jal printf_get_next_char
	subui $6, $3, 48

	# Skip padding if length of vararg > length to pad
	sle $7, $6, $1
	bnez $7, printf_format_lpad_0_return

	# Calculate number of 0s to pad, length in $6
	subu $6, $6, $1			# $6 is number of 0s to pad

printf_format_lpad_0_pad:
	# Loop $6 times printing 0
	jal printf_poll_sp1_tdr
	addui $7, $0, 48
	sw $7, 0x70000($0)
	subui $6, $6, 1
	bnez $6, printf_format_lpad_0_pad

printf_format_lpad_0_return:
	# Goto printf_format since the next char in format is the specifier
	subui $4, $4, 1			# decrement vararg index since we called printf_get_next_vararg
							# to get the length of the vararg
	j printf_format

printf_format_escape:
	# Print next char (which is %)
	j printf_write

printf_format_unknown:
	# Skip printing
	j printf_next

printf_poll_sp1_tdr:
	# Poll for serial port 1 tdr bit
	lw $7, 0x70003($0)
	andi $7, $7, 0x2		# mask tdr bit from serial port 1 status register
	beqz $7, printf_poll_sp1_tdr	# if (!tdr) goto printf_poll_sp1_tdr
	jr $ra

printf_write:
	# Write %3 to serial port
	jal printf_poll_sp1_tdr
	# Write to serial port 1
	sw $3, 0x70000($0)
	j printf_next

printf_get_next_char:
	# Get next char in format
	lw $3, 0($2)			# $4 = offset in *format
	addui $2, $2, 1			# shift offset down (right 1 char)
	jr $ra

printf_get_next_vararg:
	# Get next vararg (note: it could be anything, uint, pointer, string)
	lw $5, 0($4)			# $5 = vararg
	addui $4, $4, 1			# shift vararg index down (right 1 param)
	jr $ra

printf_return:
	# Restore non-volatile registers and unallocate space on stack
	addu $1, $2, $0
	lw $2, 0($sp)
	lw $3, 1($sp)
	lw $4, 2($sp)
	lw $5, 3($sp)
	lw $6, 4($sp)
	lw $7, 5($sp)
	lw $ra, 6($sp)
	addui $sp, $sp, 7

	# Ciao!
	jr $ra
