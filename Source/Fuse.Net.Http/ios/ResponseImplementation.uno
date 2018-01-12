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
		byte[] _data;
		IDictionary<string, IEnumerable<string>> _headers;

		internal ResponseImplementation(ObjC.Object response, byte[] data)
		{
			_response = response;
			_data = data;
		}
		
		[Foreign(Language.ObjC)]
		public int GetStatusCode()
		@{
			NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)@{ResponseImplementation:Of(_this)._response:Get()};
			return [httpResponse statusCode];
		@}

		public IDictionary<string, IEnumerable<string>> GetHeaders()
		{
			_headers = new Dictionary<string, IEnumerable<string>>();
			GetHeaderFields(Add);
			return _headers;
		}

		void Add(string key, string val)
		{
			_headers.Add(key, new [] { val });
		}

		[Foreign(Language.ObjC)]
		void GetHeaderFields(Action<string, string> add)
		@{
			NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)@{ResponseImplementation:Of(_this)._response:Get()};
			NSDictionary *headers = [httpResponse allHeaderFields];
			[headers enumerateKeysAndObjectsUsingBlock: ^(NSString *key, NSString *val, BOOL *stop)
			{
				add(key, val);
			}];
		@}

		public string GetBodyAsString()
		{
			return Uno.Text.Utf8.GetString(_data);
		}

		public byte[] GetBodyAsByteArray()
		{
			return _data;
		}
	}
}
