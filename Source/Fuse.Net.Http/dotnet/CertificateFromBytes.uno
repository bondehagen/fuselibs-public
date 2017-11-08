using Uno;
using Uno.Collections;
using Uno.Threading;
using Fuse.Security;

namespace Fuse.Net.Http
{
	extern(DotNet) public static class LoadCertificateFromBytes
	{
		public static X509Certificate Load(byte[] data)
		{
			var certificate = new System.Security.Cryptography.X509Certificates.X509Certificate2();
			certificate.Import(data);
			return new X509Certificate(certificate.RawData);
		}
	}
}
