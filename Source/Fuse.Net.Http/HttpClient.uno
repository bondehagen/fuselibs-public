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

		private IList<X509Certificate> ClientCertificates
		{
			get { return _clientCertificates; }
		}

		public void SetClientCertificate(X509Certificate certificate)
		{
			ClientCertificates.Add(certificate);
		}

		public HttpClient()
		{
			debug_log "init HttpClient";
			_impl = new HttpClientImplementation(this);
			_clientCertificates = new List<X509Certificate>();
		}

		public Future<Response> Send(Request request)
		{
			return _impl.SendAsync(request);
		}
	}

	extern(!DOTNET && !iOS && !Android) class HttpClientImplementation
	{
		public HttpClientImplementation(HttpClient client)
		{
		}

		public Future<Response> SendAsync(Request request)
		{
			debug_log "Target not supported";
			return null;
		}
	}
}
