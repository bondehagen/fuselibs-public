namespace Fuse.Net.Http
{
	public class Request
	{
		public string Url { get; set; }
		public string Method { get; set; }
		
		public Request(string method, string url)
		{
			Method = method;
			Url = url;
		}
	}
}
