using Uno;
using Uno.Collections;
using Uno.Threading;

namespace Fuse.Security
{
	extern(!android && !iOS && !DotNet)	public static class LoadCertificateFromBytes
	{
		public static byte[] Load(byte[] data)
		{
			return data;
		}

		public static object Load(byte[] data, string password)
		{
			return null;
		}

		public static byte[] GetBytes(object certificateHandle)
		{
			return null;
		}
	}
}
