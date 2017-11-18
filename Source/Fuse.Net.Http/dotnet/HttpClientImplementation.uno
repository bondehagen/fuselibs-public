using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Security;

namespace Fuse.Net.Http
{
	using System;
	using System.Net;
	using System.Net.Http;
	//using System.Security.Authentication;
	using System.Net.Security;
	using System.Threading;
	using System.Threading.Tasks;
	using System.Security.Cryptography.X509Certificates;

	extern(DOTNET && !HOST_MAC) class HttpClientImplementation
	{
		Uno.Threading.Promise<Response> _promise;
		HttpClient _client;

		public HttpClientImplementation(HttpClient client)
		{
			_client = client;
		}
		class Proxy : System.Net.IWebProxy
		{
			System.Uri _proxyAddress;
			
			public System.Net.ICredentials Credentials { get; set; }

			public Proxy(string proxyAddress, int port)
			{
				_proxyAddress = new UriBuilder("http", proxyAddress, port).Uri;
			}

			public System.Uri GetProxy(System.Uri destination)
			{
				return _proxyAddress;
			}
			public bool IsBypassed(System.Uri host)
			{
				return false;
			}
		}
		public Uno.Threading.Future<Response> SendAsync(Request request)
		{
			_promise = new Uno.Threading.Promise<Response>();

			/*using (var handler = new WebRequestHandler())
			{
			    handler.ServerCertificateValidationCallback = ...

			    using (var client = new HttpClient(handler))
			    {
			        ...
			    }
			}

			//specify to use TLS 1.2 as default connection
			System.Net.ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls;

			httpClient.BaseAddress = new Uri("https://foobar.com/");
			httpClient.DefaultRequestHeaders.Accept.Clear();
			httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/xml"));*/
			var handler = new HttpClientHandler()
            {
                Proxy = new Proxy("192.168.1.233", 8080),
                UseProxy = true,
            };
            handler.AllowAutoRedirect = true;
            /*	
			handler.ClientCertificateOptions = ClientCertificateOption.Manual;
			handler.SslProtocols = SslProtocols.Tls12;
			handler.ClientCertificates.Add(new X509Certificate2("cert.crt"));
			*/
			var client = new System.Net.Http.HttpClient(handler);

			var source = new CancellationTokenSource();
			var token = source.Token;
			
			ServicePointManager.ServerCertificateValidationCallback = Validate;
			
			var task = client.SendAsync(new HttpRequestMessage(HttpMethod.Get, request.Url), HttpCompletionOption.ResponseHeadersRead, token);
			task.ContinueWith(Continue);
			//request.Dispose();

			return _promise;
		}

		void Continue(Task<HttpResponseMessage> task)
		{
			if (!task.IsFaulted && !task.IsCanceled)
			{
				_promise.Resolve(new Response(new ResponseImplementation(task.Result)));
			}
			else
			{
				debug_log task.Exception.GetType();
				_promise.Reject(new Uno.Exception(task.Exception.ToString()));
			}
		}

		bool Validate(object sender, System.Security.Cryptography.X509Certificates.X509Certificate2 certificate,
			System.Security.Cryptography.X509Certificates.X509Chain chain, System.Net.Security.SslPolicyErrors sslPolicyErrors)
		{
			if (_client.ServerCertificateValidationCallback != null)
			{
				var c = new X509Certificate(certificate.RawData);
				return _client.ServerCertificateValidationCallback(c, new Fuse.Security.X509Chain(), (Fuse.Security.SslPolicyErrors)(int)sslPolicyErrors);
			}
			return false;
		}
	}
}
