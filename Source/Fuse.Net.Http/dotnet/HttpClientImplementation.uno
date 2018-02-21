using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Security;

namespace Fuse.Net.Http
{
	using System;
	using System.Net;
	using System.Net.Http;
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
		class DotNetProxy : System.Net.IWebProxy
		{
			System.Uri _proxyAddress;
			
			public System.Net.ICredentials Credentials { get; set; }

			public DotNetProxy(string protocol, string proxyAddress, int port)
			{
				_proxyAddress = new UriBuilder(protocol, proxyAddress, port).Uri;
			}

			public System.Uri GetProxy(System.Uri destination)
			{
				debug_log _proxyAddress.AbsoluteUri;
				return _proxyAddress;
			}

			public bool IsBypassed(System.Uri host)
			{
				debug_log "IsBypassed";
				return false;
			}
		}

		public Uno.Threading.Future<Response> SendAsync(Request request)
		{
			_promise = new Uno.Threading.Promise<Response>();

			System.Net.ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | SecurityProtocolType.Tls11 | SecurityProtocolType.Default;

			var handler = new WebRequestHandler();
            if (_client.Proxy != null)
            {
            	handler.Proxy = new DotNetProxy(_client.Proxy.Address.Scheme, _client.Proxy.Address.Host, _client.Proxy.Address.Port);
            	handler.UseProxy = true;
			}

			// handler.ClientCertificateOptions = ClientCertificateOption.Manual;
            handler.AllowAutoRedirect = _client.AutoRedirect;
			
			foreach (var cert in _client.ClientCertificates)
			{
				handler.ClientCertificates.Add((X509Certificate2)cert.ImplHandle);
			}

			var client = new System.Net.Http.HttpClient(handler);
			//client.Timeout = TimeSpan.FromMilliseconds(_client.Timeout);

			var source = new CancellationTokenSource();
			var token = source.Token;
			if (_client.ServerCertificateValidationCallback != null)
			{
				ServicePointManager.ServerCertificateValidationCallback = Validate;
			}
			var dotnetRequest = new HttpRequestMessage(GetMethodFromString(request.Method), request.Url);
			if (request.Data != null)
				dotnetRequest.Content = new ByteArrayContent(request.Data);

			foreach(var h in request.Headers)
			{
				dotnetRequest.Headers.Add(h.Key, h.Value);
			}

			var task = client.SendAsync(dotnetRequest, HttpCompletionOption.ResponseHeadersRead, token);
			task.ContinueWith(Continue);
			//request.Dispose();

			return _promise;
		}

		HttpMethod GetMethodFromString(string method)
		{
			if (method.ToUpper() == "POST") {
				return  HttpMethod.Post;
			} else if (method.ToUpper() == "DELETE") {
				return  HttpMethod.Delete;
			} else if (method.ToUpper() == "HEAD") {
				return  HttpMethod.Head;
			} else if (method.ToUpper() == "OPTIONS") {
				return  HttpMethod.Options;
			} else if (method.ToUpper() == "PUT") {
				return  HttpMethod.Put;
			} else if (method.ToUpper() == "TRACE") {
				return HttpMethod.Trace;
			}
			return HttpMethod.Get;
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
					return _client.ServerCertificateValidationCallback(c, (Fuse.Security.SslPolicyErrors)(int)sslPolicyErrors);
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
