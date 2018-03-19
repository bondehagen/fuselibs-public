using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

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
			if (client == null)
				throw new ArgumentNullException("client");

			_client = client;
		}

		public Uno.Threading.Future<Response> SendAsync(Request request)
		{
			if (request == null)
				throw new ArgumentNullException("request");

			_promise = new Uno.Threading.Promise<Response>();

			try
			{
				Java.Object headers = ForeignHttpHeaderBridge.FromDictionaryToMap(request.Headers);
				string phost = null;
				int pport = 0;
				if (_client.Proxy != null)
				{
					phost = _client.Proxy.Address.Host;
					pport = _client.Proxy.Address.Port;
				}

				var client = send2(request.Url, request.Method, headers, _client.AutoRedirect, phost,
					pport, _client.Timeout, request.EnableCache, Continue, Fail, Timeout, ServerCertificateValidationCallback);

				if(client == null)
					throw new Exception("could not create client object");

				/*foreach (var cert in _client.ClientCertificates)
				{
					SetClientCert(cert, client, cert.Password);
				}*/
			} 
			catch (Exception e)
			{
				debug_log e.ToString();
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
		Java.Object send2(string url, string httpMethod, Java.Object headers, bool followRedirects, string proxyAddress,
			int proxyPort, int timeout, bool enableCache,
			Action<Java.Object> cont,
			Action<string> fail,
			Action<string> timeoutCallback,
			Func<byte[], bool, bool> serverCertificateValidationCallback)
		@{
			try {
				android.util.Log.d("UnoHttp", " ---- SEND2");
				HttpMessage message = new HttpMessage(url, httpMethod, (java.util.Map<String, java.util.List<String>>)headers, followRedirects, proxyAddress, proxyPort, timeout, enableCache) {
					@Override
					public void onHeadersReceived(HttpURLConnection urlConnection) {
						cont.run(urlConnection);
					}
					@Override
					public void onFailure(String message) {
						fail.run(message);
					}
					@Override
					public void onTimeout(String message) {
						timeoutCallback.run(message);
					}
					@Override
					public boolean onCheckServerTrusted(java.util.List<byte[]> asn1derEncodedCert, boolean chainError) {
						return serverCertificateValidationCallback.run(new com.uno.ByteArray(asn1derEncodedCert.get(0)), chainError);
					}
				};
				HttpClientAndroid c = new HttpClientAndroid(message);
				c.execute();
				return c;
			} catch(java.lang.Exception e) {
				e.printStackTrace();
			}
			return null;
		@}

		void Continue(Java.Object urlConnection)
		{
			_promise.Resolve(new Response(new ResponseImplementation(urlConnection)));
		}
		
		void Fail(string error)
		{
			_promise.Reject(new Exception(error));
		}
		
		void Timeout(string error)
		{
			_promise.Reject(new TimeoutException(error));
		}

		bool ServerCertificateValidationCallback(byte[] asn1derEncodedCert, bool chainError)
		{
			if (_client.ServerCertificateValidationCallback != null)
			{
				//var sslPolicyErrors =  chainError ? SslPolicyErrors.RemoteCertificateChainErrors : SslPolicyErrors.None;
				return _client.ServerCertificateValidationCallback(new List<byte[]>() { asn1derEncodedCert }, "hostname");
			}
			return false;
		}
	}
}
