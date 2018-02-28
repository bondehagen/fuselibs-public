using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Uno.Threading;

namespace Foundation
{
	[DotNetType("Foundation.NSObject")]
	extern(DOTNET && HOST_MAC) public class NSObject
	{
		public extern object Handle { get; }
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
		public extern NSString(string val);
	}

	[DotNetType("Foundation.NSNumber")]
	extern(DOTNET && HOST_MAC) public class NSNumber : NSValue
	{
		public extern static NSNumber FromInt32(int number);
	}
	
	[DotNetType("Foundation.NSDictionary")]
	extern(DOTNET && HOST_MAC) public class NSDictionary : Uno.Collections.Dictionary<Object, Object>
	{
		public extern static NSDictionary FromObjectAndKey(NSObject obj, string key);
		public extern static NSDictionary FromObjectsAndKeys(NSObject[] objects, NSObject[] keys);
		public extern NSObject[] Keys { get; }
		public extern NSObject this[NSObject key] { get; }
		public extern object this[int index] { get; }
		public extern NSObject this[string key] { get; }
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
		// https://developer.xamarin.com/api/type/Foundation.NSUrlRequest/
		public extern virtual NSUrl Url { get; }
	}
	
	[DotNetType("Foundation.NSMutableUrlRequest")]
	extern(DOTNET && HOST_MAC) internal class NSMutableUrlRequest : NSUrlRequest
	{
		public extern NSMutableUrlRequest(NSUrl url);
		public extern virtual string HttpMethod { get; set; }
		//public virtual NSData Body { get; set; }
		public virtual NSInputStream BodyStream { get; set; }
		public virtual NSDictionary Headers { get; set; }
			//CachePolicy = NSUrlRequestCachePolicy.UseProtocolCachePolicy,
		// public String this [String key] { get; set; }
		// public virtual Boolean ShouldHandleCookies { get; set; }
	}

	[DotNetType("Foundation.NSUrlSession")]
	extern(DOTNET && HOST_MAC) internal class NSUrlSession
	{
		public extern static NSUrlSession FromConfiguration(NSUrlSessionConfiguration configuration, NSUrlSessionDelegate urlSessionDelegate, object delegateQueue);
		/*public static NSUrlSession SharedSession
		{
			get
			{
				return null;
			}
		}*/

		public extern virtual NSUrlSessionDataTask CreateDataTask(NSUrlRequest request, NSUrlSessionResponse completionHandler);
		public extern virtual NSUrlSessionDataTask CreateDataTask(NSUrlRequest request);
	}

	[DotNetType("Foundation.NSUrlSessionResponse")]
	extern(DOTNET && HOST_MAC) internal delegate void NSUrlSessionResponse(NSData data, NSUrlResponse response, NSError error);



	[DotNetType("Foundation.NSUrlResponse")]
	extern(DOTNET && HOST_MAC) internal class NSUrlResponse
	{}
	
	[DotNetType("Foundation.NSHttpUrlResponse")]
	extern(DOTNET && HOST_MAC) internal class NSHttpUrlResponse : NSUrlResponse
	{
		public extern int StatusCode { get; }
		public extern NSDictionary AllHeaderFields { get; }
	}

 	[DotNetType("Foundation.NSInputStream")]
	extern(DOTNET && HOST_MAC) internal class NSInputStream
	{
		//public NSInputStream (NSData data)
		//HasBytesAvailable() : Boolean
		//Read(Byte[], UInt32) : Int32
	}

	[DotNetType("Foundation.NSError")]
	extern(DOTNET && HOST_MAC) internal class NSError
	{
		public extern virtual string LocalizedFailureReason { get; }
	}

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
		public extern virtual bool HttpShouldUsePipelining { get; set; }
	}

	[DotNetType("Foundation.NSUrlSessionTask")]
	extern(DOTNET && HOST_MAC) internal class NSUrlSessionTask
	{
		//https://developer.xamarin.com/api/type/Foundation.NSUrlSessionTask/
		public extern void Resume();
		public extern void Cancel();
	}

	[DotNetType("Foundation.NSUrlSessionDataTask")]
	extern(DOTNET && HOST_MAC) internal class NSUrlSessionDataTask : NSUrlSessionTask
	{}
	
	[DotNetType("Foundation.NSUrlSessionStreamTask")]
	extern(DOTNET && HOST_MAC) internal class NSUrlSessionStreamTask :  NSUrlSessionTask
	{
		public extern virtual void CaptureStreams();
		// more methods https://developer.xamarin.com/api/type/Foundation.NSUrlSessionStreamTask/
	}
	
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
		// https://developer.xamarin.com/api/type/Foundation.NSUrlSessionTaskDelegate/
		public extern virtual void DidCompleteWithError (NSUrlSession session, NSUrlSessionTask task, NSError error);
		public extern virtual void DidSendBodyData (NSUrlSession session, NSUrlSessionTask task, int bytesSent, int totalBytesSent, int totalBytesExpectedToSend);
		public extern virtual void WillPerformHttpRedirection(NSUrlSession session, NSUrlSessionTask task,
			NSHttpUrlResponse response, NSUrlRequest newRequest, Action<NSUrlRequest> completionHandler);
	}
	[DotNetType("Foundation.NSUrlSessionDataDelegate")]
	extern(DOTNET && HOST_MAC) internal class NSUrlSessionDataDelegate : NSUrlSessionTaskDelegate
	{
		public extern virtual void DidBecomeStreamTask(NSUrlSession session, NSUrlSessionDataTask dataTask, NSUrlSessionStreamTask streamTask);
		public extern virtual void DidReceiveData(NSUrlSession session, NSUrlSessionDataTask dataTask, NSData data);
		public extern virtual void DidReceiveResponse(NSUrlSession session, NSUrlSessionDataTask dataTask, NSUrlResponse response, Action<NSUrlSessionResponseDisposition> completionHandler);
		public extern virtual void WillCacheResponse(NSUrlSession session, NSUrlSessionDataTask dataTask, NSCachedUrlResponse proposedResponse, Action<NSCachedUrlResponse> completionHandler);
	}

	[DotNetType("Foundation.NSUrlSessionResponseDisposition")]
	extern(DOTNET && HOST_MAC) internal enum NSUrlSessionResponseDisposition : long
	{
		Cancel = 0l,
		Allow,
		BecomeDownload,
		BecomeStream
	}
	
	[DotNetType("Foundation.NSCachedUrlResponse")]
	extern(DOTNET && HOST_MAC) internal class NSCachedUrlResponse
	{
		public extern virtual NSUrlCacheStoragePolicy StoragePolicy { get; }
	}

	[DotNetType("Foundation.NSUrlCacheStoragePolicy")]
	extern(DOTNET && HOST_MAC) internal enum NSUrlCacheStoragePolicy : ulong
	{
		Allowed = 0ul,
		AllowedInMemoryOnly,
		NotAllowed
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
		public extern NSUrlCredential(Security.SecTrust trust);
		public extern NSUrlCredential(Security.SecIdentity identity, Security.SecCertificate[] certificates, NSUrlCredentialPersistence persistence);
		public extern static NSUrlCredential FromTrust(Security.SecTrust trust);
		public extern static NSUrlCredential FromIdentityCertificatesPersistance(Security.SecIdentity identity, Security.SecCertificate[] certificates, NSUrlCredentialPersistence persistence);
	}

	[DotNetType("Foundation.NSUrlCredentialPersistence")]
	extern(DOTNET && HOST_MAC) internal enum NSUrlCredentialPersistence : ulong
	{
		None = 0ul,
		ForSession,
		Permanent,
		Synchronizable
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
		public extern SecTrust(SecCertificate cert, SecPolicy policy);

		public extern SecTrust(System.Security.Cryptography.X509Certificates.X509Certificate cert, SecPolicy policy);

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
	extern(DOTNET && HOST_MAC) public class SecPolicy
	{
		public extern static SecPolicy CreateSslPolicy(bool server, string hostName);
		public extern static SecPolicy CreateBasicX509Policy();
	}

	[DotNetType("Security.SecCertificate")]
	extern(DOTNET && HOST_MAC) public class SecCertificate
	{
		public extern SecCertificate(byte[] data);

		public extern System.Security.Cryptography.X509Certificates.X509Certificate2 ToX509Certificate2();
		/*public extern X509Certificate2 ToX509Certificate2();*/
		public extern Foundation.NSData DerData { get; }
		public extern string SubjectSummary { get; }

		public extern string GetCommonName();

		public extern string[] GetEmailAddresses();
// ios10
		public extern Foundation.NSData GetNormalizedIssuerSequence();

		public extern Foundation.NSData GetNormalizedSubjectSequence();

		public extern Foundation.NSData GetPublicKey();

		public extern Foundation.NSData GetSerialNumber();

		//public static extern nint GetTypeID();
	}

	[DotNetType("Security.SecIdentity")]
	extern(DOTNET && HOST_MAC) public class SecIdentity
	{
		public extern static SecIdentity Import(byte[] data, string password);
		public extern SecCertificate Certificate { get; }
	}
	[DotNetType("Security.SecImportExport")]
	extern(DOTNET && HOST_MAC) public class SecImportExport
	{
		public extern static SecStatusCode ImportPkcs12(byte[] buffer, Foundation.NSDictionary options, out Foundation.NSDictionary[] array);
		public extern static Foundation.NSString Identity { get; }
		public extern static Foundation.NSString Passphrase { get; }
	}

	[DotNetType("Security.SecStatusCode")]
	extern(DOTNET && HOST_MAC) public enum SecStatusCode
	{
	}
}
