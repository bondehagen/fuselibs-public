using Uno;
using Uno.Collections;

namespace Fuse.Net.Http
{
	public class Response
	{
		readonly ResponseImplementation _impl;

		internal Response(ResponseImplementation impl)
		{
			_impl = impl;
		}
		
		~Response()
		{
			debug_log "dealloc Response";
		}

		public int StatusCode { get { return _impl.GetStatusCode(); } }
		public string ReasonPhrase { get { return Uno.Net.Http.HttpStatusReasonPhrase.GetFromStatusCode(StatusCode); } }
		public string ContentLength { get; set; }

		public Uno.IO.Stream GetBodyAsStream()
		{
			return _impl.GetBodyAsStream();
		}

		public string GetBodyAsString()
		{
			return _impl.GetBodyAsString();
		}
		
		public byte[] GetBodyAsByteArray()
		{
			return _impl.GetBodyAsByteArray();
		}

		public IEnumerable<string> GetHeader(string key)
		{
			IEnumerable<string> ret;
			if (GetHeaders().TryGetValue(key, out ret))
				return ret;

			return null;
		}

		public IDictionary<string, IEnumerable<string>> GetHeaders()
		{
			return _impl.GetHeaders();
		}
	}

	extern(!Android && !ios && !DOTNET) internal class ResponseImplementation
	{
		int _statusCode;
		string _headers;

		public ResponseImplementation() {}
		public ResponseImplementation(int version, int statusCode, string headers)
		{
			_statusCode = statusCode;
			_headers = headers;
		}

		public int GetStatusCode()
		{
			return _statusCode;		
		}

		public IEnumerable<string> GetHeader(string key)
		{
			return new string[0];
		}
		
		public IDictionary<string, IEnumerable<string>> GetHeaders()
		{
			return new Dictionary<string, IEnumerable<string>>();
		}
		
		public Uno.IO.Stream GetBodyAsStream()
		{
			return null;
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
