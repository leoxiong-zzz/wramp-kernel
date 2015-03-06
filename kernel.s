# Written by Leo Xiong<hello@leoxiong.com> on 5/8/2014
#
# WRAMP multitasking kernel running a three processes

.data
DELAY:                      # timer delay, base quantum unit
    .word 24
old_evec:                   # old exception vector, used to pass on the exception if required
    .word 0
.global uptime
uptime:                     # uptime of kernel in seconds
    .word 0
centisecond:                # centiseconds (10ms) since last second
    .word 0
pid:                        # current process' base memory location in the PCB
    .word 0
p_quanta:                   # remaining quanta for the current process
    .word 0
.bss
PCB:
    .space 600              # Enough for 3 process
    .equ IP, 0
    .equ R1, 1
    .equ R2, 2
    .equ R3, 3
    .equ R4, 4
    .equ R5, 5
    .equ R6, 6
    .equ R7, 7
    .equ R8, 8
    .equ R9, 9
    .equ R10, 10
    .equ R11, 11
    .equ R12, 12
    .equ R13, 13
    .equ R14, 14
    .equ R15, 15
    .equ QUANTA, 16
    .equ NEXT_PID, 17
    .equ STACK, 199
.text
.global main
main:
    # Initialize handler
    movsg $1, $evec
    sw $1, old_evec($0) # save old $evec to 'pass on' exception if we shouldn't handle it

    # Load our hander address into $evec so WRAMP can call it when interrupted
    la $1, handler
    movgs $evec, $1

    # Setup timer
    sw $0, 0x72000($0)      # disable timer
    sw $0, 0x72003($0)      # make sure there are no outstanding acknowledge requests
    lw $1, DELAY($0)
    sw $1, 0x72001($0)      # store delay into timer count register
    addui $1, $1, 0x3       # 0x2 auto-restart + 0x1 enable = 0x3
    sw $1, 0x72000($0)      # enable timer and automatic restart

    # Set $cctrl to enable interrupts, IRQ2, KU, OKU
    movsg $1, $cctrl
    ori $1, $1, 0x4F
    movgs $cctrl, $1

    # Setup PCB
    la $13, PCB             # get PCB base offset

    # Setup process 1
    la $1, process1_main
    sw $1, IP($13)          # set entry point
    la $1, STACK
    addu $1, $1, $13
    sw $1, R14($13)         # set stack pointer
    addui $1, $0, 1
    sw $1, QUANTA($13)      # set quanta

    addui $1, $13, 200
    sw $1, NEXT_PID($13)    # link next process
    addu $13, $1, $0

    # Setup process 2
    la $1, process2_main
    sw $1, IP($13)          # set entry point
    la $1, STACK
    addu $1, $1, $13
    sw $1, R14($13)         # set stack pointer
    addui $1, $0, 1
    sw $1, QUANTA($13)      # set quanta

    addui $1, $13, 200
    sw $1, NEXT_PID($13)    # link next process
    addu $13, $1, $0

    # Setup process 3
    la $1, gamejob
    sw $1, IP($13)          # set entry point
    la $1, STACK
    addu $1, $1, $13
    sw $1, R14($13)         # set stack pointer
    addui $1, $0, 8
    sw $1, QUANTA($13)      # set quanta

    # Dispatch/run process 1
    la $1, PCB              # set $13 (PID) to the first process
    sw $1, NEXT_PID($13)    # set next process' address to self
    addu $13, $1, $0
    j dispatch_restore

handler:
    # Check if timer caused this interrupt, if not pass on
    movsg $13, $estat
    andi $13, $13, 0x40     # mask IRQ2 (timer interrupt)
    beqz $13, handler_pass_on

    # Timer interrupt triggered the exception, run handler
    sw $0, 0x72003($0)      # acknowledge interrupt

    # If it's been 100 centiseconds (100*10ms), increment seconds, else skip to scheduler
    lw $13, centisecond($0)
    addui $13, $13, 1
    remi $13, $13, 100
    sw $13, centisecond($0)
    bnez $13, scheduler

    # Increment uptime
    lw $13, uptime($0)
    addui $13, $13, 1
    sw $13, uptime($0)

scheduler:
    # One quantum has passed, if process is out of quanta, dispatch next process, else rfe
    lw $13, p_quanta($0)
    subui $13, $13, 1
    sw $13, p_quanta($0)
    bnez $13, handler_return

dispatch_save:
    # Get current process' offset in PCB
    lw $13, pid($0)

    # Store current process' state onto the PCB
    sw $1, R1($13)
    sw $2, R2($13)
    sw $3, R3($13)
    sw $4, R4($13)
    sw $5, R5($13)
    sw $6, R6($13)
    sw $7, R7($13)
    sw $8, R8($13)
    sw $9, R9($13)
    sw $10, R10($13)
    sw $11, R11($13)
    sw $12, R12($13)
    sw $14, R14($13)
    sw $15, R15($13)

    # Registers 1 to 15 are now free for use from this point onwards

    # Store process' $13 (WRAMP has moved $13 into $ers)
    movsg $1, $ers
    sw $1, R13($13)

    # Store process' $ip (WRAMP has moved $ip into $ear)
    movsg $1, $ear
    sw $1, IP($13)

dispath_next:
    lw $13, NEXT_PID($13)   # get next process' offset in the PCB

dispatch_restore:
    sw $13, pid($0)         # set new PID

    # Restore process' $ip (rfe will set $ip to $ear)
    lw $1, IP($13)
    movgs $ear, $1

    # Restore process' $13 (rfe will set $13 to $ers)
    lw $1, R13($13)
    movgs $ers, $1

    # Reset quanta allocated for process
    lw $1, QUANTA($13)
    sw $1, p_quanta($0)

    lw $1, R1($13)
    lw $2, R2($13)
    lw $3, R3($13)
    lw $4, R4($13)
    lw $5, R5($13)
    lw $6, R6($13)
    lw $7, R7($13)
    lw $8, R8($13)
    lw $9, R9($13)
    lw $10, R10($13)
    lw $11, R11($13)
    lw $12, R12($13)
    lw $14, R14($13)
    lw $15, R15($13)

handler_return:
    rfe                     # we're done with the handler, let WRAMP clean up the rest

handler_pass_on:
    # Nope, we don't handle this exception
    lw $13, old_evec($0)
    jr $13
