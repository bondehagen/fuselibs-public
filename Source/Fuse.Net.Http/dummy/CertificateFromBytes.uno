using Uno;
using Uno.Collections;
using Uno.Threading;

namespace Fuse.Net.Http
{
	extern(!android && !iOS)
	public static class LoadCertificateFromBytes
	{
		public static X509Certificate Load(byte[] data)
		{
			throw new Exception("LoadCertificateFromBytes is not implemented on this platform");
			return null;
		}
	}
}
