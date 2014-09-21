.data
FORMAT:
	.asciiz "\r\n%u"	# printf format string
.text
.global process2_main
process2_main:
	la $2, FORMAT		# load *format
loop:
	# Block until switches changes
	addu $4, $3, $0		# $4 is $3_old
	lw $3, 0x73000($0)	# get switches
	sub $4, $4, $3		# check diff between switches and switches_old
	beqz $4, loop		# if there is no diff, keep checking else printf

	# Call printf
	subui $sp, $sp, 2
	sw $3, 1($sp)
	sw $2, 0($sp)
	jal printf
	addui $sp, $sp, 2

	j loop
