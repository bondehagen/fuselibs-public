using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Security;

namespace System.Security.Cryptography.X509Certificates
{
	[DotNetType("System.Security.Cryptography.X509Certificates.X509Certificate2")]
	extern(DOTNET) public class X509Certificate2
	{	
		public extern byte[] RawData { get; }
		public extern void Import(byte[] rawData);
		// TODO: public extern void Import(byte[] rawData, string password, X509KeyStorageFlags keyStorageFlags)
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
		public extern HttpResponseHeaders Headers { get; }
	}
	
	[DotNetType("System.Net.Http.Headers.HttpResponseHeaders")]
	extern(DOTNET && !HOST_MAC) internal class HttpResponseHeaders
	{
		public extern bool TryGetValues(string name, out IEnumerable<string> values);
		public extern override string ToString();
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
