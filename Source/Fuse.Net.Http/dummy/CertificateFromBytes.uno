using Uno;
using Uno.Collections;
using Uno.Threading;
using Fuse.Security;

namespace Fuse.Net.Http
{
	extern(!android && !iOS && !DotNet)
	public static class LoadCertificateFromBytes
	{
		public static X509Certificate Load(byte[] data)
		{
			return new X509Certificate(data);
		}
	}
}
