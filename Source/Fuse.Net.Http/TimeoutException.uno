namespace Fuse.Net.Http
{
	public class TimeoutException : Uno.Exception
	{
		public TimeoutException(string message) : base(message) {}
	}
}
