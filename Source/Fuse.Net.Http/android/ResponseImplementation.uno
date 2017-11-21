using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Security;

namespace Fuse.Net.Http
{
	[ForeignInclude(Language.Java, "java.net.HttpURLConnection", "java.io.*")]
	extern(Android) internal class ResponseImplementation
	{
		Java.Object _urlConnection;
		IDictionary<string, IEnumerable<string>> _headers;

		internal ResponseImplementation(Java.Object urlConnection)
		{
			_urlConnection = urlConnection;
		}
		
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
		public string GetBodyAsString()
		@{
			try {
				HttpURLConnection connection = (HttpURLConnection)@{ResponseImplementation:Of(_this)._urlConnection:Get()};
				InputStream input = connection.getInputStream();
				ByteArrayOutputStream result = new ByteArrayOutputStream();
				byte[] buffer = new byte[1024];
				int length;
				while ((length = input.read(buffer)) != -1) {
					result.write(buffer, 0, length);
				}

				return result.toString("UTF-8");
			} catch (UnsupportedEncodingException e) {
				e.printStackTrace(); 
			} catch (Exception e) {
				e.printStackTrace();
			}
			return "";
		@}

		[Foreign(Language.Java)]
		public byte[] GetBodyAsByteArray()
		@{
			try {
				HttpURLConnection connection = (HttpURLConnection)@{ResponseImplementation:Of(_this)._urlConnection:Get()};
				InputStream input = connection.getInputStream();
				ByteArrayOutputStream result = new ByteArrayOutputStream();
				byte[] buffer = new byte[1024];
				int length;
				while ((length = input.read(buffer)) != -1) {
					result.write(buffer, 0, length);
				}

				return new ByteArray(result.toByteArray());
			} catch (UnsupportedEncodingException e) {
				e.printStackTrace(); 
			} catch (Exception e) {
				e.printStackTrace();
			}
			return new ByteArray(0);
		@}

		[Foreign(Language.Java)]
		public void Dispose()
		@{
		@}
	}
}
