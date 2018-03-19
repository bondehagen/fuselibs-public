using Uno;
using Uno.Collections;
using Uno.Threading;

namespace Fuse.Net.Http
{
	public class HttpClient
	{
		HttpClientImplementation _impl;
		IList<byte[]> _clientCertificates;
		public Func<Uno.Collections.IList<byte[]>, string, bool> ServerCertificateValidationCallback;

		internal IList<byte[]> ClientCertificates
		{
			get { return _clientCertificates; }
		}

		public void SetClientCertificate(byte[] certificate)
		{
			ClientCertificates.Add(certificate);
		}
		
		public NetworkProxy Proxy { get; set; }
		public bool AutoRedirect { get; set; }
		public int Timeout { get; set; }

		public HttpClient()
		{
			debug_log "init HttpClient";
			AutoRedirect = true;
			Timeout = 5000;
			_clientCertificates = new List<byte[]>();
			
			_impl = new HttpClientImplementation(this);
		}

		public Future<Response> Send(Request request)
		{
			debug_log "send";
			return _impl.SendAsync(request);
		}

		public void AbortAllRequest()
		{
			debug_log "TODO: AbortAllRequest";
		}
	}

	extern(!DOTNET && !iOS && !Android) class HttpClientImplementation
	{
		public HttpClientImplementation(HttpClient client)
		{
		}

		public Future<Response> SendAsync(Request request)
		{
			throw new Exception("Target not supported");
		}
	}
}
