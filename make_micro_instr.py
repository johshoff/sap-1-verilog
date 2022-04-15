def padded(lst, desired_len, value):
	yield from lst
	yield from (value for _ in range(desired_len - len(lst)))

# ben eater micro instructions https://youtu.be/Zg1NdPKoosU?t=504
en_write_out         = 0b1000000000000000 # OI
en_subtraction       = 0b0100000000000000 # SU
micro_done           = 0b0010000000000000 # --
halted               = 0b0001000000000000 # HLT
en_increment_pc      = 0b0000100000000000 # CE - count enable
en_write_a           = 0b0000010000000000 # AI - a register in
en_read_a            = 0b0000001000000000 # AO - a register out
en_write_b           = 0b0000000100000000 # BI - b register in
en_write_pc          = 0b0000000010000000 # J  - jump
en_read_pc           = 0b0000000001000000 # CO - program counter out
en_write_instr       = 0b0000000000100000 # II - instruction in
en_read_instr        = 0b0000000000010000 # IO - instruction out
en_write_mem         = 0b0000000000001000 # RI - RAM in
en_read_mem          = 0b0000000000000100 # RO - RAM out
en_write_mem_adr     = 0b0000000000000010 # MI - memory adr in
en_read_alu          = 0b0000000000000001 # ∑O (implies FI in my impl)
                                                          # FI - flags in

fetch_cycle = [
	en_read_pc   | en_write_mem_adr,
	en_read_mem  | en_write_instr    | en_increment_pc,
]

nop = 0

for carry in [False, True]:
	for zero in [False, True]:
		instructions = [
			[ # 0: nop
				micro_done,
			],
			[ # 1: LDA load memory to A
				en_read_instr | en_write_mem_adr,
				en_read_mem   | en_write_a       | micro_done,
			],
			[ # 2: ADD add A + memory at address, result in A
				en_read_instr | en_write_mem_adr,
				en_read_mem   | en_write_b,
				en_read_alu   | en_write_a | micro_done,
			],
			[ # 3: SUB a = a - b
				en_read_instr | en_write_mem_adr,
				en_read_mem   | en_write_b,
				en_read_alu   | en_write_a | en_subtraction | micro_done,
			],
			[ # 4: STA store value of A in memory
				en_read_instr | en_write_mem_adr,
				en_read_a     | en_write_mem    | micro_done,
			],
			[ # 5: LDI load immediate into a
				en_read_instr | en_write_a | micro_done,
			],
			[ # 6: JMP unconditional jmp
				en_read_instr | en_write_pc | micro_done,
			],
			[ # 7: JC jump if carry
				((en_read_instr | en_write_pc) if carry else nop) | micro_done,
			],
			[ # 8: JZ jump if zero
				((en_read_instr | en_write_pc) if zero else nop) | micro_done,
			],
			[ # 9: JNC jump if not carry
				((en_read_instr | en_write_pc) if not carry else nop) | micro_done,
			],
			[ # a: JNZ jump if not zero
				((en_read_instr | en_write_pc) if not zero else nop) | micro_done,
			],
			[], # b
			[], # c
			[], # d
			[ # e: OUT: out = a
				en_read_a | en_write_out | micro_done,
			],
			[ # f: halt
				halted
			],
		]

		for micro_instructions in padded(instructions, 16, []):
			for micro in padded(fetch_cycle + micro_instructions, 8, nop):
				print(f'{micro:016b}')

