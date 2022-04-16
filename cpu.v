// an attempt to recreate Ben Eaters 8-bit computer in Verilog

module register(
	input wire [7:0] bus,
	input wire clk,
	input wire reset,
	input wire en_write,
	input wire en_read

);
	reg [7:0] value;

	always @(posedge clk)
		if (reset) value <= 0;
		else if (en_write) value <= bus;
endmodule

module memory(
	input wire [7:0] bus,
	input wire clk,
	input wire reset,
	input wire en_write_mem,
	input wire en_read_mem,
	input wire en_write_mem_adr
);
	reg [3:0] address_register;
	reg [7:0] data[0:15];
	reg [7:0] last_read;

	always @(posedge clk) begin
		if (reset) address_register <= 0; // zeroing address, but not memory
		else if (en_write_mem_adr) address_register <= bus;
		else if (en_write_mem) data[address_register] <= bus;
	end

	always @(*)
		if (en_read_mem) last_read <= data[address_register];
endmodule

module rom(
	input wire [8:0] address,
	output reg [15:0] out
);
	reg [15:0] data[0:511];

	always @(*)
		out <= data[address];
endmodule

module clock(
	output reg clk
);
	always #1 clk <= ~clk;

	initial clk = 0;
endmodule

module micro_instr_counter(
	input wire clk,
	input wire reset,
	output reg [2:0] count
);
	always @(posedge clk)
		if (reset) count <= 0;
		else if (count == 5) count <= 0;
		else count <= count + 1;
endmodule

module add_carry(
	input wire [7:0] a,
	input wire [7:0] b,
	input wire carry_in,
	output wire [7:0] sum,
	output wire carry_out
);
	wire [8:0] internal_sum;

	assign internal_sum = a + b + carry_in;
	assign sum = internal_sum[7:0];
	assign carry_out = internal_sum[8];
endmodule

module machine(
	input wire en_read_external,
	input wire [7:0] external_value,
	output wire halted
);
	wire [7:0] bus;
	wire clk;
	wire [7:0] alu;
	wire [15:0] micro;
	wire [2:0] micro_counter;
	reg reset = 0;
	wire en_write_a;
	wire en_read_a;
	wire en_write_b;
	wire en_write_pc;
	wire en_read_pc;
	wire en_increment_pc;
	wire en_write_instr;
	wire en_read_instr;
	wire en_write_mem;
	wire en_read_mem;
	wire en_write_mem_adr;
	wire en_read_alu;
	wire micro_done;
	wire en_subtraction;
	wire en_write_out;

	wire carry_out;
	reg last_zero;
	reg last_carry;

	clock c(clk);
	micro_instr_counter mc(clk, reset | micro_done, micro_counter);

	register a(bus, clk, reset, en_write_a, en_read_a);
	register b(bus, clk, reset, en_write_b, 1'b0); // never read
	register out(bus, clk, reset, en_write_out, 1'b0);
	register pc(bus, clk, reset, en_write_pc, en_read_pc);
	register instr(bus, clk, reset, en_write_instr, en_read_instr);

	memory m(bus, clk, reset, en_write_mem, en_read_mem, en_write_mem_adr);
	rom instr_decode({ last_carry, last_zero, instr.value[7:4], micro_counter }, micro);

	add_carry adc(
		a.value,
		en_subtraction ? ~b.value : b.value,
		en_subtraction,
		alu,
		carry_out);

	assign bus = en_read_alu      ? alu
	           : en_read_external ? external_value
	           : en_read_a        ? a.value
	           : en_read_pc       ? pc.value
	           : en_read_instr    ? { 4'b0, instr.value[3:0] }
	           : en_read_mem      ? m.last_read
	           : 0;

	assign
		{
			en_write_out,
			en_subtraction,
			micro_done,
			halted,
			en_increment_pc,
			en_write_a,
			en_read_a,
			en_write_b,
			en_write_pc,
			en_read_pc,
			en_write_instr,
			en_read_instr,
			en_write_mem,
			en_read_mem,
			en_write_mem_adr,
			en_read_alu
		} = micro;

	always @(posedge clk) begin
		if (en_increment_pc) pc.value <= pc.value + 1;
	end

	always @(posedge clk) begin
		if (reset) begin
			last_zero <= 0;
			last_carry <= 0;
		end else if (en_read_alu) begin
			last_zero <= alu == 0;
			last_carry <= carry_out;
		end
	end

	initial begin
		// "program" the ROM
		$readmemb("build/instruction_rom.bin", instr_decode.data);
	end
endmodule

module tb_machine();
	reg [7:0] external_value = 0;
	reg en_read_external = 0;
	wire halted;

	machine m(en_read_external, external_value, halted);

	initial begin
		// "program" the RAM
		$readmemh("build/fib.hex", m.m.data);

		// reset (RAM will be untouched)
		m.reset <= 1;
		#2; // 2 is a full cycle (pos+neg edge)
		m.reset <= 0;
		$monitor("OUT ", m.out.value);

		for (integer i=0; i<50000; i=i+1) begin
			//if (m.micro_counter == 0)
			//$display("%b  bus[%d]  a[%d]  b[%d]  out[%d]  pc[%d]  instr[%h:%h]  mc[%d]  micro[%b] z=%b c=%b", m.clk, m.bus, m.a.value, m.b.value, m.out.value, m.pc.value, m.instr.value[7:4], m.instr.value[3:0], m.micro_counter, m.micro, m.last_zero, m.last_carry);
			if (halted) $finish();
			#2;
		end
		$finish();
	end
endmodule