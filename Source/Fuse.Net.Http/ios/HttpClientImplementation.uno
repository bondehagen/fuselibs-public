using Uno;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;
using Uno.Collections;
using Fuse.Security;

namespace Fuse.Net.Http
{
	[Require("Xcode.Framework", "Foundation.framework")]
	[ForeignInclude(Language.ObjC, "ios/HttpClientObjc.h")]
	extern(iOS) class HttpClientImplementation : IDisposable
	{
		ObjC.Object _client;
		Uno.Threading.Promise<Response> _promise;
		HttpClient _httpClient;

		public HttpClientImplementation(HttpClient client)
		{
			_httpClient = client;
			
		}
		
		[Foreign(Language.ObjC)]
		ObjC.Object Create()
		@{
			return [[HttpClientObjc alloc] init];
		@}

		
		public Future<Response> SendAsync(Request request)
		{
			_client = Create();
			_promise = new Uno.Threading.Promise<Response>();
			Connect(request.Url, Continue, ServerCertificateValidationCallback);
			return _promise;
		}

		bool ServerCertificateValidationCallback(byte[] asn1derEncodedCert)
		{
			if (_httpClient.ServerCertificateValidationCallback != null)
			{
				var c = new X509Certificate(asn1derEncodedCert);
				return _httpClient.ServerCertificateValidationCallback(c, new X509Chain(), (SslPolicyErrors)(int)0);
			}
			return false;
		}

		void Continue(ObjC.Object response)
		{
			if (response != null)
			{
				_promise.Resolve(new Response(new ResponseImplementation(response)));
			}
			else
			{
				_promise.Reject(new Exception("SendAsync failed"));
			}
			_client = null;
		}

		[Foreign(Language.ObjC)]
		void Connect(string strURL, Action<ObjC.Object> completeHandler, Func<byte[], bool> serverCertificateValidationCallback)
		@{
			[@{HttpClientImplementation:Of(_this)._client:Get()} connect:strURL
				onCompleteHandler:^(NSHTTPURLResponse * response) {
					completeHandler(response);
				}
				onCheckServerCertificate:^(uint8_t * data, NSUInteger length) {
					id<UnoArray> arr = @{byte[]:New((int)length)};
					memcpy(arr.unoArray->Ptr(), data, length);
					return serverCertificateValidationCallback(arr);
				}
			];
		@}

		public void Dispose()
		{
			_client = null;
		}
	}

	
	extern(iOS) internal class ResponseImplementation
	{
		ObjC.Object _response;
		IDictionary<string, IEnumerable<string>> _headers;

		internal ResponseImplementation(ObjC.Object response)
		{
			_headers = new Dictionary<string, IEnumerable<string>>();
			_response = response;
		}
		
		/*public int GetVersion()
		{
			return ((HttpURLConnection)_urlConnection).();
		}*/
		
		[Foreign(Language.ObjC)]
		public int GetStatusCode()
		@{
			NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)@{ResponseImplementation:Of(_this)._response:Get()};
			return [httpResponse statusCode];
		@}

		string _statusLine = "";

		public IDictionary<string, IEnumerable<string>> GetHeaders()
		{
			debug_log GetHeaderFields();
			return _headers;
		}

		[Foreign(Language.ObjC)]
		string GetHeaderFields()
		@{
			NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)@{ResponseImplementation:Of(_this)._response:Get()};
			NSDictionary *headers = [httpResponse allHeaderFields];
			__block NSString * result = @"";
			[headers enumerateKeysAndObjectsUsingBlock: ^(NSString *key, NSString *val, BOOL *stop)
			{
				result = [result stringByAppendingString:key];
				result = [result stringByAppendingString:val];
			}];
			return result;
		@}

		[Foreign(Language.ObjC)]
		public IEnumerable<string> GetHeader(string key)
		@{
			/**/
			return null;
		@}
	}
}
