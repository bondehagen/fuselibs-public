using Uno;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Security;

namespace Fuse.Net.Http
{
	[ForeignInclude(Language.Java,
					"java.io.InputStream",
					"java.security.cert.CertificateFactory",
					"java.security.cert.X509Certificate")]
	extern(android)
	public static class LoadCertificateFromBytes
	{
		public static X509Certificate Load(byte[] data)
		{
			var buf = ForeignDataView.Create(data);
			var inputStream = MakeBufferInputStream(buf);
			return new X509Certificate(LoadCertificateFromInputStream(inputStream));
		}

		[Foreign(Language.Java)]
		static byte[] LoadCertificateFromInputStream(Java.Object buf)
		@{
			try
			{
				com.fuse.android.ByteBufferInputStream inputStream = (com.fuse.android.ByteBufferInputStream)buf;
				CertificateFactory fact = CertificateFactory.getInstance("X.509");
				X509Certificate cer = (X509Certificate)fact.generateCertificate((InputStream)inputStream);
				System.out.println(cer.toString());
				return new com.uno.ByteArray(cer.getEncoded());
			}
			catch (Exception e)
			{
				// TODO: not sure how you want to return this
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
