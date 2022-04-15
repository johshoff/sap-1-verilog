	ldi 5
	out
subjnz:
	sub one
	out
	jnz subjnz

	ldi 13
	out
subjnc:
	sub three
	out
	jc subjnc

	hlt
.org 14
one:
	1
three:
	3
