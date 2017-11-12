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

	X509Certificate LoadClientCertificateFromBundle()
	{
		var bundleFile = Bundle.Get().GetFile("msdnmicrosoftcom.der");
		return LoadCertificateFromBytes.Load(bundleFile.ReadAllBytes());
	}

	bool ValidateServerCertificate(X509Certificate certificate, X509Chain certificateChain, SslPolicyErrors sslPolicyErrors)
	{
		debug_log "ValidateServerCertificate";
		debug_log certificate.ToString();
		if (sslPolicyErrors == SslPolicyErrors.None)
		{
			// do some validation
			return true;
		}
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
		try
		{
			if (response != null)
			{
				debug_log response.StatusCode;
				foreach (var item in response.GetHeaders())
				{
					debug_log item.Key;
					foreach (var v in item.Value)
						debug_log "  " + v;
				}
				//response.Body.AsString().Then(PrintString, Error);
				//response.Body.AsStream().Then(ConvertStream, Error);
				debug_log "header done";
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
