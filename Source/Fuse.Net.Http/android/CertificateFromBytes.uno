using Uno;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Security
{
	[ForeignInclude(Language.Java,
					"java.io.InputStream",
					"java.security.cert.CertificateFactory",
					"java.security.cert.X509Certificate")]
	extern(android)
	public static class LoadCertificateFromBytes
	{
		public static object Load(byte[] data)
		{
			var buf = ForeignDataView.Create(data);
			var inputStream = MakeBufferInputStream(buf);
			return LoadCertificateFromInputStream(inputStream);
		}

		public static object Load(byte[] data, string password)
		{
			var buf = ForeignDataView.Create(data);
			return MakeBufferInputStream(buf);
		}

		public static byte[] GetBytes(object certificateHandle)
		{
			var bytes = InternalGetBytes((Java.Object)certificateHandle);
			if (bytes == null)
				bytes = InternalGetBytes(LoadCertificateFromInputStream((Java.Object)certificateHandle));

			return bytes;
		}

		[Foreign(Language.Java)]
		static byte[] InternalGetBytes(Java.Object certificateHandle)
		@{
			if (certificateHandle instanceof X509Certificate) {
				try {
					X509Certificate cer = (X509Certificate)certificateHandle;
					return new com.uno.ByteArray(cer.getEncoded());
				} catch (Exception e) {
					return null;
				}
			}
			return null;
		@}

		[Foreign(Language.Java)]
		static Java.Object LoadCertificateFromInputStream(Java.Object buf)
		@{
			try
			{
				com.fuse.android.ByteBufferInputStream inputStream = (com.fuse.android.ByteBufferInputStream)buf;
				CertificateFactory fact = CertificateFactory.getInstance("X.509");
				return (X509Certificate)fact.generateCertificate((InputStream)inputStream);
			}
			catch (Exception e)
			{
				debug_log("Could not load certificate from byte\nReason: " + e.getMessage());
				return null;
			}
		@}

		[Foreign(Language.Java)]
		static Java.Object MakeBufferInputStream(Java.Object buf) // UnoBackedByteBuffer buf
		@{
			return new com.fuse.android.ByteBufferInputStream((com.uno.UnoBackedByteBuffer)buf);
		@}
	}
}
