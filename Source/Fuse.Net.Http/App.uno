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
		var bundle = Uno.IO.Bundle.Get();
		//var bundleFile = bundle.GetFile("msdnmicrosoftcom.der");
		//_client.ClientCertificates.Add(LoadClientCertificateFromBundle(bundleFile));
		_client.ServerCertificateValidationCallback = ValidateServerCertificate;

		InitializeUX();
	}

	X509Certificate LoadClientCertificateFromBundle(BundleFile bundleFile)
	{
		//var foo = LoadCertificateFromBytes.Load(bundleFile.ReadAllBytes());
		return null;
	}

	bool ValidateServerCertificate(X509Certificate certificate, X509Chain certificateChain, SslPolicyErrors sslPolicyErrors)
	{
		debug_log "ValidateServerCertificate";
		debug_log certificate.ToString();
		if (sslPolicyErrors == SslPolicyErrors.None)
		{
			// Good certificate.
			return true;
		}

		/*var localServerCert = LoadLocalServerCertificate();

		bool certMatch = false; // Assume failure
		byte[] certHash = certificate.GetCertHash();
		if (certHash.Length == apiCertHash.Length)
		{
			certMatch = true; // Now assume success.
			for (int idx = 0; idx < certHash.Length; idx++)
			{
				if (certHash[idx] != apiCertHash[idx])
				{
					certMatch = false; // No match
					break;
				}
			}
		}

		return certMatch;*/
		return false;
	}

	void SendRequest(object a1, EventArgs a2)
	{
		if (!this.isBusy.IsActive)
		{
			this.isBusy.IsActive = true;
			var request = new Request("https://fusetools.com");
			_client.Send(request).Then(HandleResponse, Error);
		}
	}

	void HandleResponse(Response response)
	{
		if (response != null)
		{
			debug_log response.ContentLength;
			//response.Body.AsString().Then(PrintString, Error);
			//response.Body.AsStream().Then(ConvertStream, Error);
		}
		else
		{
			debug_log "response was null";
		}
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
