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
	extern(iOS) struct SecCertificateHandle
	{
		public static bool IsNull(SecCertificateHandle lhs)
		{
			return extern<bool>(lhs)"$0 == NULL";
		}
		
		[Foreign(Language.ObjC)]
		public static byte[] GetRawData(SecCertificateHandle lhs)
		@{
			CFDataRef dataref = SecCertificateCopyData(lhs);
			NSData* data = CFBridgingRelease(dataref);
			id<UnoArray> arr = @{byte[]:New((int)[data length])};
			memcpy(arr.unoArray->Ptr(), (uint8_t *)[data bytes], [data length]);
			return arr;
		@}
	}

	[Require("Entity","SecCertificateHandle")]
	extern(iOS) public static class LoadCertificateFromBytes
	{
		public static object Load(byte[] data)
		{
			var fdv = ForeignDataView.Create(data);
			return Load(fdv);
		}

		public static object Load(byte[] data, string password)
		{
			var fdv = ForeignDataView.Create(data);
			return Load(fdv);
		}

		public static byte[] GetBytes(object certificateHandle)
		{
			return SecCertificateHandle.GetRawData((SecCertificateHandle)certificateHandle);
		}

		static object Load(ForeignDataView view)
		{
			var certRef = Impl(view);
			if (!SecCertificateHandle.IsNull(certRef))
			{
				return certRef;
			}
			else
			{
				return null;
			}
		}

		[Foreign(Language.ObjC)]
		static SecCertificateHandle Impl(ForeignDataView view)
		@{
			return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)view);
		@}
	}
}
