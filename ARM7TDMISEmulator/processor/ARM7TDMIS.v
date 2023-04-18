module Arm();
`define WIDTH 31
`define MEMSIZE 3000000

   reg [7:0] MEM [0:`MEMSIZE]; //Simulated Ram for this processor
   

//Conditional codes
`define EQ 4'b0000
`define NE 4'b0001
`define CS 4'b0010
`define CC 4'b0011
`define MI 4'b0100
`define PL 4'b0101
`define VS 4'b0110
`define VC 4'b0111
`define HI 4'b1000
`define LS 4'b1001
`define GE 4'b1010
`define LT 4'b1011
`define GT 4'b1100
`define LE 4'b1101
`define AL 4'b1110

   //OpType
`define STOP 32'b00000110000000000000000000010000 //32
`define BX 32'bzzzz000100101111111111110001zzzz //24
`define MRS 32'bzzzz00010z001111zzzz000000000000 //23
`define MSR1 32'bzzzz00010z101001111100000000zzzz //23
`define SWP 32'bzzzz00010z00zzzzzzzz00001001zzzz //15
`define MSR2 32'bzzzz00z10z1010001111zzzzzzzzzzzz //14
`define MULMLA 32'bzzzz000000zzzzzzzzzzzzzz1001zzzz //10
`define MULLMLAL 32'bzzzz00001zzzzzzzzzzzzzzz1001zzzz //9
`define LDRHSTRHLDRSBLDRSH 32'bzzzz000zz0zzzzzzzzzzzzzz1zz1zzzz //6
`define SWI 32'bzzzz1111zz0zzzzzzzzzzzzzzzzzzzzz //4
`define BBL 32'bzzzz101zzzzzzzzzzzzzzzzzzzzzzzzz //3
`define LDMSTM 32'bzzzz100zzzzzzzzzzzzzzzzzzzzzzzzz //3
`define DATAPROC 32'bzzzz00zzzzzzzzzzzzzzzzzzzzzzzzzz //2
`define LDRSTR 32'bzzzz01zzzzzzzzzzzzzzzzzzzzzzzzzz //2

   //Registers
   reg [`WIDTH:0] R[0:16]; //General Purpouse

   //old register allocations

   /* 
    reg [WIDTH:0] R0; //general purpouse
    reg [WIDTH:0] R1; //general purpouse
    reg [WIDTH:0] R1; //General Purpouse
    reg [WIDTH:0] R2; //General Purpouse
    reg [WIDTH:0] R3; //General Purpouse
    reg [WIDTH:0] R4; //General Purpouse
    reg [WIDTH:0] R5; //General Purpouse
    reg [WIDTH:0] R6; //General Purpouse
    reg [WIDTH:0] R7; //Holds SysCall Number
    reg [WIDTH:0] R8; //General Purpouse
    reg [WIDTH:0] R9; //General Purpouse
    reg [WIDTH:0] R10;//General Purpouse
    reg [WIDTH:0] R11;//General Purpouse
    reg [WIDTH:0] R12;//Intra Procedure Call
    reg [WIDTH:0] R13;//Stack Pointer
    reg [WIDTH:0] R14;//Link Register
    reg [WIDTH:0] R15;//Program Counter
   */
   
   //hidden registers
   reg [`WIDTH:0] INSTR;

   integer 	  InstructionCode;

   task loadProgram;
      input [31:0] address;
      integer 	   status, handler;
      reg [31:0]   binaryLine;
      begin
	  $setRegister(15, address); // initialize stack pointer to address 0
	  handler = $fopen("default", "r");
	  while(!$feof(handler)) begin
	    status = $fscanf(handler,"%b\n",binaryLine); //scan next line as binary
		$setMemory($getRegister("R15"), binaryLine[31:24]);
		$setMemory($getRegister("R15") + 1, binaryLine[23:16]);
		$setMemory($getRegister("R15") + 2, binaryLine[15:8]);
		$setMemory($getRegister("R15") + 3, binaryLine[7:0]);
		$setRegister("R15", $getRegister("R15") + 4); //incriment program counter
	  end
	  $fclose(handler); //close handler
	  $setRegister("R15", address); //set the program counter back to the beginning
      end
   endtask //loadProgram

   function reg [`WIDTH:0] fetch;
      input reg [`WIDTH:0] addr;
      reg [`WIDTH:0] 	   store;
      begin
	 	store[31:24] = $getMemory(addr); //get memory from gui in specified addresses
	 	store[23:16] = $getMemory(addr + 1);
	 	store[15:8] = $getMemory(addr + 2);
	 	store[7:0] = $getMemory(addr + 3);
	 	fetch = store; //return from function
      end
   endfunction // fetch

    /*
    task displayMemory;
    	integer   index;
    	begin
    	  for(index = 0; index < `MEMSIZE; index = index + 1)
    	    $display("memory[%d] = %b", index, MEM[index]);
      	end
    endtask // readmemory
    */
   
   function integer decode;
      input reg [`WIDTH:0] instruction;
      begin
	 casez(instruction)
	   `STOP : decode = 28;
	   `BX : decode = 0;
	   `MRS : decode = 18;
	   `MSR2 : decode = 20;
	   `SWP : decode = 26;
	   `MSR1 : decode = 19;
	   `MULMLA : decode = 21;
	   `MULLMLAL : decode = 22;
	   `LDRHSTRHLDRSBLDRSH : decode = 24;
	   `SWI : decode = 27;
	   `BBL : decode = 1;
	   `LDMSTM : decode = 25;
	   `DATAPROC: decode = instruction[24:21] + 2; // 2 to 17
	   `LDRSTR : decode = 23;
	   default: begin
	      $display("Error: Unidentified intsruction when decoding instruction %d\n", instruction);
	      $finish;
	      decode = -1;
	   end
	 endcase // casez ()
      end
   endfunction // fetch

   function checkCC;
      input [3:0] codecc;
      begin
	 case(codecc)
	   `EQ : checkCC = $getStatus("Z");
	   `NE : checkCC = ~$getStatus("Z");
	   `CS : checkCC = $getStatus("C");
	   `CC : checkCC = ~$getStatus("C");
	   `MI : checkCC = $getStatus("N");
	   `PL : checkCC = ~$getStatus("N");
	   `VS : checkCC = $getStatus("V");
	   `VC : checkCC = ~$getStatus("V");
	   `HI : checkCC = $getStatus("C") & ~$getStatus("Z");
	   `LS : checkCC = ~$getStatus("C") & $getStatus("Z");
	   `GE : checkCC = $getStatus("N") == $getStatus("V");
	   `LT : checkCC = $getStatus("N") != $getStatus("V");
	   `GT : checkCC = ~$getStatus("Z") & ($getStatus("N") == $getStatus("V"));
	   `LE : checkCC = $getStatus("Z") | ($getStatus("N") != $getStatus("V"));
	   `AL : checkCC = 1; //allways exec
	   default: begin
	      $display("Error: Unidentified intsruction when checkingCC %d\n", codecc);
	      $finish;
	      checkCC = -1;
	   end
	 endcase // case (code)
      end
   endfunction // checkCC
   

   task incriment;
      $setRegister("R15", $getRegister("R15") + 4); //incriment program counter by 4 bytes
   endtask // incriment

   task execute;
      input [31:0] code;
      reg [31:0]   op1;
      reg [31:0]   op2;
      reg [31:0]   copy;
      reg [31:0]   dest;
      reg [31:0]   offset;
      reg [32:0]   solution32;
      reg [64:0]   solution64;
      reg [31:0]   address;
      reg [31:0]   totalholder;
      reg [15:0]   regList;
      integer 	   i;
      if(checkCC(INSTR[31:28])) begin
		case(code)
	  		0: $setRegister("R15", $getRegister(INSTR[3:0])); //BX or BE
	  		1: begin //BL | B
	     		if(INSTR[24]) //check if Link bit is set
	       			$setRegister(14, $getRegister(15));
	     		$setRegister(15,  INSTR[23:0]);
	  		end
	  		2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17: begin //AND Instruction
	     		op1 = $getRegister(INSTR[19:16]);
	     		if(INSTR[25]) begin //Operand 2 is immediate and rotated
					op2 = INSTR[7:0];
					for(i=0; i <= `WIDTH; i = i + 1)
		  				copy[i] = op2[(i + INSTR[11:8] * 2) % (`WIDTH+1)];
					op2 = copy;
	     		end else begin //Operand 2 is shifted
					op2 = $getRegister(INSTR[3:0]);
					if(INSTR[4]) //shift is stored in register value
		  				case(INSTR[6:5])
		    				2'b00: op2 = op2 << ($getRegister(INSTR[11:8]) & 8'b11111111); //Logical left
		    				2'b01: op2 = op2 >> ($getRegister(INSTR[11:8]) & 8'b11111111); //Logical right
		    				2'b10: begin 
		       					op2 = op2 >> ($getRegister(INSTR[11:8]) & 8'b11111111);
		       					if(op2[`WIDTH] == 1)
			 						op2 = op2 | (((1 << ($getRegister(INSTR[11:8]) & 8'b11111111)) - 1) << (`WIDTH + 1 - ($getRegister(INSTR[11:8]) & 8'b11111111))); //Arithmetic Right						
		    				end							 
		    				2'b11: begin
		       					for(i = 0; i <= `WIDTH; i = i + 1)
			 						copy[i] = op2[(i + ($getRegister(INSTR[11:8]) & 8'b11111111)) % (`WIDTH+1)]; //Rotate Right
		       					op2 = copy;
		    				end
		  				endcase
					else //shift is immediate
		  				case(INSTR[6:5])
		    				2'b00: op2 = op2 << INSTR[11:7]; //Logical left
		    				2'b01: op2 = op2 >> INSTR[11:7]; //Logical right
		    				2'b10: begin //Arithmetic right
		       					op2 = op2 >> INSTR[11:7];
		       					if(op2[`WIDTH]) //Aritmetic right
			 						op2 = op2 | (((1 << INSTR[11:7]) - 1) << (`WIDTH + 1 - INSTR[11:7]));
		    					end
		    				2'b11: begin
		       					for(i=0; i <= `WIDTH; i = i + 1)
			 						copy[i] = op2[((i + INSTR[11:7]) % (`WIDTH + 1))]; //Rotate Right
		       					op2 = copy;
		    				end
		  				endcase
	     			end // else
	     
	     		case(code) //perform the specified operation
	       			2, 10: solution32 = op1 & op2;
	       			3, 11: solution32 = op1 ^ op2;
	       			4, 12: solution32 = op1 - op2;
	       			5: solution32 = op2 - op1;
	       			6, 13: solution32 = op1 + op2;
	       			7: solution32 = op1 + op2 + $getStatus("C");
	       			8: solution32 = op1 - op2 + $getStatus("C") - 1;
	       			9: solution32 = op2 - op1 + $getStatus("C") - 1;
	       			14: solution32 = op1 | op2;
	       			15: solution32 = op2;
	       			16: solution32 = op1 & ~op2;
	       			17: solution32 = ~op2;
	     		endcase // case (code)
	     
	     		if(INSTR[20]) begin //set the status bits if necessary
					$setStatus("C", solution32[32]);
					$setStatus("Z", !solution32);
					$setStatus("N", solution32[31]);
            		$setStatus("V", (solution32[31] & ~op1[`WIDTH] & ~op2[`WIDTH]) | (~solution32[31] & op1[`WIDTH] & op2[`WIDTH]));
	     		end

				//If the instruction wants a result return it
	     		if(code >= 2 && code <= 9 || code >= 10 && code <= 17) begin 
	       			$setRegister(INSTR[15:12], solution32[31:0]);
				end
	  		end
	  		18: begin //MRS Instruction
	     			if(INSTR[22]) begin 
						$display("Error: there is no SPSR on this machine");
						$finish;	
	     			end
	     		$setRegister(INSTR[15:12], $getRegister(42)); //CSPR = register 42 
	  		end 
	  		19:  begin //MSR1 Instruction
	     		 	if(INSTR[22]) begin 
						$display("Error: there is no SPSR on this machine");
						$finish;	
	     			end
	     			$setRegister(42, $getRegister(INSTR[3:0]));
	  		end  
	  		20: begin //MSR2 Instruction
	     			if(INSTR[22]) begin
						$display("Error: there is no SPSR on this machine");
						$finish;	
	     			end

	     			if(INSTR[11:4] == 0)
	       				$setRegister(42, $getRegister(INSTR[3:0]));
	     			else begin
						$setRegister(42, INSTR[7:0]); //sign extend the value to 32 bits inside the CSPR register
					
						for(i = 0; i <= `WIDTH; i = i + 1)
		  					//copy = CSPR[(i + (INSTR[11:8] * 2)) % (`WIDTH+1)]; //not implemented yet
							CSPR = copy;
	     			end
          	end
	  		21: begin //MUL | MLA Instruction
	     		op1 = $getRegister(INSTR[3:0]);
	     		op2 = $getRegister(INSTR[11:8]);
	     		solution32 = op1 * op2;
	     		if(INSTR[21])
	       			solution32 = solution32 + $getRegister(INSTR[15:12]);
	     
	     		if(INSTR[20]) begin
					$setStatus("C", solution32[32]);
					$setStatus("Z", solution32 == 0 ? 1 : 0);
					$setStatus("N", solution32[`WIDTH] == 1 ? 1 : 0);
					$setStatus("V", (solution32[`WIDTH] & ~op1[`WIDTH] & ~op2[`WIDTH]) | (~solution32[`WIDTH] & op1[`WIDTH] & op2[`WIDTH]));
	    		end
	  		end
	  		22: begin //MULL | MLAL
	     		op1 = $getRegister(INSTR[3:0]); //first op
	     		op2 = $getRegister(INSTR[11:8]); //second opp
	     		solution64 = op1 * op2;
	     		if(INSTR[21]) //is there a add in this instruction
	       			solution64 = solution64 + {R[INSTR[19:16]], R[INSTR[15:12]]};

            	if(INSTR[20]) begin
					$setStatus("C", solution64[64]);
					$setStatus("Z", (solution64 == 0) ? 1 : 0);
					$setStatus("N", (solution64[63] == 1) ? 1 : 0);
					$setStatus("V", (solution64[63] & ~op1[`WIDTH] & ~op2[`WIDTH]) | (~solution64[63] & op1[`WIDTH] & op2[`WIDTH]));
            	end
	     		if(INSTR[19:16] != INSTR[15:12] && INSTR[19:16] != 15 && INSTR[15:12] != 15) begin
					R[INSTR[19:16]] = solution64[63:32];
					R[INSTR[15:12]] = solution64[31:0];
	     		end
	  		end 
	  		23: begin //LDR | STR
	     			if(INSTR[25])
	       				if(INSTR[4])
		 					case(INSTR[6:5])
		   						2'b00: offset = $getRegister(INSTR[3:0]) << ($getRegister(INSTR[11:8]) & 8'b11111111); //Logical left
		   						2'b01: offset = $getRegister(INSTR[3:0]) >> ($getRegister(INSTR[11:8]) & 8'b11111111); //Logical right
		   						2'b10: begin 
		      						offset = $getRegister(INSTR[3:0]) >> ($getRegister(INSTR[11:8]) & 8'b11111111);
		      						if(offset[`WIDTH] == 1)
										offset = offset | (((1 << ($getRegister(INSTR[11:8]) & 8'b11111111)) - 1) << (`WIDTH + 1 - ($getRegister(INSTR[11:8]) & 8'b11111111))); //Arithmetic Right						
		   						end							 
		   						2'b11: begin
		      						offset = $getRegister(INSTR[3:0]);
		      						for(i = 0; i <= `WIDTH; i = i + 1)
										copy[i] = offset[(i + ($getRegister(INSTR[11:8]) & 8'b11111111)) % (`WIDTH+1)]; //Rotate Right
		      							offset = copy;
		   						end
		 					endcase // case (INSTR[6:5])
	       				else
		 					case(INSTR[6:5])
		   						2'b00: offset = $getRegister(INSTR[3:0]) << INSTR[11:7]; //Logical left
		   						2'b01: offset = $getRegister(INSTR[3:0]) >> INSTR[11:7]; //Logical right
		   						2'b10: begin 
		      						offset = $getRegister(INSTR[3:0]) >> INSTR[11:7];
		      						if(offset[`WIDTH] == 1)
										offset = offset | ((1 << (INSTR[11:7]) - 1) << (`WIDTH + 1 - INSTR[11:7])); //Arithmetic Right						
		   							end							 
		   						2'b11: begin
		      						offset = $getRegister(INSTR[3:0]);
		      						for(i = 0; i <= `WIDTH; i = i + 1)
										copy[i] = offset[(i + (INSTR[11:7])) % (`WIDTH+1)]; //Rotate Right
		      							offset = copy;
		   						end
		 					endcase // case (INSTR[6:5])
	     				else
	       					offset = INSTR[11:0]; //immediate
	     				if(INSTR[24])//Pre indexed
	       					if(INSTR[23]) //up or down
		 						address = $getRegister(INSTR[19:16]) + offset;	        
	       					else
		 						address = $getRegister(INSTR[19:16]) - offset;
	     				else
	       					address = $getRegister(INSTR[19:16]);

	     				if(INSTR[21])//Write back enabled
	       					$setRegister(INSTR[19:16], address);
	     
	     			if(INSTR[20])// load
	       				if(INSTR[22]) begin //In byte mode
		  					$setRegister(INSTR[15:12], $getMemory(address));
	       				end else begin //In half word mode
		  					totalholder[15:8] = $getMemory(address);
		  					totalholder[7:0] = $getMemory(address + 1);
		  					$setRegister(INSTR[15:12], totalholder);
	       				end
	     			else //store
	       				if(INSTR[22])begin //In byte mode
		  					op2 = $getRegister(INSTR[15:12]);
		  					$setMemory(address, $getRegister(INSTR[15:12]) & 8'b11111111);
	       				end else begin //In word mode
		  					totalholder[31:24] =($getRegister(INSTR[15:12]) >> 24) & 8'b11111111;
		  					totalholder[23:16] = ($getRegister(INSTR[15:12]) >> 16) & 8'b11111111;
		  					totalholder[15:8] = ($getRegister(INSTR[15:12]) >> 8) & 8'b11111111;
		  					totalholder[7:0] = ($getRegister(INSTR[15:12]) & 8'b11111111);
		  					$setMemory(address, totalHolder);
	       				end
	     			
					if(!INSTR[24])//Post Indexed
	       				if(INSTR[23])//U bit
		 					$setRegister(INSTR[19:16], $getRegister(INSTR[19:16]) + offset);	        
	       				else
		 					$setRegister(INSTR[19:16], $getRegister(INSTR[19:16]) - offset); 
	  		end // case: 23
	  		24: begin //LDRH | STRH | LDRSB | LDRSH
	  			if(INSTR[11:8] == 0)
	       			offset = $getMemory(INSTR[3:0]); //register offset
	     		else
	       			offset = {INSTR[11:8],INSTR[3:0]}; //immediate
	     
	    		if(INSTR[24])// Pre indexed
	       			if(INSTR[23])//Add of subtract offset
		 				address = $getMemory(INSTR[19:16]) + offset;	        
	       			else
		 				address = $getMemory(INSTR[19:16]) - offset;
	     		else
	       			address = $getMemory(INSTR[19:16]);

	     		if(INSTR[21])
	       			$setRegister(INSTR[19:16], address);
	     
	     		if(INSTR[20])// load
	       			case(INSTR[6:5])
		 				2'b00: begin //SWP instruction
		    				op1 = $getMemory(address);
		    				op2 = $getRegister(INSTR[15:12]);
		    				$setMemory(address, op2);
		    				$setRegister(INSTR[15:12], op1);
		 				end
		 				2'b01: begin //Unsigned Halfwords
		    				totalholder[15:8] = $getMemory(address);
		    				totalholder[7:0] = $getMemory(address + 1);
		    				$setRegister(INSTR[15:12], totalholder);
		 				end
		 				2'b10: begin //Signed Bytes
		    				$setRegister(INSTR[15:12], $getMemory(address));
		    				if($getRegister(INSTR[15:12]) & 8'b10000000)
		      					$setRegister(INSTR[15:12], $getRegister(INSTR[15:12]) | 32'b11111111111111111111111100000000);
		 				end
		 				2'b11: begin //Signed Halfwords
		    				totalholder[15:8] = $getMemory(address);
		    				totalholder[7:0] = $getMemory(address + 1);
		    				$setRegister(INSTR[15:12], totalholder);
		    				if($getRegister(INSTR[15:12]) & 16'b1000000000000000)
		      					$setRegister(INSTR[15:12], $getRegister(INSTR[15:12]) | 32'b11111111111111110000000000000000);   
		 				end
	       			endcase // case (INSTR[6:5])
	     		else //store
	       			case(INSTR[6:5])
		 				2'b00: begin //SWP
							op1 = $getMemory(address);
							op2 = $getRegister(INSTR[15:12]);
							$setMemory(address, op2);
							$setRegister(INSTR[15:12], op1);
		 				end
		 				2'b01: begin //Unsigned Halfwords
		    				$setMemory(address, ($getRegister(INSTR[15:12]) >> 8) & 8'b11111111);
		    				$setMemory(address + 1, $getRegister(INSTR[15:12]) & 8'b11111111);
		 				end
		 				2'b10: begin //Signed Bytes
		    				$setMemory(address, $getRegister(INSTR[15:12]) & 8'b11111111);
		 				end
		 				2'b11: begin //Signed Halfwords
		    				$setMemory(address, ($getRegister(INSTR[15:12]) >> 8) & 8'b11111111);
		    				$setMemory(address + 1, $getRegister(INSTR[15:12]) & 8'b11111111);
		 				end
	       			endcase // case (INSTR[6:5])

	     		if(!INSTR[24])//post indexed
	       			if(INSTR[23]) //Ubit offset
		 				$setRegister(INSTR[19:16], $getRegister(INSTR[19:16]) + offset);	        
	       			else
		 				$setRegister(INSTR[19:16], $getRegister(INSTR[19:16]) - offset);
	  		end // case: 24
	  		25: begin //LDM | STM
				address = $getRegister(INSTR[19:16]);
	     		regList = INSTR[15:0];

	     		if(INSTR[20]) begin //load
					if(INSTR[23]) begin //up or down (up)
		   				if(INSTR[24]) //pre indexing
		     				address = address + 4;
		   
		   				for(i = 0; i < 16; i = i + 1)
		     				if(regList[i] == 1) begin
								R[i] = MEM[address];
								address = address + 4;
		     				end
		  			end else begin 
		   				if(INSTR[24])
		     				address = address - 4;
		   
		   				for(i = 15; i >= 0; i = i - 1)
		     				if(regList[i] == 1) begin
								$setRegister(i, $getMemory(address));
								address = address - 4;
		     				end
		  			end // else: !if(INSTR[23])
	  			end else begin //store
		
						if(INSTR[23]) begin
							if(INSTR[24])
								address = address + 4;
				
						for(i = 0; i < 16; i = i + 1)
							if(regList[i] == 1) begin
								$setMemory(address, $getRegister(i));
								address = address + 4;
							end
		   
						end else begin
							if(INSTR[24])
								address = address - 4;
				
							for(i = 15; i >= 0; i = i - 1)
								if(regList[i] == 1) begin
									$setMemory(address, $getRegister(i));
									address = address - 4;
								end
						end // else: !if(INSTR[23])
				end // else: !if(INSTR[20])
	  		end // case: 25
	  		26: begin //data swap
				if(INSTR[22]) begin //swap byte
					address = $getRegister(INSTR[19:16]);
					op1 = $getRegister(address);
					op2 = $getMemory(INSTR[3:0]);
					$setRegister(INSTR[15:12], op1);
					$setmemory(address, op2);
				end else begin //swap word
					address = $getMemory(INSTR[19:16]);
					op1[31:24] = $getMemory(address);
					op1[23:16] = $getmemory(address + 1);
					op1[15:8] = $getMemory(address + 2);
					op1[7:0] = $getMemory(address + 3);
					op2 = $getRegister(INSTR[3:0]);
					$setRegister(INSTR[15:12], op1);
					$setMemory(address, op2);
				end
	  		end // case: 26
	  		27: begin //software interupt
	     		case(INSTR[23:0])
				//0: R[0] = $input;
				1: begin 
					$display("%d\n", $getRegister(0));
				end //displays value in RO
				default: begin
						$display("Error: invalid interupt vector number");
						$finish;
				end
				endcase // case (INSTR[])
			end // case: 27

			28: begin //stop
				$display("Program executed succesfully!!!");
				$finish;
			end // case: 28

			default: begin
				$display("Unknown Instruction with opcode: ", code);
				$finish;
			end
		endcase // case (code)
	   end
   endtask // execute

   initial begin
      loadProgram(0); //load program at memory location 0 and set the stack pointer to the top of the program after loading
      while(InstructionCode != 28 && $getRegister(15) < `MEMSIZE) begin
	 	INSTR = fetch($getRegister(15)); //old Fetch
	 	InstructionCode = decode(INSTR);
	 	incriment; //increment the program counter by a word or 4 bytes
	 	execute(InstructionCode);
      end
   end
   
endmodule // Arm
