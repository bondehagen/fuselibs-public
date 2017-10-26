using Uno;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Security;

namespace Fuse.Net.Http
{
	[Require("Xcode.Framework", "Security.framework")]
	[Require("Source.Include", "Security/Security.h")]
	[Set("Include", "Security/Security.h")]
	[Set("TypeName", "SecCertificateRef")]
	[Set("DefaultValue", "NULL")]
	[Set("FileExtension", "mm")]
	[TargetSpecificType]
	extern(iOS) struct SecCertHandle
	{
		public static bool IsNull(SecCertHandle lhs)
		{
			return extern<bool>(lhs)"$0 == NULL";
		}
	}

	[Require("Entity","SecCertHandle")]
	extern(iOS)
	public static class LoadCertificateFromBytes
	{
		public static X509Certificate Load(byte[] data)
		{
			return Load(ForeignDataView.Create(data));
		}

		static X509Certificate Load(ForeignDataView view)
		{
			var certRef = Impl(view);
			if (!SecCertHandle.IsNull(certRef))
			{
				// TODO: Extract details here
				return null;
			}
			else
			{
				throw new Exception("LoadCertificateFromBytes Failed. Certificate was null");
				return null;
			}
		}

		[Foreign(Language.ObjC)]
		static SecCertHandle Impl(ForeignDataView view)
		@{
			return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)view);
		@}
	}
}
