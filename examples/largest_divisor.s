    LDA xfirst
    OUT
outer:
    LDA xeach
    SUB one
    STA xeach
    LDA xfirst
inner:
    SUB xeach
    JZ  end
    JNC outer
    JMP inner
end:
    LDA xeach
    OUT
    HLT
one:
    1
xeach:
	181
xfirst:
	181
