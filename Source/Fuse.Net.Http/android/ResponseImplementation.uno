using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

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
			return ForeignHttpHeaderBridge.FromMapToDictionary(GetHeaderFields());
		}

		[Foreign(Language.Java)]
		Java.Object GetHeaderFields()
		@{
			HttpURLConnection connection = (HttpURLConnection)@{ResponseImplementation:Of(_this)._urlConnection:Get()};
			return connection.getHeaderFields();
		@}
		
		public Uno.IO.Stream GetBodyAsStream()
		{
			return new JavaStream(GetInputStream(), GetOutputStream());
		}
		
		[Foreign(Language.Java)]
		Java.Object GetInputStream()
		@{
			try {
				HttpURLConnection connection = (HttpURLConnection)@{ResponseImplementation:Of(_this)._urlConnection:Get()};
				if ("gzip".equals(connection.getContentEncoding())) {
					return new java.util.zip.GZIPInputStream(connection.getInputStream());
				} else if ("deflate".equals(connection.getContentEncoding())) {
					return new java.util.zip.InflaterInputStream(connection.getInputStream());
				}
				return connection.getInputStream();
			} catch (IOException e) {
				// TODO
			}
			return null;
		@}

		[Foreign(Language.Java)]
		Java.Object GetOutputStream()
		@{
			try {
				HttpURLConnection connection = (HttpURLConnection)@{ResponseImplementation:Of(_this)._urlConnection:Get()};
				return connection.getOutputStream();
			} catch (IOException e) {
				// TODO
			}
			return null;
		@}

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
			return null;
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
			return null;
		@}

		[Foreign(Language.Java)]
		public void Dispose()
		@{
			// TODO: This need to be on HttpClient https://developer.android.com/reference/java/net/HttpURLConnection.html#disconnect() 
			//((HttpURLConnection)_urlConnection).disconnect();
			//_urlConnection = null;
		@}
	}
}
