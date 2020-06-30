module pipe_MIPS32(clk1 , clk2); // we use a two phase clock to reduce data hazard.

input clk1 , clk2;   // Two Phase Clock.

// Intemediate registers and latches between pipeline stages.
/* IF = Instruction Fetch stage
   ID = Instruction Decode stage. Here the instructions are given their respective opcode
   EX = Execute Instructions stage
   MEM = fetched into memory. After the type is decoded then depending on the type of execution the me   registers are alloted.
   WB = Register write back stage.
*/
reg [31:0]PC , IF_ID_IR, IF_ID_NPC;  //PC:-  Program Counter , NPC:- New Program Counter 
reg [31:0]ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_IMM; //After the opcode is decoded in the ID stage then the type of instructions is set.
reg [2:0]ID_EX_type, EX_MEM_type, MEM_WB_type; 
reg [31:0]EX_MEM_IR, EX_MEM_ALUOUT, EX_MEM_B;
reg EX_MEM_condition; // Required for Branch or Jump condition checking.
reg [31:0]MEM_WB_IR, MEM_WB_ALUOUT, MEM_WB_LMD;
   
reg [31:0]Reg[0:31];  // Register Bank (32X32) memory.
reg [31:0]Mem[0:1023];  //Memory Storage (1024X32) memory.

//Opcode Definitions . Not really necessary just to increase the readabilty of the codes.

parameter ADD  = 6'b000000,
	  SUB  = 6'b000001,
	  AND  = 6'b000010,
	  OR   = 6'b000011,
	  SLT  = 6'b000100, // Set Less Than
	  MUL  = 6'b000101,
	  HLT  = 6'b111111, // Halt Operations. Stop Program Execution.
	  LW   = 6'b001000,
	  SW   = 6'b001001,
   	  ADDI = 6'b001010, // Add Immediate
	  SUBI = 6'b001011, // Sub Immediate
	  SLTI = 6'b001100,
	  BNEQZ = 6'b001101, // Conditional Operator, Branch Not Equal To
	  BEQZ = 6'b001110; // Conditional Operator, Branch Equal To

// The Type of instructions. Means the type of instructions executing in the final pipeline
parameter RR_ALU = 3'b000, 
	  RM_ALU = 3'b001, 
	  LOAD = 3'b010, 
    	  STORE = 3'b011, 
 	  BRANCH = 3'b100, 
	  HALT = 3'b101;

reg HALTED; // Meaning the executions are done. Done only in WB stage.
reg TAKEN_BRANCH; // The conditional statements are executed. And all the other writes will be disabled while this flag is high. So that the conditional statements are executed.

// The INSTRUCTION FETCH STAGE.
always @(posedge clk1) 
	if (HALTED == 0)// If the HALTED signal is set high then there is no further need of fetching any instructions.So we begin only when the HALTED flag is not set high.
	begin
		if (((EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_condition == 1)) || ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_condition == 0)))// Bit Number 26 to 31 has the opcodes so we compare the opcodes to see if the conditions are branch conditions or not. If the register content is zero then EX_MEM_condition is set 1 and vice versa
 		begin
			IF_ID_IR     <= Mem[EX_MEM_ALUOUT];// The address of the next instruction is calculated and stored in the the EX_MEM_ALUOUT rather than the NPC in case of branch instruction so the address stored in that register is moved in IF_ID_IR latch.
			TAKEN_BRANCH <= 1'b1; //Taken Branch is 1 indicating that the conditional statements is executing
			IF_ID_NPC    <= EX_MEM_ALUOUT + 1;
			PC           <= EX_MEM_ALUOUT + 1;
		end
		else // Branch is not taken then normal instruction stage
		begin
				IF_ID_IR  <= Mem[PC];
				IF_ID_NPC <= PC + 1;
				PC        <= PC + 1;
		end
	end

// The INSTRUCTION DECODE stage
/*Here we are doing three things 
  1. We are decoding the opcodes implied by the case statements 
  2. We are prefetching the two source registers. Register A and B which we use for normal executions. The prefetching is done until in the EX stage we come to know whether the second register is used or not 
 3. We are sign extending the sixteen bit offset.
*/
	always @(posedge clk2)
	if (HALTED == 0)
	begin
		if (IF_ID_IR[25:21] == 5'b00000) // Check if the first register is the default register 
		begin
			ID_EX_A <= 0;   // If it is the default register then assign 0 to the reg A
		end
		else
		begin
			ID_EX_A <= Reg[IF_ID_IR[25:21]];   // rs resgister
		end

		if(IF_ID_IR[20:16] == 5'b00000)  // Check if the 2nd register is the default register 
		begin
			ID_EX_B <= 0;  // if it is then assign ) to reg B
		end
		else
		begin
			ID_EX_B <= Reg[IF_ID_IR[20:16]];   // rt register
		end
		
		ID_EX_NPC <= IF_ID_NPC; // No change in NPC as PC is incremented only on the IF stage 
		ID_EX_IR <= IF_ID_IR; // The register values are also carried to the next stage.
		ID_EX_IMM <= {{16{IF_ID_IR[15]}}, {IF_ID_IR[15:0]}}; // sign extension. The signed bit is replicated 16 times and replicated. This is a unique feature of  2's compliment saving method
		
		// The opcodes decoding 
		case (IF_ID_IR[31:26])
			ADD,SUB,AND,OR,SLT,MUL:   ID_EX_type <= RR_ALU;
			ADDI,SUBI, SLTI:          ID_EX_type <= RM_ALU;
			LW:			  ID_EX_type <= LOAD;
			SW:			  ID_EX_type <= STORE;
			BNEQZ, BEQZ:   		  ID_EX_type <= BRANCH;
			HLT: 			  ID_EX_type <= HALT;
			default: 		  ID_EX_type <= HALT; // Invalid opcode.
		endcase
	end	

// The EX stage . The statements are executed in this stage. Only in this stage we come to know whether the branch statements are allowed to execute or not. 		
always @(posedge clk1)
	if (HALTED == 0)
	begin
		EX_MEM_type  <= ID_EX_type;
		EX_MEM_IR    <= ID_EX_IR;
		TAKEN_BRANCH <= 0;  // The taken branch which was set to one in the first stage is now set to zero as soon after the conditional statements are executed. Then the remaining statements are executed
		
		case (ID_EX_type)
			RR_ALU:  // Register to Register ALU
				begin
					case (ID_EX_IR[31:26])  //opcode
						ADD:  EX_MEM_ALUOUT <= ID_EX_A + ID_EX_B;
						SUB:  EX_MEM_ALUOUT <= ID_EX_A - ID_EX_B;
						AND:  EX_MEM_ALUOUT <= ID_EX_A & ID_EX_B;
						OR :  EX_MEM_ALUOUT <= ID_EX_A | ID_EX_B;
						SLT:  EX_MEM_ALUOUT <= ID_EX_A < ID_EX_B;
						MUL:  EX_MEM_ALUOUT <= ID_EX_A * ID_EX_B;
						default: EX_MEM_ALUOUT <= 32'hxxxxxxxx; // Invalid opcode.
			      		endcase
				end

			RM_ALU:
				begin
					case (ID_EX_IR[31:26])  //opcode
							
						ADDI:  EX_MEM_ALUOUT <= ID_EX_A + ID_EX_IMM;
						SUBI:  EX_MEM_ALUOUT <= ID_EX_A - ID_EX_IMM;
 						SLTI:  EX_MEM_ALUOUT <= ID_EX_A < ID_EX_IMM;
						default: EX_MEM_ALUOUT <= 32'hxxxxxxxx;
					endcase
				end
		
			LOAD, STORE:
				begin
					EX_MEM_ALUOUT <= ID_EX_A + ID_EX_IMM;
					EX_MEM_ALUOUT <= ID_EX_B;
				end
		
			BRANCH:
				begin
					EX_MEM_ALUOUT <= ID_EX_NPC + ID_EX_IMM; // The next address is evaluated here which is to be taken if the branch is taken. 
					EX_MEM_condition <= (ID_EX_A == 0); // Evaluating the condition
				end
		endcase
	end

 //The MEM stage. Here the values are written in the Memory.

always @(posedge clk2)
	if (HALTED == 0)
	begin
		MEM_WB_type <= EX_MEM_type;
		MEM_WB_IR   <= EX_MEM_IR;
		
		case (EX_MEM_type)
			RR_ALU , RM_ALU:
				MEM_WB_ALUOUT <= EX_MEM_ALUOUT;
			LOAD:
				MEM_WB_LMD    <= Mem[EX_MEM_ALUOUT];
			STORE:
				if (TAKEN_BRANCH == 0)  // Disable Write
				begin
					Mem[EX_MEM_ALUOUT] <= EX_MEM_B;	
				end
		endcase
	end

//The WB stage. Here the results calculated will be stored. The desired results are written back to the register Bank.
always @(posedge clk1)
	begin
		if (TAKEN_BRANCH == 0) // Disable write if Branch is Taken.
		case (MEM_WB_type)
			RR_ALU: Reg[MEM_WB_IR[15:11]]  <= MEM_WB_ALUOUT;
			RM_ALU: Reg[MEM_WB_IR[20:16]]  <= MEM_WB_ALUOUT;
			LOAD:   Reg[MEM_WB_IR[20:16]]  <= MEM_WB_LMD;
			HALT:   HALTED                 <= 1'b1;
		endcase
	end

endmodule
