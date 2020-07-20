/*
Load a number 85 which was already stored in memory location 120 , 
we add 45 to it and store the result in memory location 121.
The Steps 
   -- Initialize register R1 with the memory address 120.
   -- Load the contents of memory location 120 into register R2.
   -- Add 45 to register R2
   -- Store the result in memory location 121

   Assembly language Program            Machine Language code(Binary)    HEX Equivalent
   ADDI R1, R0, 120                 001010 00000 00001 0000000001111000    28010078
   LW R2,0(R1)                      001000 00001 00010 0000000000000000    20220000
   ADDI R2, R2, 45                  001010 00010 00010 0000000000101101    2842002D
   SW R2, 1(R1)                     001001 00001 00010 0000000000000001    24410001
   HLT                              111111 00000 00000 00000 00000 000000  FC000000
*/
module RISCTB2();

reg clk1, clk2;
integer k;

pipe_RISC16bit RISC16bit(clk1, clk2);

initial 
	begin
		clk1 =0 ; clk2 = 0;
		repeat(40)
			begin
				#5 clk1 = 1; #5 clk1 = 0;  // Generating two phase clock
				#5 clk2 = 1; #5 clk2 = 0;
			end
		end
initial 
	begin
		for(k=0; k<31; k=k+1)
     			RISC16bit.Reg[k] = k;
		
		RISC16bit.Mem[0] = 32'h28010078; //ADDI R1, R0, 120
        RISC16bit.Mem[1] = 32'h0c631800; //OR R3, R3, R3//Dummy Instruction to prevent data hazard
		RISC16bit.Mem[2] = 32'h20220000; // LW R2,0(R1) 
        RISC16bit.Mem[3] = 32'h0c631800; //OR R3, R3, R3//Dummy Instruction to prevent data hazard
		RISC16bit.Mem[4] = 32'h2842002d; //ADDI R2, R2, 45 
		RISC16bit.Mem[5] = 32'h0c631800; //OR R3, R3, R3//Dummy Instruction to prevent data hazard
		RISC16bit.Mem[6] = 32'h24220001; //SW R2, 1(R1)
		RISC16bit.Mem[7] = 32'hfc000000; //HLT
		
        RISC16bit.Mem[120] = 85;  // Load a number 85 in memory location 120
        RISC16bit.HALTED = 0;
		RISC16bit.PC = 0;
		RISC16bit.TAKEN_BRANCH = 0;

		
		#500
		$display("Mem[120] = %4d\nMem[121] = %4d",RISC16bit.Mem[120],RISC16bit.Mem[121]);
	end
initial
	begin
		$dumpfile("RISC16bitTB1waveform.vcd");
		$dumpvars(0, RISCTB2);
		#1000 $finish;
	end
endmodule