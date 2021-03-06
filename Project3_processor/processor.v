/**
 * READ THIS DESCRIPTION!
 *
 * The processor takes in several inputs from a skeleton file.
 *
 * Inputs
 * clock: this is the clock for your processor at 50 MHz
 * reset: we should be able to assert a reset to start your pc from 0 (sync or
 * async is fine)
 *
 * Imem: input data from imem
 * Dmem: input data from dmem
 * Regfile: input data from regfile
 *
 * Outputs
 * Imem: output control signals to interface with imem
 * Dmem: output control signals and data to interface with dmem
 * Regfile: output control signals and data to interface with regfile
 *
 * Notes
 *
 * Ultimately, your processor will be tested by subsituting a master skeleton, imem, dmem, so the
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file acts as a small wrapper around your processor for this purpose.
 *
 * You will need to figure out how to instantiate two memory elements, called
 * "syncram," in Quartus: one for imem and one for dmem. Each should take in a
 * 12-bit address and allow for storing a 32-bit value at each address. Each
 * should have a single clock.
 *
 * Each memory element should have a corresponding .mif file that initializes
 * the memory element to certain value on start up. These should be named
 * imem.mif and dmem.mif respectively.
 *
 * Importantly, these .mif files should be placed at the top level, i.e. there
 * should be an imem.mif and a dmem.mif at the same level as process.v. You
 * should figure out how to point your generated imem.v and dmem.v files at
 * these MIF files.
 *
 * imem
 * Inputs:  12-bit address, 1-bit clock enable, and a clock
 * Outputs: 32-bit instruction
 *
 * dmem
 * Inputs:  12-bit address, 1-bit clock, 32-bit data, 1-bit write enable
 * Outputs: 32-bit data at the given address
 *
 */
module processor(
    // Control signals
    clock,                          // I: The master clock
    reset,                          // I: A reset signal

    // Imem
    address_imem,                   // O: The address of the data to get from imem
    q_imem,                         // I: The data from imem

    // Dmem
    address_dmem,                   // O: The address of the data to get or put from/to dmem
    data,                           // O: The data to write to dmem
    wren,                           // O: Write enable for dmem
    q_dmem,                         // I: The data from dmem

    // Regfile
    ctrl_writeEnable,               // O: Write enable for regfile
    ctrl_writeReg,                  // O: Register to write to in regfile
    ctrl_readRegA,                  // O: Register to read from port A of regfile
    ctrl_readRegB,                  // O: Register to read from port B of regfile
    data_writeReg,                  // O: Data to write to for regfile
    data_readRegA,                  // I: Data from port A of regfile
    data_readRegB,                   // I: Data from port B of regfile
);


	 
    // Control signals
    input clock, reset;

    // Imem
    output [11:0] address_imem;
    input [31:0] q_imem;

    // Dmem
    output [11:0] address_dmem;
    output [31:0] data;
    output wren;
    input [31:0] q_dmem;

    // Regfile
    output ctrl_writeEnable;
    output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
    output [31:0] data_writeReg;
    input [31:0] data_readRegA, data_readRegB;
	 
	 
	 
	 
	 
	 
	 
	 
	 

    /* YOUR CODE STARTS HERE */
	 wire ovf, isNotEqual, isLessThan, excep_T, ovf_set;

	 wire [4:0] opcode, ALUopcode, shamt;
	 //pc relevant 
	 wire [11:0] pc_controller_to_pc, pc_out, N_to_pc, T, PC_plus_1, new_PC, rd_to_pc;
	 wire [16:0] imme;
	 wire [31:0] insn, imme_to_ALU, imme_to_data_dmem, alu_result, PC_plus_1_32bit, ovf_data, T_32bit;
	 
	 
	 //control signals begin
	 wire reg_ctrl_jal_en, reg_ctrl_setx_en, reg_ctrl_rd_to_rt_en, reg_rstatus_en, imme_en,
			dmem_wr_en, addi_en, excep_bex_en, excep_ovf_en;
	 wire [2:0] reg_write_selector;
	 wire [2:0] pc_selector; //////////////////////////////////////////////////////////////////////////////////
	 wire pc_ctrl_ilt_neq;
	 //control signals end
	 
	 /////////////////PC/////////////////
	 pc mypc(.clock(clock), .reset(reset), .pc_in(pc_controller_to_pc), .pc_out(pc_out));
	 //12-bit using in a 16-bit adder, cout dead end
	 fa_16 myfa_16(.a(pc_out), .b(16'b1), .cin(0), .sum(PC_plus_1));
	 /////////////////imem/////////////////
	 assign address_imem = pc_out[11:0];
	 assign insn = q_imem;
	 /////////////////dmem/////////////////
	 assign wren = dmem_wr_en;
	 //address_dem is wrote in part of ALU
	 //data is wrote int part of Imme Controller
	 
	 /////////////////Control Signal/////////////////
	 assign opcode = insn[31:27];
	 control_signal myControlSignal(opcode,
											  reg_ctrl_jal_en, reg_ctrl_setx_en, reg_ctrl_rd_to_rt_en, 
											  reg_rstatus_en, ctrl_writeEnable, reg_write_selector,
											  imme_en, dmem_wr_en, 
											  pc_selector, pc_ctrl_ilt_neq, 
											  addi_en,
										     excep_bex_en, excep_ovf_en);
	/////////////////Reg Controller/////////////////
	reg_controller myreg_controller(insn, ovf, reg_ctrl_setx_en, reg_ctrl_jal_en, reg_ctrl_rd_to_rt_en, excep_bex_en,
												ctrl_writeReg, ctrl_readRegB, ctrl_readRegA);
	/////////////////Imme Controller/////////////////
	assign imme = insn[16:0];
	imme_controller myimme_controller(data_readRegB, imme, imme_en, 					//input
												 N_to_pc, imme_to_ALU, imme_to_data_dmem);	//output
	assign data = imme_to_data_dmem;
	/////////////////ALU/////////////////
	assign ALUopcode = addi_en ? 5'b0 : insn[6:2];
	assign shamt = insn[11:7];
	assign address_dmem = alu_result;
	alu myalu(data_readRegA, imme_to_ALU, ALUopcode, shamt, alu_result, isNotEqual, isLessThan, ovf);
	/////////////////PC Controller/////////////////
	
	assign T = insn[11:0];
	assign rd_to_pc = data_readRegA[11:0];
	PC_controller myPC_controller(T, N_to_pc, rd_to_pc, pc_selector, isLessThan, isNotEqual, pc_ctrl_ilt_neq, excep_T, PC_plus_1, //input
											PC_plus_1_32bit, pc_controller_to_pc);																				//output
	/////////////////Exception Controller/////////////////
	excep_controller myexcep_controller(excep_bex_en, excep_ovf_en, isNotEqual, ovf, insn,	//input
													ovf_set, excep_T, ovf_data);								//output		
	/////////////////Mux/////////////////'
	assign T_32bit[26:0] = insn[26:0];
	assign T_32bit[31:27] = 5'b0;
	assign data_writeReg = ovf_set ? ovf_data :
								(~reg_write_selector[2]&~reg_write_selector[1]& reg_write_selector[0])?  PC_plus_1_32bit : 
								(~reg_write_selector[2]& reg_write_selector[1]&~reg_write_selector[0])?  q_dmem :
								(~reg_write_selector[2]& reg_write_selector[1]& reg_write_selector[0])?  alu_result :
								( reg_write_selector[2]&~reg_write_selector[1]&~reg_write_selector[0])?  T_32bit: 32'b0;
	
	
endmodule
