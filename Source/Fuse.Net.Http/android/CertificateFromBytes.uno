using Uno;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Scripting;

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
			var jcert = LoadCertificateFromInputStream(inputStream);
			// TODO: Extract details here
			return null;
		}

		[Foreign(Language.Java)]
		static Java.Object LoadCertificateFromInputStream(Java.Object buf)
		@{
			try
			{
				com.fuse.android.ByteBufferInputStream inputStream = new com.fuse.android.ByteBufferInputStream((com.uno.UnoBackedByteBuffer)buf);
				CertificateFactory fact = CertificateFactory.getInstance("X.509");
				X509Certificate cer = (X509Certificate)fact.generateCertificate((InputStream)inputStream);
				return cer;
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
