using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

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
	
	[DotNetType("System.UriBuilder")]
	extern(DOTNET) internal class UriBuilder
	{
		public extern UriBuilder(string scheme, string host, int portNumber);
		public extern System.Uri Uri { get; }
	}

	[DotNetType("System.Uri")]
	extern(DOTNET) internal class Uri
	{
		public extern Uri(string s) {}
		public extern string AbsoluteUri { get; }
	}

	[DotNetType("System.Exception")]
	extern(DOTNET) internal class Exception
	{
		public extern virtual string Message { get; }
		public extern virtual string StackTrace { get; }
		public extern System.Exception InnerException { get; }
	}

	[DotNetType("System.AggregateException")]
	extern(DOTNET) internal class AggregateException : System.Exception
	{
		public extern AggregateException Flatten();
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
		public extern static SecurityProtocolType SecurityProtocol { get; set; }
	}
	[DotNetType("System.Net.IWebProxy")]
	extern(DOTNET && !HOST_MAC) internal interface IWebProxy
	{
		extern ICredentials Credentials { get; set; }
		extern Uri GetProxy(Uri destination);
		extern bool IsBypassed(Uri host);
	}
	[DotNetType("System.Net.ICredentials")]
	extern(DOTNET && !HOST_MAC) internal interface ICredentials
	{}
}
namespace System.Net.Http
{
	[DotNetType("System.Net.Http.HttpClient")]
	extern(DOTNET && !HOST_MAC) internal class HttpClient
	{
		public extern HttpClient(System.Net.Http.HttpClientHandler handler);
		public extern System.Threading.Tasks.Task<HttpResponseMessage> SendAsync(HttpRequestMessage request);
		public extern System.Threading.Tasks.Task<HttpResponseMessage> SendAsync(HttpRequestMessage request,
			HttpCompletionOption completionOption, System.Threading.CancellationToken cancellationToken);
		public extern System.Threading.Tasks.Task<string> GetStringAsync(string uri);
	}
	
	[DotNetType("System.Net.Http.HttpRequestMessage")]
	extern(DOTNET && !HOST_MAC) internal class HttpRequestMessage
	{
		public extern HttpRequestMessage(HttpMethod method, string uri);
		public extern HttpContent Content { get; set; }
		public extern HttpHeaders Headers { get; }
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
		public extern HttpHeaders Headers { get; }
		public extern HttpContent Content { get; }
	}
	[DotNetType("System.Net.Http.Headers.HttpHeaders")]
	extern(DOTNET && !HOST_MAC) internal class HttpHeaders
	{
		public extern void Add(string key, IEnumerable<string> values);
		public extern bool TryGetValues(string name, out IEnumerable<string> values);
		public extern override string ToString();
	}
	[DotNetType("System.Net.Http.HttpContent")]
	extern(DOTNET && !HOST_MAC) internal class HttpContent 
	{
		public extern HttpHeaders Headers { get; }
		public extern override string ToString();
		public extern System.Threading.Tasks.Task<byte[]> ReadAsByteArrayAsync();
		public extern System.Threading.Tasks.Task<Uno.IO.Stream> ReadAsStreamAsync();
		public extern System.Threading.Tasks.Task<string> ReadAsStringAsync();
	}
	[DotNetType("System.Net.Http.StreamContent")]
	extern(DOTNET && !HOST_MAC) public class StreamContent : HttpContent
	{
	}
	[DotNetType("System.Net.Http.ByteArrayContent")]
	extern(DOTNET && !HOST_MAC) public class ByteArrayContent : HttpContent
	{
		public extern ByteArrayContent(byte[] data);
	}
	[DotNetType("System.Net.Http.WebRequestHandler")]
	extern(DOTNET && !HOST_MAC) internal class WebRequestHandler : HttpClientHandler
	{
		public extern System.Security.Cryptography.X509Certificates.X509CertificateCollection ClientCertificates { get; }
	}
	[DotNetType("System.Net.Http.HttpClientHandler")]
	extern(DOTNET && !HOST_MAC) internal class HttpClientHandler
	{
		public DecompressionMethods AutomaticDecompression { get; set; }
		public extern bool AllowAutoRedirect { get; set; }
		public extern System.Net.IWebProxy Proxy { get; set; }
		public extern bool UseProxy { get; set; }
	}
}
namespace System.Net
{
	[DotNetType("System.Net.DecompressionMethods")]
	extern(DOTNET) public enum DecompressionMethods
	{
		Deflate,
		GZip,
		None
	}
	
	[DotNetType("System.Net.SecurityProtocolType")]
	extern(DOTNET) public enum SecurityProtocolType
 	{
		None = 0,
		Ssl2 = 12,
		Ssl3 = 48,
		Tls = 192,
		Tls11 = 768,
		Tls12 = 3072,
		Default = Tls | Ssl3,
	}
}
namespace System.Security.Cryptography.X509Certificates
{
	[DotNetType("System.Security.Cryptography.X509Certificates.X509Certificate")]
	extern(DOTNET) public class X509Certificate
	{
		public extern X509Certificate();
		public extern X509Certificate(string file, string pass);
	}
	[DotNetType("System.Security.Cryptography.X509Certificates.X509Certificate2")]
	extern(DOTNET) public class X509Certificate2 : X509Certificate
	{
		public extern byte[] RawData { get; }
		public extern void Import(byte[] rawData);
		public extern void Import(string filename, string password, X509KeyStorageFlags keyStorageFlags);
		public extern void Import(byte[] rawData, string password, X509KeyStorageFlags keyStorageFlags);
	}
	
	[DotNetType("System.Security.Cryptography.X509Certificates.X509KeyStorageFlags")]
	extern(DOTNET) public enum X509KeyStorageFlags
	{
		DefaultKeySet = 0,
		UserKeySet = 1,
		MachineKeySet = 2,
		Exportable = 4,
		UserProtected = 8,
		PersistKeySet = 16,
	}

	[DotNetType("System.Security.Cryptography.X509Certificates.X509Chain")]
	extern(DOTNET && !HOST_MAC) public class X509Chain
	{
		public extern X509ChainElementCollection ChainElements { get; }
	}

	[DotNetType("System.Security.Cryptography.X509Certificates.X509ChainElementCollection")]
	extern(DOTNET && !HOST_MAC) public sealed class X509ChainElementCollection
	{	
		public extern X509ChainElement this[int index] { get; }
		public extern int Count { get; }
	}

	[DotNetType("System.Security.Cryptography.X509Certificates.X509ChainElement")]
	extern(DOTNET && !HOST_MAC) public sealed class X509ChainElement
	{
		public extern X509Certificate2 Certificate { get; }
	}

	[DotNetType("System.Security.Cryptography.X509Certificates.X509CertificateCollection")]
	extern(DOTNET && !HOST_MAC) internal class X509CertificateCollection
	{
		public extern int Add(X509Certificate value);
	}
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
