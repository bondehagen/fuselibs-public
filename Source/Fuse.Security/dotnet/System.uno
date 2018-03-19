using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace System
{
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
	{}

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
