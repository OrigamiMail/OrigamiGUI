package application.listeners;

public interface SMTPErrorListener
{
	void notify(Exception ex);
	void notifyFatal(Exception ex);
	void notifyWithMessage(Exception ex, String message);
}