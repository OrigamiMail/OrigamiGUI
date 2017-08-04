package application.threads;

import java.net.BindException;
import java.net.SocketException;
import java.util.List;

import com.pessetto.Status.StatusListener;
import com.pessetto.main.ConsoleMain;

import application.listeners.SMTPErrorListener;
import application.listeners.SMTPStatusListener;

public class SMTPThread implements Runnable{

	private int port;
	private ConsoleMain smtpServer;
	private SMTPErrorListener listener;
	private boolean smtpStarted;
	private List<SMTPStatusListener> statusListeners;
	public SMTPThread(int port,SMTPErrorListener listener,List<SMTPStatusListener> statusListeners)
	{
		this.port = port;
		this.listener = listener;
		this.statusListeners = statusListeners;
		smtpServer = new ConsoleMain(this.port);
	}
	
	
	public boolean isStarted()
	{
		return smtpStarted;
	}
	
	@Override
	public void run() 
	{
		try 
		{
			System.out.println("Starting bundled SMTP Server");
			notifyAllStatusListeners(true);
			smtpServer.startSMTP();
		}
		catch(BindException ex)
		{
			listener.notifyWithMessage(ex, "You may be able to fix this by changing the port in File > Settings > Connection or exiting a previous instance");
			ex.printStackTrace(System.err);
			notifyAllStatusListeners(false);
		}
		catch (Exception e) {
			listener.notifyWithMessage(e, e.getMessage());
			e.printStackTrace();
			notifyAllStatusListeners(false);
		}
	}
	
	public void stop()
	{
		smtpServer.closeSMTP();
		notifyAllStatusListeners(false);
	}
	
	public void notifyAllStatusListeners(boolean started)
	{
		for(SMTPStatusListener listener : statusListeners)
		{
			listener.smtpStatusChanged(started);
		}
	}
	

}
