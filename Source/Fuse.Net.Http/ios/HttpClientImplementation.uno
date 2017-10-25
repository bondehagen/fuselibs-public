using Uno;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;
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
			_client = Create();
		}
		
		[Foreign(Language.ObjC)]
		ObjC.Object Create()
		@{
			return [[HttpClientObjc alloc] init];
		@}

		
		public Future<Response> SendAsync(Request request)
		{
			_promise = new Uno.Threading.Promise<Response>();
			Connect(request.Url, Continue, ServerCertificateValidationCallback);
			return _promise;
		}

		bool ServerCertificateValidationCallback(byte[] asn1derEncodedCert)
		{
			if (_httpClient.ServerCertificateValidationCallback != null)
			{
				var c = new X509Certificate("", "", asn1derEncodedCert);
				return _httpClient.ServerCertificateValidationCallback(c, new X509Chain(), (SslPolicyErrors)(int)0);
			}
			return false;
		}

		void Continue(string response)
		{
			debug_log "IsCompleted " + response;
			if (response != null)
			{
				debug_log "got response";
				
				_promise.Resolve(new Response());
			}
			else
			{
				debug_log "err";
				_promise.Reject(new Exception("SendAsync failed"));
			}
		}

		[Foreign(Language.ObjC)]
		void Connect(string strURL, Action<string> completeHandler, Func<byte[], bool> serverCertificateValidationCallback)
		@{
			[@{HttpClientImplementation:Of(_this)._client:Get()} connect:strURL
				onCompleteHandler:^(NSString * response) {
					completeHandler(response);
				}
				onCheckServerCertificate:^(uint8_t * data, NSUInteger length) {
					id<UnoArray> arr = @{byte[]:New((int)length)};
					memcpy(arr.unoArray->Ptr(), data, length);
					serverCertificateValidationCallback(arr);
				}
			];
		@}

		public void Dispose()
		{
			_client = null;
		}
	}
}
