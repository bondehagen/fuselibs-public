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

		public int StatusCode { get { return _impl.GetStatusCode(); } }
		public string ReasonPhrase { get { return Uno.Net.Http.HttpStatusReasonPhrase.GetFromStatusCode(StatusCode); } }
		public string ContentLength { get; set; }
		public Body Body { get { return new Body(_impl); } }

		public IEnumerable<string> GetHeader(string key)
		{
			return _impl.GetHeader(key);
		}

		public IDictionary<string, IEnumerable<string>> GetHeaders()
		{
			return _impl.GetHeaders();
		}
	}
	
	public class Body
	{
		internal Body(ResponseImplementation impl)
		{}
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

/*HTTP message
	HTTP request message
		request-line
			method
			URI
			protocol version
		HeaderFields
		MessageBody
			payload body

	HTTP response message
		status-line
			HTTP-version
			status-code
			reason-phrase
		HeaderFields
*/
