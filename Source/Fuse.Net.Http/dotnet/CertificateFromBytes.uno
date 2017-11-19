using Uno;
using Uno.Collections;
using Uno.Threading;

namespace Fuse.Security
{
	extern(DotNet) public static class LoadCertificateFromBytes
	{
		public static byte[] Load(byte[] data)
		{
			var certificate = new System.Security.Cryptography.X509Certificates.X509Certificate2();
			certificate.Import(data);
			return certificate.RawData;
		}
	}
}
