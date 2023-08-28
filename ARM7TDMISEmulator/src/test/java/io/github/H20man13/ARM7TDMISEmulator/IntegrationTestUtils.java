package io.github.H20man13.ARM7TDMISEmulator;

import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.util.List;
import java.util.concurrent.Callable;

import org.antlr.v4.runtime.ANTLRInputStream;
import org.antlr.v4.runtime.CommonTokenStream;
import org.testfx.framework.junit.ApplicationTest;

import edu.depauw.declan.common.Source;
import edu.depauw.declan.common.ast.Program;
import io.github.H20man13.ArmAssembler.AssemblerVisitor;
import io.github.H20man13.ArmAssembler.grammar.ParserLexer;
import io.github.H20man13.ArmAssembler.grammar.ParserParser;
import io.github.H20man13.DeClan.common.IrRegisterGenerator;
import io.github.H20man13.DeClan.common.ReaderSource;
import io.github.H20man13.DeClan.common.icode.ICode;
import io.github.H20man13.DeClan.main.MyCodeGenerator;
import io.github.H20man13.DeClan.main.MyDeClanLexer;
import io.github.H20man13.DeClan.main.MyDeClanParser;
import io.github.H20man13.DeClan.main.MyICodeGenerator;
import io.github.H20man13.DeClan.main.MyIrLexer;
import io.github.H20man13.DeClan.main.MyIrParser;
import io.github.H20man13.DeClan.main.MyOptimizer;
import io.github.H20man13.DeClan.main.MyStandardLibrary;
import io.github.H20man13.emulator_ide.gui.GuiEde;
import io.github.H20man13.emulator_ide.gui.gui_job.GuiJob.TextAreaType;
import io.github.H20man13.emulator_ide.gui.gui_machine.GuiRam;
import io.github.H20man13.emulator_ide.gui.gui_machine.GuiRegister;
import javafx.geometry.Rectangle2D;
import javafx.scene.Scene;
import javafx.stage.Screen;
import javafx.stage.Stage;

/**
 * Unit test for simple App.
 */
public class IntegrationTestUtils extends ApplicationTest{
    private IrRegisterGenerator gen;
    
    public IntegrationTestUtils(){
        gen = new IrRegisterGenerator();
    }
    /**
	 * The following code builds the default ArmTDMI7 machine in java
	 * This is the default machine if no xml Config File is provided 
	 * @param stage
	*/
	private void buildDefaultMachine(Stage stage){
		Screen screen = Screen.getPrimary();
		Rectangle2D bounds = screen.getVisualBounds();

		stage.setX(bounds.getMinX());
		stage.setY(bounds.getMinY());

		stage.setMaxWidth(bounds.getWidth());
		stage.setMaxHeight(bounds.getHeight());
		stage.setWidth(bounds.getWidth());
		stage.setHeight(bounds.getHeight());

		stage.setTitle("ARM7TDMIS Processor");

		int NumberOfBytes = 1000;
		int NumberOfBytesInRow = 4;

		GuiEde EdeInstance = new GuiEde(NumberOfBytes, NumberOfBytesInRow, GuiRam.AddressFormat.DECIMAL, GuiRam.MemoryFormat.HEXADECIMAL, stage.getMaxWidth(), stage.getMaxHeight());

		String[] declanKeywords = new String[]{
			"VAR", "CONST", "PROCEDURE", "BEGIN", "END", "END.", "RETURN", "INTEGER;", "INTEGER"
		};

		EdeInstance.AddJavaJob("Compile DeClan", TextAreaType.KEYWORD, new Callable<Void>() {
			@Override
			public Void call(){
				try {
					FileReader reader = new FileReader("InputDeClan.d");
					Source readerSource = new ReaderSource(reader);
					edu.depauw.declan.common.ErrorLog errorLog = new edu.depauw.declan.common.ErrorLog();
					MyDeClanLexer lexer = new MyDeClanLexer(readerSource, errorLog);
					MyDeClanParser parser = new MyDeClanParser(lexer, errorLog);
					

					Program p = parser.parseProgram();
					MyICodeGenerator generator = new MyICodeGenerator(errorLog, gen);

					MyStandardLibrary stdLib = new MyStandardLibrary(errorLog);
					stdLib.ioLibrary().accept(generator);
					p.accept(generator);

					List<ICode> icode = generator.getICode();

					FileWriter fw = new FileWriter("OutputIr.i");
					for(ICode ic : icode){
						fw.write(ic.toString());
						fw.write('\n');
					}
					fw.close();
				} catch(Exception exp){
					EdeInstance.appendIoText("StandardError", exp.toString());
				}
				return null;
			}
			
		}, "InputDeclan.d", "OutputIr.i", "StandardError", declanKeywords);

		EdeInstance.AddJavaJob("Compile Ir", TextAreaType.DEFAULT, new Callable<Void>() {

			@Override
			public Void call(){
				try{
					// TODO Auto-generated method stub
					FileReader Reader = new FileReader("InputIr.i");
					edu.depauw.declan.common.ErrorLog errorLog = new edu.depauw.declan.common.ErrorLog();
					Source source = new ReaderSource(Reader);
					MyIrLexer lexer = new MyIrLexer(source, errorLog);
					MyIrParser parser = new MyIrParser(lexer, errorLog);
					List<ICode> icode = parser.parseProgram();

					MyOptimizer optimizer = new MyOptimizer(icode, gen);
					optimizer.runDataFlowAnalysis();
					optimizer.performDeadCodeElimination();

					icode = optimizer.getICode();

					MyCodeGenerator codeGen = new MyCodeGenerator(optimizer.getLiveVariableAnalysis(), icode, gen, errorLog);
					FileWriter Writer = new FileWriter(new File("OutputAssembly.a"));
					codeGen.codeGen(Writer);
					Writer.close();
				} catch (Exception exp){
					EdeInstance.appendIoText("StandardError", exp.toString());
				}
				return null;
			}
			
		}, "InputIr.i", "OutputAssembly.a", "StandardError");
		EdeInstance.AddJavaJob("Assemble", TextAreaType.DEFAULT, new Callable<Void>() {
			public Void call(){
				try{
					FileReader Reader = new FileReader("InputAssembly.a");
					ANTLRInputStream byteStream = new ANTLRInputStream(Reader);
					ParserLexer lex = new ParserLexer(byteStream);
					CommonTokenStream tokStream = new CommonTokenStream(lex);
					ParserParser parse = new ParserParser(tokStream);
					io.github.H20man13.ArmAssembler.grammar.ParserParser.ProgramContext ctx = parse.program();
					AssemblerVisitor visitor = new AssemblerVisitor();
					List<Integer> assembledCode = visitor.assembleCode(ctx);

					//Now we just need to write to the Output File
					FileWriter writer = new FileWriter("OutputBinary.bin");
					for(Integer assembledCodeInstr : assembledCode){
						StringBuilder resultBuilder = new StringBuilder();
						String rawBinaryString = Integer.toBinaryString(assembledCodeInstr);
						if(rawBinaryString.length() > 32){
							rawBinaryString = rawBinaryString.substring(rawBinaryString.length() - 32);
						}
						
						if(rawBinaryString.length() < 32){
							for(int i = 0; i < 32 - rawBinaryString.length(); i++){
								resultBuilder.append('0');
							}
							resultBuilder.append(rawBinaryString);
							rawBinaryString = resultBuilder.toString();
						}

						writer.append(rawBinaryString);
						writer.append('\n');
					}
					writer.close();
				} catch(Exception exp){
					EdeInstance.appendIoText("StandardError", exp.toString());
				}
				return null;
			}
		}, "InputAssembly.a", "OutputBinary.bin", "StandardError");

		EdeInstance.AddVerilogJob("Execute", "processor/ARM7TDMIS.v", "default", "StandardInput", "StandardOutput", "StandardError");

		int RegisterLength = 32;
		EdeInstance.AddRegister("CPSR", RegisterLength, GuiRegister.Format.BINARY);
		EdeInstance.AddRegister("R0", RegisterLength, GuiRegister.Format.BINARY);
		EdeInstance.AddRegister("R1", RegisterLength, GuiRegister.Format.BINARY);
		EdeInstance.AddRegister("R2", RegisterLength, GuiRegister.Format.BINARY);
		EdeInstance.AddRegister("R3", RegisterLength, GuiRegister.Format.BINARY);
		EdeInstance.AddRegister("R4", RegisterLength, GuiRegister.Format.BINARY);
		EdeInstance.AddRegister("R5", RegisterLength, GuiRegister.Format.BINARY);
		EdeInstance.AddRegister("R6", RegisterLength, GuiRegister.Format.BINARY);
		EdeInstance.AddRegister("R7", RegisterLength, GuiRegister.Format.BINARY);
		EdeInstance.AddRegister("R8", RegisterLength, GuiRegister.Format.BINARY);
		EdeInstance.AddRegister("R9", RegisterLength, GuiRegister.Format.BINARY);
		EdeInstance.AddRegister("R10", RegisterLength, GuiRegister.Format.BINARY);
		EdeInstance.AddRegister("R11", RegisterLength, GuiRegister.Format.BINARY);
		EdeInstance.AddRegister("R12", RegisterLength, GuiRegister.Format.BINARY);
		EdeInstance.AddRegister("R13", RegisterLength, GuiRegister.Format.BINARY);
		EdeInstance.AddRegister("R14", RegisterLength, GuiRegister.Format.BINARY);
		EdeInstance.AddRegister("R15", RegisterLength, GuiRegister.Format.BINARY);

		EdeInstance.AddFlag("C");
		EdeInstance.AddFlag("V");
		EdeInstance.AddFlag("N");
		EdeInstance.AddFlag("O");
		EdeInstance.AddFlag("Z");

		EdeInstance.AddIoSection("Errors", "StandardError");
		EdeInstance.AddIoSection("Io", "StandardInput", "StandardOutput");
		
		Scene scene = new Scene(EdeInstance);
		stage.setScene(scene);
		stage.setMaximized(true);
		stage.show();
    }
    
    @Override
    public void start(Stage arg0) throws Exception {
        buildDefaultMachine(arg0);
    }
}
