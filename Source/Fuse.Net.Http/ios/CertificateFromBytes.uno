using Uno;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Security
{
	[Require("Xcode.Framework", "Security.framework")]
	[Require("Source.Include", "Security/Security.h")]
	[Set("Include", "Security/Security.h")]
	[Set("TypeName", "SecCertificateRef")]
	[Set("DefaultValue", "NULL")]
	[Set("FileExtension", "mm")]
	[TargetSpecificType]
	extern(iOS) struct SecCertificateRef
	{
		public static bool IsNull(SecCertificateRef lhs)
		{
			return extern<bool>(lhs)"$0 == NULL";
		}
		
		[Foreign(Language.ObjC)]
		public static byte[] GetRawData(SecCertificateRef lhs)
		@{
			CFDataRef dataref = SecCertificateCopyData(lhs);
			NSData* data = CFBridgingRelease(dataref);
			id<UnoArray> arr = @{byte[]:New((int)[data length])};
			memcpy(arr.unoArray->Ptr(), (uint8_t *)[data bytes], [data length]);
			return arr;
		@}
	}

	[Require("Entity","SecCertificateRef")]
	extern(iOS)
	public static class LoadCertificateFromBytes
	{
		public static byte[] Load(byte[] data)
		{
			return Load(ForeignDataView.Create(data));
		}

		static byte[] Load(ForeignDataView view)
		{
			var certRef = Impl(view);
			if (!SecCertificateRef.IsNull(certRef))
			{
				return SecCertificateRef.GetRawData(certRef);
			}
			else
			{
				throw new Exception("LoadCertificateFromBytes Failed. Certificate was null");
				return null;
			}
		}

		[Foreign(Language.ObjC)]
		static SecCertificateRef Impl(ForeignDataView view)
		@{
			return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)view);
		@}
	}
}
