using Uno.Net.Http;

namespace Fuse.Net.Http
{
	public class NetworkProxy
	{
		public NetworkProxy(Uri address)
		{
			Address = address;
		}

		public Uri Address { get; set; }
	}
}
