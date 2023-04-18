package io.github.H20man13.ARM7TDMISEmulator;

import io.github.h20man13.emulator_ide.gui.GuiEde;
import io.github.h20man13.emulator_ide.gui.gui_machine.GuiRam;
import io.github.h20man13.emulator_ide.gui.gui_machine.GuiRegister;
import javafx.application.Application;
import javafx.geometry.Rectangle2D;
import javafx.scene.Scene;
import javafx.stage.Screen;
import javafx.stage.Stage;

public class Loader extends Application {

	public Loader(){}

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

		EdeInstance.AddExeJob("Assemble", "ArmAssembler.exe -i TempInput -o TempOutput -e TempError", "TempInput", "TempOutput", "TempError", "StandardError");
		EdeInstance.AddVerilogJob("Execute", "emulator_ide/src/main/java/edu/depauw/emulator_ide/processor/ARM7TDMIS.v", "default", "StandardInput", "StandardOutput", "StandardError");

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
    public void start(Stage stage){
		buildDefaultMachine(stage);
	}
    
}
