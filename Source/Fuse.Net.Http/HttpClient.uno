using Uno;
using Uno.Collections;
using Uno.Threading;
using Fuse.Security;

namespace Fuse.Net.Http
{
	public class HttpClient
	{
		HttpClientImplementation _impl;
		IList<X509Certificate> _clientCertificates;
		public Func<X509Certificate, SslPolicyErrors, bool> ServerCertificateValidationCallback;

		internal IList<X509Certificate> ClientCertificates
		{
			get { return _clientCertificates; }
		}

		public void SetClientCertificate(X509Certificate certificate)
		{
			ClientCertificates.Add(certificate);
		}
		
		public NetworkProxy Proxy { get; set; }
		public bool AutoRedirect { get; set; }
		public int Timeout { get; set; }

		public HttpClient()
		{
			debug_log "init HttpClient";
			_impl = new HttpClientImplementation(this);
			_clientCertificates = new List<X509Certificate>();
			AutoRedirect = true;
			Timeout = 5000;
		}

		public Future<Response> Send(Request request)
		{
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
