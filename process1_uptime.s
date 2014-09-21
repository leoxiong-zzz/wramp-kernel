.text
.global process1_main
process1_main:
loop:
	lw $1, uptime($0)	# load uptime
	remi $1, $1, 0x100	# wrap after 0xFF

	# Write to seven segment display
	sw $1, 0x73003($0)
	srli $1, $1, 4
	sw $1, 0x73002($0)

	j loop
