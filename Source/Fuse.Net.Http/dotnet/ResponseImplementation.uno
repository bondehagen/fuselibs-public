using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Security;

namespace Fuse.Net.Http
{
	extern(DOTNET && !HOST_MAC) class ResponseImplementation
	{
		int _statusCode;
		string _headers;
		System.Net.Http.HttpResponseMessage _response;

		public ResponseImplementation(System.Net.Http.HttpResponseMessage response)
		{
			_response = response;
		}

		public int GetStatusCode()
		{
			return (int)_response.StatusCode;		
		}

		public IEnumerable<string> GetHeader(string key)
		{
			return new string[0];
		}
		
		public IDictionary<string, IEnumerable<string>> GetHeaders()
		{
			var dict = new Dictionary<string, IEnumerable<string>>();
			foreach (var header in _response.Headers.ToString().Split(new [] { '\n' }))
			{
				var items = header.Split(new [] { ':' });
				var key = items[0];
				var values = new string [0];
				if (items.Length > 1)
					values = new string [] { items[1] };

				dict.Add(key, values);
			}

			return dict;
		}

		public string GetBodyAsString()
		{
			return "";
		}

		public byte[] GetBodyAsByteArray()
		{
			return new byte [0];
		}
	}
}
