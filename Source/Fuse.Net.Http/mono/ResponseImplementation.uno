using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Foundation;

namespace Fuse.Net.Http
{
	extern(DOTNET && HOST_MAC) class ResponseImplementation
	{
		readonly NSHttpUrlResponse _response;
		readonly NSData _data;

		readonly NSInputStream _inputStream;
		readonly NSOutputStream _outputStream;

		public ResponseImplementation(NSHttpUrlResponse response, NSInputStream inputStream, NSOutputStream outputStream)
		{
			_response = response;
			_inputStream = inputStream;
			_outputStream = outputStream;
		}

		public ResponseImplementation(NSHttpUrlResponse response, NSData data)
		{
			_response = response;
			_data = data;
		}

		public int GetStatusCode()
		{
			return _response.StatusCode;
		}

		public IDictionary<string, IEnumerable<string>> GetHeaders()
		{
			var en = _response.AllHeaderFields;
			var dict = new Dictionary<string, IEnumerable<string>>(); 
			foreach (var key in en.Keys)
			{
				var v = en[key].ToString();
				dict.Add(key.ToString(), new [] { v });
			}
			return dict;
		}

		public Uno.IO.Stream GetBodyAsStream()
		{
			return new MacStream(_inputStream, _outputStream);
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
