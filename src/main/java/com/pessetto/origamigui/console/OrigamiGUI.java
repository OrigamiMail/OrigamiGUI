package com.pessetto.origamigui.console;

import javafx.application.Application;
import javafx.application.Platform;
import javafx.event.EventHandler;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.scene.control.Alert;
import javafx.scene.control.Alert.AlertType;
import javafx.scene.control.ButtonType;
import javafx.scene.image.Image;
import javafx.scene.layout.VBox;
import javafx.stage.Stage;
import javafx.stage.WindowEvent;

import java.awt.TrayIcon.MessageType;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.File;
import java.io.PrintStream;
import java.util.Optional;

import com.pessetto.origamigui.debug.DebugLogSingleton;
import com.pessetto.origamigui.listeners.TrayIconListener;
import com.pessetto.origamigui.settings.SettingsSingleton;
import com.pessetto.origamigui.tray.SystemTraySingleton;
import java.io.IOException;

public class OrigamiGUI extends Application implements ActionListener, TrayIconListener{
	
	private Image icon;
	private Stage mainStage;
	private static PrintStream debugOut;
	private static DebugLogSingleton debugLog;
	
	
	@Override
	public void start(Stage stage) {
		
            try
            {
                System.out.println("opening stage");
		mainStage = stage;
		Platform.setImplicitExit(false);
		
		// icons
                System.out.println("setting icons");
		icon = new Image(getClass().getClassLoader().getResourceAsStream("icons/origami.png"));
		stage.getIcons().add(icon);
		
                System.out.println("Starting tray icon");
		SystemTraySingleton systemTray = SystemTraySingleton.getInstance();
		systemTray.setIcon(icon);
		systemTray.addActionListener(this);
		systemTray.startTrayIcon();
		
                System.out.println("Loading console");
                System.out.println("Loading: "+getClass().getClassLoader().getResource("gui/Console.fxml"));
		VBox console = FXMLLoader.load(getClass().getClassLoader().getResource("gui/Console.fxml"));
		Scene scene = new Scene(console);
		
		mainStage.setTitle("Origami Mail");
		mainStage.setScene(scene);
		
                System.out.println("Setting close event");
		// Make sure to prompt before close
		mainStage.setOnCloseRequest(new EventHandler<WindowEvent>() {
		    @Override
		    public void handle(WindowEvent event) {
		        exit(event);
		    }
		});
		
               System.out.println("Opening stage");
		openStage();
            }
            catch(IOException ex)
            {
                System.out.println("An IO Exception was found");
                ex.printStackTrace(System.err);
            }
	}
	
	public void openStage()
	{
		try
		{	
			SystemTraySingleton systemTray = SystemTraySingleton.getInstance();
			systemTray.stop();
			if(mainStage != null)
			{
				mainStage.show();
			}
		}
		catch(Exception ex)
		{
			Alert alert = new Alert(AlertType.ERROR);
			alert.setContentText(ex.getMessage());
			alert.showAndWait();
			System.err.println(ex);
		}
	}
	
	
	public void exit(WindowEvent event)
	{
		if(exitApplication())
		{
			stop();
		}
		else
		{
			mainStage.hide();
			SystemTraySingleton systemTray = SystemTraySingleton.getInstance();
			systemTray.startTrayIcon();
			systemTray.displayMessage("I am here", "I will be down here if you need me. Exit from the menu if you want me to go away.", MessageType.INFO);
		}
	}
	
	@Override
	public void stop()
	{
                System.out.println("Exiting");
		SystemTraySingleton systemTray = SystemTraySingleton.getInstance();
		systemTray.stop();
		SettingsSingleton.getInstance().stopSMTPServer();
		Platform.exit();
	}
	
	public static void main(String[] args)
	{
		try
		{
		debugOut = System.err;
		System.out.println("starting Origami GUI !");
		String workingDir = System.getProperty("user.dir");
		File workingDirFile = new File(workingDir+"/Origami SMTP");
		System.out.println("working dir: " + workingDirFile.getAbsolutePath());
		if(!workingDirFile.exists())
		{
			System.out.println("working dir non exist");
			if(!workingDirFile.mkdirs())
			{
				System.out.println("Failed to make directory");
			}
		}
		if(!workingDirFile.canWrite())
		{
			System.out.println("Cannot write dir");
			System.err.println("Directory not writable ("+workingDirFile+")");
			Alert alert = new Alert(AlertType.ERROR);
			alert.setTitle("Error: Directory not writable");
			alert.setContentText(workingDirFile + " is not writable when it should be");
			alert.showAndWait();
		}
		else
		{
			debugLog = DebugLogSingleton.getInstance();
			System.out.println("Origami GUI");
			System.out.println("Write to: " + workingDirFile.getAbsolutePath() );
			launch(args);
		}
		System.out.println("done");
		}
		catch(Exception ex)
		{
			debugOut.println("Exception:");
			debugOut.println(ex.getMessage());
                        System.err.println("Exception");
                        ex.printStackTrace(System.err);
			ex.printStackTrace(debugOut);
		}
	}

	@Override
	public void actionPerformed(ActionEvent e)
	{
		if(e.getActionCommand().equals("Open"))
		{
			SystemTraySingleton systemTray = SystemTraySingleton.getInstance();
			systemTray.stop();
			Platform.runLater(new Runnable()
			{
				@Override
				public void run() {
					mainStage.show();	
				}
		
			});
		}
		else if(e.getActionCommand().equals("Exit"))
		{
			stop();
		}
	}

	@Override
	public void TrayAction(String action) {
		if(action.equals("open stage"))
		{
			mainStage.show();
		}
		
	}
	
	private boolean exitApplication()
	{
		Alert alert = new Alert(AlertType.CONFIRMATION);
		alert.setTitle("Exit or Minimize?");
		alert.setHeaderText("Do you wish to exit or minimize to tray?");
		alert.setContentText("Choose one");
		
		ButtonType buttonExit = new ButtonType("Exit");
		ButtonType buttonMinimize = new ButtonType("Minimize");
		
		alert.getButtonTypes().setAll(buttonExit,buttonMinimize);
		
		Optional<ButtonType> result = alert.showAndWait();
		
		if(result.get() == buttonExit)
		{
			return true;
		}
		else
		{
			return false;
		}
		
	}
	

}
