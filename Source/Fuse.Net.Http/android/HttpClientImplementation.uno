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
			HttpTest client = new HttpTest();
			client.callback = new MyCallback() {
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
			client.createRequest(uri);
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

	[ForeignInclude(Language.Java, "java.net.HttpURLConnection", "java.io.IOException")]
	extern(Android) internal class ResponseImplementation
	{
		Java.Object _urlConnection;
		IDictionary<string, IEnumerable<string>> _headers;

		internal ResponseImplementation(Java.Object urlConnection)
		{
			_urlConnection = urlConnection;
		}
		
		/*public int GetVersion()
		{
			return ((HttpURLConnection)_urlConnection).();
		}*/
		
		[Foreign(Language.Java)]
		public int GetStatusCode()
		@{
			try {
				HttpURLConnection connection = (HttpURLConnection)@{ResponseImplementation:Of(_this)._urlConnection:Get()};
				return connection.getResponseCode();
			} catch(IOException e) {
				return 0;
			}
		@}

		string _statusLine = "";

		public IDictionary<string, IEnumerable<string>> GetHeaders()
		{
			var a = new MapToDictionary(GetHeaderFields());
			var items = a.Get();
			_statusLine = a.GetStatus();
			debug_log _statusLine;
			return items;
		}

		[Foreign(Language.Java)]
		Java.Object GetHeaderFields()
		@{
			HttpURLConnection connection = (HttpURLConnection)@{ResponseImplementation:Of(_this)._urlConnection:Get()};
			return connection.getHeaderFields();
		@}

		[Foreign(Language.Java)]
		public IEnumerable<string> GetHeader(string key)
		@{
			/**/
			return null;
		@}

		class MapToDictionary
		{
			IDictionary<string, IEnumerable<string>> _dict;

			public MapToDictionary(Java.Object map)
			{
				_dict = new Dictionary<string, IEnumerable<string>>();
				ForeignLoop(map, Add, SetStatus);
			}

			[Foreign(Language.Java)]
			void ForeignLoop(Java.Object omap, Action<string, string[]> add, Action<string> setStatus)
			@{
				java.util.Map<String, java.util.List<String>> m =  (java.util.Map<String, java.util.List<String>>)omap;
				for (java.util.Map.Entry<String, java.util.List<String>> k : m.entrySet()) {
					String key = k.getKey();
					if (key == null)
						setStatus.run(k.getValue().get(0));
					else
						add.run(key, new StringArray(k.getValue().toArray(new String[0])));
				}
			@}
			string _statusLine;
			void SetStatus(string key)
			{
				_statusLine = key;
			}

			void Add(string key, string[] values)
			{
				_dict.Add(key, values);
			}
			public string GetStatus()
			{
				return _statusLine;
			}

			public IDictionary<string, IEnumerable<string>> Get()
			{
				return _dict;
			}
		}

		[Foreign(Language.Java)]
		public void Dispose()
		@{
			// TODO: This need to be on HttpClient https://developer.android.com/reference/java/net/HttpURLConnection.html#disconnect() 
			//((HttpURLConnection)_urlConnection).disconnect();
			//_urlConnection = null;
		@}

		~ResponseImplementation()
		{
			debug_log "ResponseImplementation destroyed";
		}
	}
}
