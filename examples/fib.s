    LDI 1
    STA x
    LDI 0
loop:
    STA y
    OUT
    LDA x
    ADD y
    STA x
    OUT
    LDA y
    ADD x
    JC  halt
    JMP loop
halt:
    HLT
x:
    0
y:
    0
