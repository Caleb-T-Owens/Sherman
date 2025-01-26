@ References:
@ https://www.cl.cam.ac.uk/projects/raspberrypi/tutorials/os/ok01.html
@ https://developer.arm.com/documentation/ddi0301/h/?lang=en
@   https://developer.arm.com/documentation/ddi0301/h/introduction/arm1176jzf-s-instruction-set-summary/extended-arm-instruction-set-summary?lang=en
@ https://en.wikipedia.org/wiki/Raspberry_Pi
@ https://www.raspberrypi.org/app/uploads/2012/02/BCM2835-ARM-Peripherals.pdf
@ https://www.cl.cam.ac.uk/teaching/2005/ECADArch/datasheets/arm_quick.pdf
@ https://developer.arm.com/documentation/den0013/d/Introduction-to-Assembly-Language/Introduction-to-the-GNU-Assembler

@ This declares a section. The compiler is fed a `kernel.ld` file as part of
@ the linker step which is a kind of schema for the resulting elf file.
@ We've declared that the .init section should come first, meaning it's what
@ our pi will run first, after the bootloader has finished.
@ Without this configuration, if we had multiple sections?/files? it would
@ output them in alphabetical order.
.section .init
@ Typically when compiling a program for a standard operating system, we
@ to declare a global symbol that I believe the OS looks for rather than
@ simply starting execution at the start of the binary file. In our case, this
@ is superflous as after the bootloader, the pi does simply start at the start
@ of our compiled binary. We still include this here as without it the
@ compiler complains, as it's typicaly expected.
.globl _start
_start:

@ ldr loads a word (32 bits) into a register. ldr is a psudo instruction that
@ uses multiple mov instructions to load the data into the register. mov only
@ operates on 8bit numbers on this system.
@ We are storing 0x20200000 into the first register (of which there are 13
@ general purpouse ones r0 through to r12). 0x20200000 is the address location
@ of the GPIO controller. For some perverted reason, in the manual there is a
@ different addressing scheme, so they list it as being at 0x7E200000. I don't
@ know how you are meant to know that.
@ In the BCM peripherals manual, check out `6.1 Register View` for the GPIO
@ registers
ldr r0,=0x20200000
@ The following is roughly equivalent:
@ mov r0,#0x20
@ lsl r0,#0x8
@ orr r0,#0x20
@ lsl r0,#0x10

@ # Enabling output

@ Set r1 to the value 1. `mov` has a "flexable" oprand. In our case we want to
@ load the value 1, so we use # to indicate immediate mode. In this case we're
@ simply using decimal numbers.
mov r1,#0x1
@ Logical shift left. Shift the value in r1 over 18 positions and store it
@ back in r1. This results in r1 being 0b1000000000000000000. Not sure why we
@ didn't just set r1 to this value in the first place. But... I guess this is
@ cool.
lsl r1,#0x12
@ Store. Stores the contents of r1 at the location specified by `[r0,#4]`.
@ This is a funky little bit of syntax to find the right address. It is taking
@ the value of r0 and adding the constant 4 to it. The result is simply the
@ address `0x20200004`
str r1,[r0,#0x4]

@ # Sending output signal
mov r1,#0x1
lsl r1,#0x1
str r1,[r0,#0x24]

loop$:
b loop$
