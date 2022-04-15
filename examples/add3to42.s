	lda forty_two
loop:
	add three
	out
	jnz loop
	hlt

.org 14
three:
	3
forty_two:
	42
