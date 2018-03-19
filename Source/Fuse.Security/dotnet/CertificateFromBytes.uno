using Uno;

namespace Fuse.Security
{
	extern(DotNet) public static class LoadCertificateFromBytes
	{
		public static object Load(byte[] data)
		{
			var certificate = new System.Security.Cryptography.X509Certificates.X509Certificate2();
			certificate.Import(data);
			return certificate;
		}

		public static object Load(byte[] data, string password)
		{
			var certificate = new System.Security.Cryptography.X509Certificates.X509Certificate2();
			certificate.Import(data, password, System.Security.Cryptography.X509Certificates.X509KeyStorageFlags.DefaultKeySet);
			return certificate;
		}

		public static byte[] GetBytes(object certificateHandle)
		{
			return ((System.Security.Cryptography.X509Certificates.X509Certificate2)certificateHandle).RawData;
		}
	}
}
