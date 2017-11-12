using Uno;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;
using Uno.Collections;
using Fuse.Security;

namespace Fuse.Net.Http
{
	extern(iOS) internal class ResponseImplementation
	{
		ObjC.Object _response;
		IDictionary<string, IEnumerable<string>> _headers;

		internal ResponseImplementation(ObjC.Object response)
		{
			_headers = new Dictionary<string, IEnumerable<string>>();
			_response = response;
		}
		
		/*public int GetVersion()
		{
			return ((HttpURLConnection)_urlConnection).();
		}*/
		
		[Foreign(Language.ObjC)]
		public int GetStatusCode()
		@{
			NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)@{ResponseImplementation:Of(_this)._response:Get()};
			return [httpResponse statusCode];
		@}

		string _statusLine = "";

		public IDictionary<string, IEnumerable<string>> GetHeaders()
		{
			var dict = new Dictionary<string, IEnumerable<string>>();
			foreach (var header in GetHeaderFields().Split(new [] { '\n' }))
			{
				var items = header.Split(new [] { ':' });
				var key = items[0];
				var values = new string [0];
				if (items.Length > 1)
					values = new string [] { items[1] };

				dict.Add(key, values);
			}
			return _headers;
		}

		[Foreign(Language.ObjC)]
		string GetHeaderFields()
		@{
			NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)@{ResponseImplementation:Of(_this)._response:Get()};
			NSDictionary *headers = [httpResponse allHeaderFields];
			__block NSString * result = @"";
			[headers enumerateKeysAndObjectsUsingBlock: ^(NSString *key, NSString *val, BOOL *stop)
			{
				result = [result stringByAppendingString:key];
				result = [result stringByAppendingString:val];
			}];
			return result;
		@}

		[Foreign(Language.ObjC)]
		public IEnumerable<string> GetHeader(string key)
		@{
			/**/
			return null;
		@}
	}
}
