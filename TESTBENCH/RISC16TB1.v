/* This testbench shows addition of three numbers in this processor.
	Add three numbers 10, 20, 30
	The steps 1) Initialize register R1 with 10.
		  2) Initialize register R2 with 20.
		  3) Initialize register R3 with 30.
		  4) Add the three numbers nd store the sum in R4.
    The instruction set                   Machine Code                  HEX VALUE 
	ADDI R1, R0, 10 		    001010 00000 00001 0000000000001010     2801000A
	ADDI R2, R0, 20 		    001010 00000 00010 0000000000010100     28020014
    ADDI R3, R0, 25			    001010 00000 00011 0000000000011001     28030019 
	ADD  R4, R1, R2             000000 00001 00010 00100 00000 000000   222000
    ADD  R5, R4, R3             000000 00100 00011 00101 00000 000000   832800
*/
module  RISCTB1();

reg clk1, clk2;
integer k;

pipe_RISC16bit RISC16bit(clk1, clk2);

task Initialize;
	begin
		RISC16bit.HALTED = 0;
		RISC16bit.PC = 0;
		RISC16bit.TAKEN_BRANCH = 0;
	end
endtask

always 
	begin
		clk1 =0 ; clk2 = 0;
			begin
				#5 clk1 = 1; #5 clk1 = 0;  // Generating two phase clock
				#5 clk2 = 1; #5 clk2 = 0;
			end
	end

initial 
	begin
		Initialize;
		for(k=0; k<31; k=k+1)
     			RISC16bit.Reg[k] = k;
		
		RISC16bit.Mem[0] = 32'h2801000a; //ADDI R1, R0, 10
		RISC16bit.Mem[1] = 32'h28020014; //ADDI R2, R0, 20
		RISC16bit.Mem[2] = 32'h28030019; //ADDI R3, R0, 25
		RISC16bit.Mem[3] = 32'h0ce77800; //OR R7, R7, R7//Dummy Instruction to prevent data hazard
		RISC16bit.Mem[4] = 32'h0ce77800; //OR R7, R7, R7//Dummy Instruction to prevent data hazard
		RISC16bit.Mem[5] = 32'h00222000; //ADD R4, R1, R2
		RISC16bit.Mem[6] = 32'h0ce77800; //OR R7, R7, R7//Dummy Instruction to prevent data hazards
		RISC16bit.Mem[7] = 32'h00832800; //ADD R5, R4, R3
/*
2nd Part of the program
Load a word which was already stored in memory location 120 , 
we add 45 to it and store the result in memory location 121.
The Steps 
   -- Initialize register R1 with the memory address 120.
   -- Load the contents of memory location 120 into register R2.
   -- Add 45 to register R2
   -- Store the result in memory location 121

   Assembly language Program            Machine Language code(Binary)    HEX Equivalent
   ADDI R6, R0, 120                  001010 00000 00110 0000000001111000    28060078
   LW R7,0(R6)                       001000 00110 00111 0000000000000000    20C70000
   ADDI R7, R7, 45                   001010 00111 00111 0000000000101101    28E7002D
   SW R7, 1(R6)                      001001 00110 00111 0000000000000001    24C70001
   HLT                               111111 00000 00000 00000 00000 000000  FC000000
*/

		RISC16bit.Mem[8] = 32'h28060078; //ADDI R6, R0, 120
        RISC16bit.Mem[9] = 32'h0c631800; //OR R3, R3, R3//Dummy Instruction to prevent data hazard
		RISC16bit.Mem[10] = 32'h20c70000; // LW R7,0(R6) 
        RISC16bit.Mem[11] = 32'h0c631800; //OR R3, R3, R3//Dummy Instruction to prevent data hazard
		RISC16bit.Mem[12] = 32'h28e7002d; //ADDI R7, R7, 45
		RISC16bit.Mem[13] = 32'h0c631800; //OR R3, R3, R3//Dummy Instruction to prevent data hazard
		RISC16bit.Mem[14] = 32'h24c70001; //SW R7, 1(R6)  // Store whatever value is stored in R10 in the memory adrress 1+(Value stored in Reg R9)
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

		RISC16bit.Mem[15] = 32'h280800C8; //ADDI R8, R0, 200
        RISC16bit.Mem[16] = 32'h280a0001; //ADDI R10, R0, 1  
        RISC16bit.Mem[17] = 32'h0c631800; //OR R3, R3, R3//Dummy Instruction to prevent data hazard
		RISC16bit.Mem[18] = 32'h21090000; // LW R9, 0(R8)  
        RISC16bit.Mem[19] = 32'h0c631800; //OR R3, R3, R3//Dummy Instruction to prevent data hazard
		RISC16bit.Mem[20] = 32'h15495000; //Loop:MUL R10, R10, R9 
        RISC16bit.Mem[21] = 32'h2d290001; //SUBI R9, R9 , 1 
		RISC16bit.Mem[22] = 32'h0c631800; //OR R3, R3, R3//Dummy Instruction to prevent data hazard
		RISC16bit.Mem[23] = 32'h3520fffc; //BNEQZ R9, Loop
        RISC16bit.Mem[24] = 32'h250afffe; //SW R10, -2(R8)
		RISC16bit.Mem[25] = 32'hfc000000; //HLT
		
		RISC16bit.Mem[120] = 85;
		RISC16bit.Mem[200] = 7;

		#300
		$display("--------------------------------------------------------------------------");
		$display("The Addition Part");
		$display("--------------------------------------------------------------------------");
		for (k=0; k<6; k=k+1)
			$display($time," R%1d - %2d",k,RISC16bit.Reg[k]);
		$display("\tThe final added sum is %d", RISC16bit.Reg[5]);
		$display("###########################################################################");
		
		#200
		$display("--------------------------------------------------------------------------");
		$display("\tUnloading 45 from Mem[120] adding 45 to it and loading it in Mem[121]");
		$display("--------------------------------------------------------------------------");
		$display("\tThe Number loaded in Memory address 120 is %d", RISC16bit.Mem[120]);
		$display("\tThe Number loaded in Memory address 121 is %d", RISC16bit.Mem[121]);
		$display("###########################################################################");

		$display("--------------------------------------------------------------------------");
		$display("Looping and finding factorial of the number stored in Mem[200]");
		$display("--------------------------------------------------------------------------");
		$display("\tThe Number stored in Mem[200] is %d",RISC16bit.Mem[200]);
		$monitor("\tR10: %4d ",RISC16bit.Reg[10]);
	    #800$display("\tThe factorial of %d is %d",RISC16bit.Mem[200], RISC16bit.Reg[10]);
		$display("###########################################################################");

	end

initial
	begin
		$dumpfile("RISC16bitTB1waveform.vcd");
		$dumpvars(0, RISCTB1);
		#2000 $finish;
	end

endmodule


		
