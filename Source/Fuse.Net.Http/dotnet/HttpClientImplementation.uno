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

		public Uno.Threading.Future<Response> SendAsync(Request request)
		{
			_promise = new Uno.Threading.Promise<Response>();
			debug_log "Run";


		/*	var handler = new HttpClientHandler();
			handler.ClientCertificateOptions = ClientCertificateOption.Manual;
			handler.SslProtocols = SslProtocols.Tls12;
			handler.ClientCertificates.Add(new X509Certificate2("cert.crt"));
			var client = new HttpClient(handler);



			using (var handler = new WebRequestHandler())
			{
			    handler.ServerCertificateValidationCallback = ...

			    using (var client = new HttpClient(handler))
			    {
			        ...
			    }
			}


			WebRequestHandler handler = new WebRequestHandler();
			X509Certificate2 certificate = GetMyX509Certificate();
			handler.ClientCertificates.Add(certificate);

			var client = new HttpClient(handler);

			//specify to use TLS 1.2 as default connection
			System.Net.ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls;

			httpClient.BaseAddress = new Uri("https://foobar.com/");
			httpClient.DefaultRequestHeaders.Accept.Clear();
			httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/xml"));*/

			var client = new System.Net.Http.HttpClient();

			var source = new CancellationTokenSource();
			var token = source.Token;
			
			ServicePointManager.ServerCertificateValidationCallback = Validate;
			
			var task = client.SendAsync(new HttpRequestMessage(HttpMethod.Get, request.Url), HttpCompletionOption.ResponseContentRead, token);
			debug_log "sent";
			task.ContinueWith(Continue);

			return _promise;
		}

		void Continue(Task<HttpResponseMessage> task)
		{
			debug_log "IsCompleted " + task.IsCompleted;
			if (!task.IsFaulted && !task.IsCanceled)
			{
				debug_log "got response";
				debug_log task.Result.StatusCode.ToString();
				_promise.Resolve(new Response());
			}
			else
			{
				debug_log "err";
				_promise.Reject(new Uno.Exception(task.Exception.ToString()));
			}
		}

		bool Validate(object sender, System.Security.Cryptography.X509Certificates.X509Certificate2 certificate,
			System.Security.Cryptography.X509Certificates.X509Chain chain, System.Net.Security.SslPolicyErrors sslPolicyErrors)
		{
			if (_client.ServerCertificateValidationCallback != null)
			{
				var c = new X509Certificate(certificate.Subject, certificate.Issuer, certificate.RawData);
				return _client.ServerCertificateValidationCallback(c, new Fuse.Security.X509Chain(), (Fuse.Security.SslPolicyErrors)(int)sslPolicyErrors);
			}
			return false;
		}
	}
}
namespace System.Security.Cryptography.X509Certificates
{
	[DotNetType("System.Security.Cryptography.X509Certificates.X509Certificate2")]
	extern(DOTNET && !HOST_MAC) public class X509Certificate2
	{
		public extern string Subject { get; }
		public extern string Issuer { get; }
		public extern byte[] RawData { get; }
		public extern virtual string GetCertHashString();

	}

	[DotNetType("System.Security.Cryptography.X509Certificates.X509Chain")]
	extern(DOTNET && !HOST_MAC) public class X509Chain
	{}
}
namespace System.Net.Security
{
	using System.Security.Cryptography.X509Certificates;

	[DotNetType("System.Net.Security.SslPolicyErrors")]
	extern(DOTNET && !HOST_MAC) public enum SslPolicyErrors
	{
		None = 0,
		RemoteCertificateNotAvailable = 1,
		RemoteCertificateNameMismatch = 2,
		RemoteCertificateChainErrors = 4,
	}

	[DotNetType("System.Net.Security.RemoteCertificateValidationCallback")]
	extern(DOTNET && !HOST_MAC) public delegate bool RemoteCertificateValidationCallback(object sender,
		X509Certificate2 certificate, System.Security.Cryptography.X509Certificates.X509Chain chain, SslPolicyErrors sslPolicyErrors);
}
namespace System.Threading
{	
	[DotNetType("System.Threading.CancellationTokenSource")]
	extern(DOTNET && !HOST_MAC) internal class CancellationTokenSource
	{
		public extern CancellationToken Token { get; }
	}
	[DotNetType("System.Threading.CancellationToken")]
	extern(DOTNET && !HOST_MAC) internal class CancellationToken
	{
		public extern void Cancel();
	}
}
namespace System.Threading.Tasks
{
	[DotNetType("System.Threading.Tasks.Task")]
	extern(DOTNET && !HOST_MAC) internal class Task
	{}

	[DotNetType("System.Threading.Tasks.Task`1")]
	extern(DOTNET && !HOST_MAC) internal class Task<TResult>
	{
		public extern System.Exception Exception { get; }
		public extern TResult Result { get; }
		public extern Task ContinueWith(Action<Task<TResult>> continuationAction);
		public extern bool IsCanceled { get; }
		public extern bool IsCompleted { get; }
		public extern bool IsFaulted { get; }
	}
}
namespace System
{
	[DotNetType("System.Uri")]
	extern(DOTNET) internal class Uri
	{
		public extern Uri(string s) {}
	}

	[DotNetType("System.Exception")]
	extern(DOTNET) internal class Exception
	{
	}

}
namespace System.Net
{
	[DotNetType("System.Net.HttpStatusCode")]
	extern(DOTNET && !HOST_MAC) internal enum HttpStatusCode
	{}

	[DotNetType("System.Net.ServicePointManager")]
	extern(DOTNET && !HOST_MAC) public class ServicePointManager
	{
		public extern static System.Net.Security.RemoteCertificateValidationCallback ServerCertificateValidationCallback { get; set; }
	}
}
namespace System.Net.Http
{
	[DotNetType("System.Net.Http.HttpClient")]
	extern(DOTNET && !HOST_MAC) internal class HttpClient
	{
		public extern System.Threading.Tasks.Task<HttpResponseMessage> SendAsync(HttpRequestMessage request);
		public extern System.Threading.Tasks.Task<HttpResponseMessage> SendAsync(HttpRequestMessage request,
			HttpCompletionOption completionOption, System.Threading.CancellationToken cancellationToken);
		public extern System.Threading.Tasks.Task<string> GetStringAsync(string uri);
	}
	
	[DotNetType("System.Net.Http.HttpRequestMessage")]
	extern(DOTNET && !HOST_MAC) internal class HttpRequestMessage
	{
		public extern HttpRequestMessage(HttpMethod method, string uri);
	}
	[DotNetType("System.Net.Http.HttpMethod")]
	extern(DOTNET && !HOST_MAC) internal class HttpMethod
	{
		public extern static HttpMethod Delete { get; }
		public extern static HttpMethod Get { get; }
		public extern static HttpMethod Head { get; }
		public extern static HttpMethod Method { get; }
		public extern static HttpMethod Options { get; }
		public extern static HttpMethod Post { get; }
		public extern static HttpMethod Put { get; }
		public extern static HttpMethod Trace { get; }	
	}
	[DotNetType("System.Net.Http.HttpCompletionOption")]
	extern(DOTNET && !HOST_MAC) internal enum HttpCompletionOption
	{
		ResponseContentRead,
		ResponseHeadersRead
	}

	[DotNetType("System.Net.Http.HttpResponseMessage")]
	extern(DOTNET && !HOST_MAC) internal class HttpResponseMessage
	{
		public extern HttpStatusCode StatusCode { get; }
	}

	[DotNetType("System.Net.Http.WebRequestHandler")]
	extern(DOTNET && !HOST_MAC) internal class WebRequestHandler
	{

	}
	[DotNetType("System.Net.Http.HttpClientHandler")]
	extern(DOTNET && !HOST_MAC) internal class HttpClientHandler
	{
	}
}
