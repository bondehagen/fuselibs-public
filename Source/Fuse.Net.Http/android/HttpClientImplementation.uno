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
		void connect(string uri, Action<Java.Object> cont, Action<string> fail, Func<byte[], bool, bool> serverCertificateValidationCallback)
		@{
			HttpClientAndroid client = new HttpClientAndroid() {
				@Override
				public void onHeadersReceived(HttpURLConnection urlConnection) {
					cont.run(urlConnection);
				}
				@Override
				public void onFailure(String message) {
					fail.run(message);
				}
				@Override
				public boolean onCheckServerTrusted(java.util.List<byte[]> asn1derEncodedCert, boolean chainError) {
					return serverCertificateValidationCallback.run(new com.uno.ByteArray(asn1derEncodedCert.get(0)), chainError);
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

		bool ServerCertificateValidationCallback(byte[] asn1derEncodedCert, bool chainError)
		{
			if (_client.ServerCertificateValidationCallback != null)
			{
				var c = new X509Certificate(asn1derEncodedCert);
				var sslPolicyErrors =  chainError ? SslPolicyErrors.RemoteCertificateChainErrors : SslPolicyErrors.None;
				return _client.ServerCertificateValidationCallback(c, new X509Chain(), sslPolicyErrors);
			}
			return false;
		}
	}
}
