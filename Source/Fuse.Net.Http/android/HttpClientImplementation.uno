using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Security;

namespace Fuse.Net.Http
{
	[ForeignInclude(Language.Java, "com.fusetools.http.*")]
	[ForeignInclude(Language.Java, "java.net.HttpURLConnection")]
	extern(Android) class HttpClientImplementation
	{
		Uno.Threading.Promise<Response> _promise;
		HttpClient _client;

		public HttpClientImplementation(HttpClient client)
		{
			_client = client;
		}

		public Uno.Threading.Future<Response> SendAsync(Request request)
		{
			_promise = new Uno.Threading.Promise<Response>();
			connect(request.Url, Continue, Fail, ServerCertificateValidationCallback);
			return _promise;
		}

		[Foreign(Language.Java)]
		void connect(string uri, Action<Java.Object> cont, Action<string> fail, Func<byte[], bool> serverCertificateValidationCallback)
		@{
			HttpClientAndroid client = new HttpClientAndroid() {
				public void onHeadersReceived(HttpURLConnection urlConnection) {
					cont.run(urlConnection);
				}
				public void onFailure(String message) {
					fail.run(message);
				}
				public boolean onCheckServerTrusted(byte[] asn1derEncodedCert) {
					return serverCertificateValidationCallback.run(new com.uno.ByteArray(asn1derEncodedCert));
				}
			};
			client.createRequest(uri, "", "", 0);
		@}

		void Continue(Java.Object urlConnection)
		{
			_promise.Resolve(new Response(new ResponseImplementation(urlConnection)));
		}
		
		void Fail(string error)
		{
			_promise.Reject(new Exception(error));
		}

		bool ServerCertificateValidationCallback(byte[] asn1derEncodedCert)
		{
			if (_client.ServerCertificateValidationCallback != null)
			{
				var c = new X509Certificate(asn1derEncodedCert);
				return _client.ServerCertificateValidationCallback(c, new X509Chain(), (SslPolicyErrors)(int)0);
			}
			return false;
		}
	}
}
