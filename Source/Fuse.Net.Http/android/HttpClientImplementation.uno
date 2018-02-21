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
			Java.Object client = connect(request.Url, request.Method, ForeignHttpHeaderBridge.FromDictionaryToMap(request.Headers),
				_client.AutoRedirect, _client.Proxy.Address.Host, _client.Proxy.Address.Port, _client.Timeout, request.EnableCache, Continue, Fail, ServerCertificateValidationCallback);
			
			foreach (var cert in _client.ClientCertificates)
			{
				SetClientCert(cert.RawBytes, client, cert.Password);
			}
			
			return _promise;
		}
		
		[Foreign(Language.Java)]
		void SetClientCert(byte[] buf, Java.Object client, string pass)
		@{
			((HttpClientAndroid)client).AddClientCertificate(buf.copyArray(), pass);
		@}
		
		/*[Foreign(Language.Java)]
		public void Cancel(Java.Object client)
		@{
			((HttpClientAndroid)client).cancel();
		@}*/

		[Foreign(Language.Java)]
		Java.Object connect(string url, string httpMethod, Java.Object headers, bool followRedirects, string proxyAddress, int proxyPort, int timeout, bool enableCache,
			Action<Java.Object> cont, Action<string> fail, Func<byte[], bool, bool> serverCertificateValidationCallback)
		@{
			HttpClientAndroid client = new HttpClientAndroid(url, httpMethod, (java.util.Map<String, java.util.List<String>>)headers, followRedirects, proxyAddress, proxyPort, timeout, enableCache) {
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
			client.execute();
			return client;
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
				return _client.ServerCertificateValidationCallback(c, sslPolicyErrors);
			}
			return false;
		}
	}
}
