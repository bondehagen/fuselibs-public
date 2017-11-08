using Uno;
using Uno.Collections;

namespace Fuse.Net.Http
{
	extern(!Android) internal class ResponseImplementation
	{
		public int GetStatusCode()
		{
			return 0;			
		}

		public IEnumerable<string> GetHeader(string key)
		{
			return null;
		}
		
		public IDictionary<string, IEnumerable<string>> GetHeaders()
		{
			return null;
		}
	}
	public class Response
	{
		readonly ResponseImplementation _impl;

		internal Response(ResponseImplementation impl)
		{
			_impl = impl;
		}

		public int StatusCode { get { return _impl.GetStatusCode(); } }
		//public string ReasonPhrase { get; private set; }
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
