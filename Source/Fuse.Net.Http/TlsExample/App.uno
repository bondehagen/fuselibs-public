using Uno;
using Uno.IO;
using Uno.Threading;
using Fuse.Net.Http;
using Fuse.Security;

public partial class App2
{
	HttpClient _client;

	public App2()
	{
		_client = new HttpClient();
		//_client.ClientCertificates.Add(LoadClientCertificateFromBundle());
		_client.ServerCertificateValidationCallback = ValidateServerCertificate;

		InitializeUX();
	}

	X509Certificate LoadCertificateFromBundle(string bundleFilename)
	{
		var bundleFile = Bundle.Get().GetFile(bundleFilename);
		return LoadCertificateFromBytes.Load(bundleFile.ReadAllBytes());
	}

	bool ValidateServerCertificate(X509Certificate serverCert, X509Chain certificateChain, SslPolicyErrors sslPolicyErrors)
	{
		debug_log "ValidateServerCertificate";
		debug_log "Subject: " + serverCert.Certificate.Subject.Name;
		debug_log "Issuer: " + serverCert.Certificate.Issuer.Name;
		// TODO: trusting the self-signed server certificate through ssl pinning, with a cert loaded from bundle
		// ios https://infinum.co/the-capsized-eight/how-to-make-your-ios-apps-more-secure-with-ssl-pinning
		// android https://infinum.co/the-capsized-eight/securing-mobile-banking-on-android-with-ssl-certificate-pinning https://medium.com/@appmattus/android-security-ssl-pinning-1db8acb6621e
		// do pinning against the public key (SubjectPublicKeyInfo)
		// or we can just check if there is a CA installed that accepts the server.
		// maybe both
		var localCert = LoadCertificateFromBundle("mitmproxy.pem");
		if (localCert.Certificate.SubjectPublicKeyInfo.ToString() == serverCert.Certificate.SubjectPublicKeyInfo.ToString())
			return true;

		if (sslPolicyErrors == SslPolicyErrors.None)
		{
			return true;
		}
		debug_log "SSL/TLS validation errors occured " + sslPolicyErrors;
		return false;
	}

	void SendRequest(object a1, EventArgs a2)
	{
		try
		{
			if (!this.isBusy.IsActive)
			{
				this.isBusy.IsActive = true;
				var request = new Request("GET", "https://fusetools.com");
				_client.Send(request).Then(HandleResponse, Error);
			}
		}
		catch(Exception e)
		{
			debug_log e.Message;
			debug_log e.StackTrace;
		}
	}

	void HandleResponse(Response response)
	{
		try
		{
			if (response != null)
			{
				debug_log "----- StatusCode -----";
				debug_log response.StatusCode + " " + response.ReasonPhrase;
				debug_log "----- Headers --------";
				foreach (var item in response.GetHeaders())
				{
					var header = item.Key + ":";
					foreach (var v in item.Value)
						header += "  " + v;

					debug_log header;
				}
				debug_log "----- Body -----------";
				var body = response.GetBodyAsString();
				//var bbody = response.GetBodyAsByteArray();
				debug_log body.Substring(0, 200);
				debug_log "----------------------";
			}
			else
			{
				debug_log "response was null";
			}
		}
		catch(Exception e)
		{
			debug_log e.Message;
			debug_log e.StackTrace;
		}
		response = null;
		this.isBusy.IsActive = false;
	}
	
	void PrintString(Response response, string content)
	{
		debug_log content;
	}

	/*void ConvertStream(Response response, Stream stream)
	{
		using(var streamReader = new Uno.IO.streamReader())
		{
			PrintString(response, streamReader.ReadToEnd());
		}
	}*/

	void Error(Exception exception)
	{
		debug_log "Request failed: " + exception.Message;
		this.isBusy.IsActive = false;
	}
}
