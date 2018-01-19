class HttpClient
{
	// TODO: Set default proxy statically

	NetworkProxy Proxy { get; set; }
	bool AutoRedirect { get; set; }
	int RequestTimeout { get; set; };
	
	Func<X509Certificate, SslPolicyErrors, bool> ServerCertificateValidationCallback;
	void SetClientCertificates(IList<X509Certificate> certificates);

	Future<Response> Send(Request request);
}

class Request
{
	Uri Url { get; set; }
	string Method { get; set; }
	bool EnableCache { get; set; }
	IDictionary<string, IEnumerable<string>> Headers;

	void SetHeader(string name, string value);
	void SetBody(string data);
	void SetBody(byte[] data);
	void SetBody(Stream stream);
}

class Response
{
	int StatusCode { get }
	string ReasonPhrase { get { return Uno.Net.Http.HttpStatusReasonPhrase.GetFromStatusCode(StatusCode); } }
	string ContentLength { get; set; }

	IEnumerable<string> GetHeader(string key);
	IDictionary<string, IEnumerable<string>> GetHeaders();
	string GetBodyAsString();
	byte[] GetBodyAsByteArray();
	Stream GetBodyAsStream();
}

var client = new HttpClient();
client.Send(new Request("GET", "https://<yourhost>")).Then(HandleResponse, HandleError);

void HandleResponse(Response response)
{
	debug_log response.GetBodyAsString();
}

What about Abort? Progress? and should GetBodyAsString be a future?
