// an attempt to recreate Ben Eaters 8-bit computer in Verilog

module register(
	inout wire [7:0] bus,
	input wire clk,
	input wire reset,
	input wire en_write,
	input wire en_read

);
	reg [7:0] value;

	assign bus = en_read ? value : 'bz;

	always @(posedge clk)
		if (reset) value <= 0;
		else if (en_write) value <= bus;
endmodule

module memory(
	inout wire [7:0] bus,
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

	assign bus = en_read_mem ? last_read : 'bz;
endmodule

module rom(
	input wire [8:0] address,
	output reg [15:0] out
);
	reg [15:0] data[0:511];

	always @(*)
		out <= data[address];
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
	input wire clk,
	input wire en_read_external,
	input wire [7:0] external_value,
	output wire halted
);
	wire [7:0] bus;
	wire [7:0] instr_bus; // intermediate bus for instructions for masking
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

	micro_instr_counter mc(clk, reset | micro_done, micro_counter);

	register a(bus, clk, reset, en_write_a, en_read_a);
	register b(bus, clk, reset, en_write_b, 1'b0); // never read
	register out(bus, clk, reset, en_write_out, 1'b0);
	register pc(bus, clk, reset, en_write_pc, en_read_pc);
	register instr(instr_bus, clk, reset, en_write_instr, en_read_instr);

	memory m(bus, clk, reset, en_write_mem, en_read_mem, en_write_mem_adr);
	rom instr_decode({ last_carry, last_zero, instr.value[7:4], micro_counter }, micro);

	add_carry adc(
		a.value,
		en_subtraction ? ~b.value : b.value,
		en_subtraction,
		alu,
		carry_out);

	assign bus = en_read_external ? external_value : 'bz;
	assign bus = en_read_alu      ? alu            : 'bz;

	assign bus = en_read_instr ? { 4'b0, bus[3:0] } : 'bz;
	assign instr_bus = en_write_instr ? bus : 'bz;

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

