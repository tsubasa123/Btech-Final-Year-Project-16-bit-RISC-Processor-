/*
Compute the factorial of a number N stored in memory location 200.
The result will be stored in memory loation 198.
The Steps
 -- Initialize register R8 with the memory address 200.
 -- Load the contents of memory location 200 into register R9.
 -- Initialize register R10 with the value 1.
 -- In a loop, multiply R10 and R9, and store the product in R10.
 -- Decrement R9 by 1; if not zero repeat the loop
 -- Store the result (from R9) in memory location 198

 The instruction Set      Machine Code (in Binary)                 Hexadecimal Code        
    ADDI R8, R0, 200        001010 00000 01000 0000000011001000    280800C8
    LW   R9, 0(R8)          001000 01000 01001 0000000000000000    21090000
    ADDI R10, R0, 1         001010 00000 01010 0000000000000001    280A0001
Loop:MUL R10, R10, R9       000101 01010 01001 01010 00000 000000  15495000
     SUBI R9, R9 , 1        001011 01001 01001 0000000000000001    2D290001
     BNEQZ R9, Loop         001101 01001 00000 1111111111111100    3520FFFC
     // Decrement PC by 4 in the above loop end
    SW R10, -2(R8)          001001 01000 01010 1111111111111110    2548FFFE
     HLT                    111111 00000 00000 00000 00000 000000  FC000000
*/

module RISCTB3();

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
        
        RISC16bit.Mem[0] = 32'h280800C8; //ADDI R8, R0, 200
        RISC16bit.Mem[1] = 32'h280a0001; //ADDI R10, R0, 1  
        RISC16bit.Mem[2] = 32'h0c631800; //OR R3, R3, R3//Dummy Instruction to prevent data hazard
		RISC16bit.Mem[3] = 32'h21090000; // LW R9, 0(R8)  
        RISC16bit.Mem[4] = 32'h0c631800; //OR R3, R3, R3//Dummy Instruction to prevent data hazard
		RISC16bit.Mem[5] = 32'h15495000; //Loop:MUL R10, R10, R9 
        RISC16bit.Mem[6] = 32'h2d290001; //SUBI R9, R9 , 1 
		RISC16bit.Mem[7] = 32'h0c631800; //OR R3, R3, R3//Dummy Instruction to prevent data hazard
		RISC16bit.Mem[8] = 32'h3520fffc; //BNEQZ R9, Loop
        RISC16bit.Mem[9] = 32'h250afffe; //SW R10, -2(R8)
		RISC16bit.Mem[10] = 32'hfc000000; //HLT

        RISC16bit.Mem[200] = 7;  // Load a number 85 in memory location 120
        RISC16bit.HALTED = 0;
		RISC16bit.PC = 0;
		RISC16bit.TAKEN_BRANCH = 0;

        #2000
		$display("Mem[200] = %4d\nMem[198] = %4d",RISC16bit.Mem[200],RISC16bit.Mem[198]);

    end    
initial
	begin
		$dumpfile("RISC16bitTB1waveform.vcd");
		$dumpvars(0, RISCTB3);
        $monitor("R10: %4d  R8: %4d",RISC16bit.Reg[10],RISC16bit.Reg[8]);
		#3000 $finish;
	end
endmodule