using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Security;

namespace Fuse.Net.Http
{
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
		public string GetBodyAsString()
		{
			return "";
		}

		public byte[] GetBodyAsByteArray()
		{
			return new byte [0];
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
