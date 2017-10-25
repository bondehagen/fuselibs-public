namespace Fuse.Security
{
	public class X509Certificate
	{
		public string Subject { get; private set; }
		public string Issuer { get; private set; }
		public string Thumbprint { get; private set; }
		public byte[] DerEncodedData { get; private set; } 

		public X509Certificate(string subject, string issuer, byte[] der)
		{
			Subject = subject;
			Issuer = issuer;
			Thumbprint = "thumbprint"; // sha1 of der
			DerEncodedData = der;
			var lol = new ASN1Tools();
			lol.Decode(der);
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
