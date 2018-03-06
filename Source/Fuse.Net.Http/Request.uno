using Uno;
using Uno.Collections;

namespace Fuse.Net.Http
{
	public class Request
	{
		public string Url { get; set; }
		public string Method { get; set; }
		public bool EnableCache { get; set; }
		public IDictionary<string, IList<string>> Headers;
		
		public Request(string method, string url)
		{
			Method = method;
			Url = url;
			Headers = new Dictionary<string, IList<string>>();
		}

		public void SetHeader(string name, string value)
		{
			if (Headers == null)
				Headers = new Dictionary<string, IList<string>>();
			
			if (Headers.ContainsKey(name))
				Headers[name].Add(value);
			else
				Headers.Add(name, new List<string>() { value } );
		}

		public void SetBody(string data)
		{
			SetBody(Uno.Text.Utf8.GetBytes(data));
		}
		internal byte[] Data;
		public void SetBody(byte[] data)
		{
			Data = data;
		}
	}
}
