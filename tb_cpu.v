module clock(
	output reg clk
);
	always #1 clk <= ~clk;

	initial clk = 0;
endmodule

module tb_cpu();
	reg [7:0] external_value = 0;
	reg en_read_external = 0;
	wire halted;
	wire [7:0] out_reg;

	clock c(clk);
	machine m(clk, en_read_external, external_value, out_reg, halted);

	initial begin
		// optionally overwrite the program in RAM
		//$readmemh("build/largest_divisor.hex", m.m.data);

		// reset (RAM will be untouched)
		m.reset <= 1;
		@(posedge clk);
		m.reset <= 0;
		$monitor("OUT ", out_reg);

		for (integer i=0; i<50000; i=i+1) begin
			//if (m.micro_counter == 0)
			//$display("%b  bus[%d]  a[%d]  b[%d]  out[%d]  pc[%d]  instr[%h:%h]  mc[%d]  micro[%b] z=%b c=%b", m.clk, m.bus, m.a.value, m.b.value, m.out.value, m.pc.value, m.instr.value[7:4], m.instr.value[3:0], m.micro_counter, m.micro, m.last_zero, m.last_carry);
			if (halted) $finish();
			@(posedge clk);
		end
		$finish();
	end
endmodule
