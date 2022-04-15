start:
	LDA x
	SUB one
	JC  continue
	LDA product
	OUT
	HLT
continue:
	STA x
	LDA product
	ADD y
	STA product
	JMP start
one:
	1
product:
	0
x:
	7
y:
	8
