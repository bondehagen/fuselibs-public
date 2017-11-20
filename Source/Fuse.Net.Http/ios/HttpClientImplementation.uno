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
			foreach (var cert in _httpClient.ClientCertificates)
			{
				AddClientCertificate(cert.RawBytes, cert.Password);
			}
			Connect(request.Url, Continue, ServerCertificateValidationCallback);
			return _promise;
		}

		[Foreign(Language.ObjC)]
		void AddClientCertificate(byte[] data, string pass)
		@{
			const uint8_t *arrPtr = (const uint8_t *)[data unoArray]->Ptr();
			[@{HttpClientImplementation:Of(_this)._client:Get()} addClientCertificate:arrPtr length:[data count] password:pass]:
		@}

		bool ServerCertificateValidationCallback(byte[] asn1derEncodedCert)
		{
			if (_httpClient.ServerCertificateValidationCallback != null)
			{
				var c = new X509Certificate(asn1derEncodedCert);
				return _httpClient.ServerCertificateValidationCallback(c, new X509Chain(), (SslPolicyErrors)(int)0);
			}
			return false;
		}

		void Continue(ObjC.Object response, byte[] data)
		{
			if (response != null)
			{
				_promise.Resolve(new Response(new ResponseImplementation(response, data)));
			}
			else
			{
				_promise.Reject(new Exception("SendAsync failed"));
			}
			_client = null;
		}

		[Foreign(Language.ObjC)]
		void Connect(string strURL, Action<ObjC.Object, byte[]> completeHandler, Func<byte[], bool> serverCertificateValidationCallback)
		@{
			[@{HttpClientImplementation:Of(_this)._client:Get()} connect:strURL
				onCompleteHandler:^(NSHTTPURLResponse * response, uint8_t * data, NSUInteger length) {
					id<UnoArray> arr = @{byte[]:New((int)length)};
					memcpy(arr.unoArray->Ptr(), data, length);
					completeHandler(response, arr);
				}
				onCheckServerCertificate: ^ BOOL(uint8_t * data, NSUInteger length) {
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
}
