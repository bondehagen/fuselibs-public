using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Uno.Threading;

namespace Foundation
{
	[DotNetType("Foundation.NSObject")]
	extern(DOTNET && HOST_MAC) public class NSObject
	{
		public extern static NSObject FromObject(string str);
		public extern override string ToString();
	}
	
	[DotNetType("Foundation.NSValue")]
	extern(DOTNET && HOST_MAC) public class NSValue : NSObject
	{
	}

	[DotNetType("Foundation.NSString")]
	extern(DOTNET && HOST_MAC) public class NSString : NSObject
	{
	}

	[DotNetType("Foundation.NSNumber")]
	extern(DOTNET && HOST_MAC) public class NSNumber : NSValue
	{
		public extern static NSNumber FromInt32(int number);
	}
	
	[DotNetType("Foundation.NSDictionary")]
	extern(DOTNET && HOST_MAC) public class NSDictionary
	{
		public extern static NSDictionary FromObjectsAndKeys(NSObject[] objects, NSObject[] keys);
		public extern NSObject[] Keys { get; }
		public extern NSObject this[NSObject key] { get; }
	}

	[DotNetType("Foundation.NSUrl")]
	extern(DOTNET && HOST_MAC) public class NSUrl
	{
		public extern NSUrl(string urlString);
		public extern static NSUrl FromString(string s);
		public extern string AbsoluteString { get; }
	}

	[DotNetType("Foundation.NSUrlRequest")]
	extern(DOTNET && HOST_MAC) internal class NSUrlRequest
	{
	}
	
	[DotNetType("Foundation.NSMutableUrlRequest")]
	extern(DOTNET && HOST_MAC) internal class NSMutableUrlRequest : NSUrlRequest
	{
		public extern NSMutableUrlRequest(NSUrl url);
		public extern virtual string HttpMethod { get; set; }
	}

	[DotNetType("Foundation.NSUrlSession")]
	extern(DOTNET && HOST_MAC) internal class NSUrlSession
	{
		public extern static NSUrlSession FromConfiguration(NSUrlSessionConfiguration configuration, NSUrlSessionDelegate urlSessionDelegate, object delegateQueue);
		public static NSUrlSession SharedSession
		{
			get
			{
				return null;
			}
		}

		public virtual NSUrlSessionDataTask CreateDataTask(NSUrlRequest request, NSUrlSessionResponse completionHandler)
		{
			 return null;
		}
	}

	[DotNetType("Foundation.NSUrlSessionResponse")]
	extern(DOTNET && HOST_MAC) internal delegate void NSUrlSessionResponse(NSData data, NSUrlResponse response, NSError error);

	[DotNetType("Foundation.NSUrlSessionDataTask")]
	extern(DOTNET && HOST_MAC) internal class NSUrlSessionDataTask
	{
		public extern void Resume();
		public extern void Cancel();
	}

	[DotNetType("Foundation.NSUrlResponse")]
	extern(DOTNET && HOST_MAC) internal class NSUrlResponse
	{}
	
	[DotNetType("Foundation.NSHttpUrlResponse")]
	extern(DOTNET && HOST_MAC) internal class NSHttpUrlResponse : NSUrlResponse
	{
		public extern int StatusCode { get; }
		public extern NSDictionary AllHeaderFields { get; }
	}
 
	[DotNetType("Foundation.NSError")]
	extern(DOTNET && HOST_MAC) internal class NSError
	{}

	[DotNetType("Foundation.NSData")]
	extern(DOTNET && HOST_MAC) public class NSData
	{
		public extern byte[] ToArray();
		public extern override string ToString();
	}

	[DotNetType("Foundation.NSUrlSessionConfiguration")]
	extern(DOTNET && HOST_MAC) internal class NSUrlSessionConfiguration : Uno.IDisposable
	{
		public extern static NSUrlSessionConfiguration DefaultSessionConfiguration { get; }
		public extern virtual NSDictionary ConnectionProxyDictionary { get; set; }
	}

	[DotNetType("Foundation.NSUrlSessionTask")]
	extern(DOTNET && HOST_MAC) internal class NSUrlSessionTask
	{}

	[DotNetType("Foundation.NSUrlSessionDelegate")]
	extern(DOTNET && HOST_MAC) internal class NSUrlSessionDelegate
	{
		public extern virtual void DidBecomeInvalid(NSUrlSession session, NSError error);

		public extern virtual void DidFinishEventsForBackgroundSession(NSUrlSession session);

		public extern virtual void DidReceiveChallenge(NSUrlSession session, NSUrlAuthenticationChallenge challenge,
			Action<NSUrlSessionAuthChallengeDisposition, NSUrlCredential> completionHandler);
	}

	[DotNetType("Foundation.NSUrlSessionTaskDelegate")]
	extern(DOTNET && HOST_MAC) internal class NSUrlSessionTaskDelegate : NSUrlSessionDelegate
	{
		public extern virtual void WillPerformHttpRedirection(NSUrlSession session, NSUrlSessionTask task,
			NSHttpUrlResponse response, NSUrlRequest newRequest, Action<NSUrlRequest> completionHandler);
	}
	[DotNetType("Foundation.NSUrlSessionDataDelegate")]
	extern(DOTNET && HOST_MAC) internal class NSUrlSessionDataDelegate : NSUrlSessionTaskDelegate
	{
	}

	[DotNetType("Foundation.NSUrlAuthenticationChallenge")]
	extern(DOTNET && HOST_MAC) internal class NSUrlAuthenticationChallenge
	{
		public extern virtual NSUrlProtectionSpace ProtectionSpace { get; }
	}

	[DotNetType("Foundation.NSUrlProtectionSpace")]
	extern(DOTNET && HOST_MAC) internal class NSUrlProtectionSpace
	{
		public extern virtual string AuthenticationMethod { get; }
		
		public extern virtual string Host { get; }

		public extern Security.SecTrust ServerSecTrust { get; }
	}

	[DotNetType("Foundation.NSUrlCredential")]
	extern(DOTNET && HOST_MAC) internal class NSUrlCredential
	{
		public extern static NSUrlCredential FromTrust(Security.SecTrust trust);
	}

	[DotNetType("Foundation.NSUrlSessionAuthChallengeDisposition")]
	extern(DOTNET && HOST_MAC) internal enum NSUrlSessionAuthChallengeDisposition : long
	{
		UseCredential = 0l,
		PerformDefaultHandling,
		CancelAuthenticationChallenge,
		RejectProtectionSpace
	}
}
namespace Security
{
	[DotNetType("Security.SecTrust")]
	extern(DOTNET && HOST_MAC) internal class SecTrust
	{
		public extern SecCertificate this[int index] { get; }
		
		public extern int Count { get; }
		
		public extern SecTrustResult Evaluate();
		
		public extern void SetPolicy(SecPolicy policy);
	}
	
	public enum SecTrustResult
	{
		Invalid,
		Proceed,
		Confirm,
		Deny,
		Unspecified,
		RecoverableTrustFailure,
		FatalTrustFailure,
		ResultOtherError,
	}

	[DotNetType("Security.SecPolicy")]
	extern(DOTNET && HOST_MAC) internal class SecPolicy
	{
		public extern static SecPolicy CreateSslPolicy(bool server, string hostName);
	}

	[DotNetType("Security.SecCertificate")]
	extern(DOTNET && HOST_MAC) public class SecCertificate
	{
		public extern System.Security.Cryptography.X509Certificates.X509Certificate2 ToX509Certificate2();
		public extern Foundation.NSData DerData { get; }
		public extern string SubjectSummary { get; }

		public extern string GetCommonName();

		public extern string[] GetEmailAddresses();
		public extern Foundation.NSData GetNormalizedIssuerSequence();

		public extern Foundation.NSData GetNormalizedSubjectSequence();

		public extern Foundation.NSData GetPublicKey();

		public extern Foundation.NSData GetSerialNumber();
	}
}
