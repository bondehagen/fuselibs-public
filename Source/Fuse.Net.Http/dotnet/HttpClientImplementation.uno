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

			httpClient.BaseAddress = new Uri("https://foobar.com/");
			httpClient.DefaultRequestHeaders.Accept.Clear();
			httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/xml"));*/

			//specify to use TLS 1.2 as default connection
			System.Net.ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls;

			var handler = new HttpClientHandler()
            {
                Proxy = new Proxy("192.168.1.233", 8080),
                UseProxy = false,
            };
            handler.AllowAutoRedirect = true;
            /*	
			handler.ClientCertificateOptions = ClientCertificateOption.Manual;*/
			
			foreach (var cert in _client.ClientCertificates)
			{
				handler.ClientCertificates.Add((X509Certificate2)cert.ImplHandle);
			}

			var client = new System.Net.Http.HttpClient(handler);

			var source = new CancellationTokenSource();
			var token = source.Token;
			if (_client.ServerCertificateValidationCallback != null)
			{
				ServicePointManager.ServerCertificateValidationCallback = Validate;
			}
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
				var aggregateException = task.Exception as System.AggregateException;
				if (aggregateException != null)
					_promise.Reject(new Uno.Exception(aggregateException.Flatten().InnerException.ToString()));
				else
					_promise.Reject(new Uno.Exception(task.Exception.ToString()));
			}
		}

		bool Validate(object sender, System.Security.Cryptography.X509Certificates.X509Certificate2 certificate,
			System.Security.Cryptography.X509Certificates.X509Chain chain, System.Net.Security.SslPolicyErrors sslPolicyErrors)
		{
			try
			{
				if (_client.ServerCertificateValidationCallback != null)
				{
					var c = new Fuse.Security.X509Certificate(certificate.RawData);
					return _client.ServerCertificateValidationCallback(c, new Fuse.Security.X509Chain(), (Fuse.Security.SslPolicyErrors)(int)sslPolicyErrors);
				}
				return (sslPolicyErrors != 0);
			}
			catch(Uno.Exception e)
			{
				debug_log e;
				return false;
			}
		}
	}
}
