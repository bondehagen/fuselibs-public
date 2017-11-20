using Uno;
using Uno.IO;
using Uno.UX;
using Uno.Threading;
using Fuse.Net.Http;
using Fuse.Security;
using Fuse.Scripting;
using Fuse.Scripting.JSObjectUtils;

[UXGlobalModule]
public class HttpJSModule : NativeModule
{
	readonly HttpClient _client;
	static readonly HttpJSModule _instance;

	public HttpJSModule()
	{
		if(_instance != null) return;
		Resource.SetGlobalKey(_instance = this, "SecureHttp");

		_client = new HttpClient();

		var bundleFile = Bundle.Get().GetFile("certs/client/sender.pfx");
		var password = "1234";
		_client.ClientCertificates.Add(new X509Certificate(bundleFile.ReadAllBytes(), password));
		_client.ServerCertificateValidationCallback = ValidateServerCertificate;

		AddMember(new NativePromise<string, Fuse.Scripting.Object>("sendRequest", SendRequest, null));
	}

	Promise<string> _p;

	Future<string> SendRequest(object[] args)
	{
		_p = new Promise<string>();
		try
		{
			var request = new Request("GET", "https://192.168.1.187:80");
			_client.Send(request).Then(HandleResponse, Error);
		}
		catch(Exception e)
		{
			_p.Reject(e);
		}
		return _p;
	}

	bool ValidateServerCertificate(X509Certificate serverCert, X509Chain certificateChain, SslPolicyErrors sslPolicyErrors)
	{
		debug_log "ValidateServerCertificate";
		debug_log "Subject: " + serverCert.Certificate.Subject.Name;
		debug_log "Issuer: " + serverCert.Certificate.Issuer.Name;

		var bundleFile = Bundle.Get().GetFile("certs/server/receiver.crt");
		var localCert = new X509Certificate(bundleFile.ReadAllText());
		if (localCert.Certificate.ToString() == serverCert.Certificate.ToString())
			return true;

		return false;
	}

	void HandleResponse(Response response)
	{
		try
		{
			if (response != null)
			{
				debug_log "Got response " + response.StatusCode + " " + response.ReasonPhrase;
				var body = response.GetBodyAsString();
				_p.Resolve(body);
			}
			else
			{
				debug_log "response was null";
			}
		}
		catch(Exception e)
		{
			_p.Reject(e);
		}
	}

	void Error(Exception exception)
	{
		debug_log "Request failed: " + exception.Message;
		_p.Reject(exception);
	}
}
