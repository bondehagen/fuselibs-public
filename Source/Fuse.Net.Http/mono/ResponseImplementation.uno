using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Security;

namespace Fuse.Net.Http
{
	extern(DOTNET && HOST_MAC) class ResponseImplementation
	{
		readonly Foundation.NSHttpUrlResponse _response;
		readonly Foundation.NSData _data;

		public ResponseImplementation(Foundation.NSHttpUrlResponse response, Foundation.NSData data)
		{
			_response = response;
			_data = data;
		}

		public int GetStatusCode()
		{
			return _response.StatusCode;		
		}

		public IEnumerable<string> GetHeader(string key)
		{
			return new string[0];
		}
		
		public IDictionary<string, IEnumerable<string>> GetHeaders()
		{
			var en = httpUrlResponse.AllHeaderFields;
			var dict = new Dictionary<string, IEnumerable<string>>(); 
			foreach (var key in en.Keys)
			{
				var v = en[key];
				dict.Add(key, v.Split(","));
			}
			return dict;
		}

		public string GetBodyAsString()
		{
			return _data.ToString();
		}

		public byte[] GetBodyAsByteArray()
		{
			return _data.ToArray();
		}
	}
}
