//TODO: namespace Fuse.Security
namespace Fuse.Net.Http
{
	public class X509Certificate
	{
		public string Subject { get; private set; }
		public string Issuer { get; private set; }
		public string Thumbprint { get; private set; }
		//public byte[] DerEncodedSignature 

		public X509Certificate(string subject, string issuer, string thumbprint)
		{
			Subject = subject;
			Issuer = issuer;
			Thumbprint = thumbprint;
		}
	}
	public class X509Chain
	{

	}
	public enum SslPolicyErrors
	{
		None = 0,
		RemoteCertificateNotAvailable = 1,
		RemoteCertificateNameMismatch = 2,
		RemoteCertificateChainErrors = 4,
	}
}
