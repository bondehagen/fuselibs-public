using Uno;
using Uno.Threading;

namespace Fuse.Net.Http
{
	using Foundation;
	using Security;

	extern(DOTNET && HOST_MAC) class HttpClientImplementation : NSUrlSessionDelegate
	{
		Promise<Response> _response;
		HttpClient _client;

		public HttpClientImplementation(HttpClient client)
		{
			_client = client;
			//NSApplication.Init();
			_response = new Promise<Response>();
		}
		
		public Future<Response> SendAsync(Request request)
		{
			var url = NSUrl.FromString(request.Url);
			var nsUrlRequest = NSUrlRequest.FromUrl(url);

			using (var configuration = NSUrlSessionConfiguration.DefaultSessionConfiguration)
			{
				var _session = NSUrlSession.FromConfiguration(configuration, this, null);
				//var _session = NSUrlSession.SharedSession;
				var task = _session.CreateDataTask(nsUrlRequest, Callback);
				task.Resume();
			}
			return _response;
		}

		void Callback(NSData data, NSUrlResponse urlResponse, NSError error) 
		{
			try
			{
				if (urlResponse != null)
				{
					_response.Resolve(new Response(new ResponseImplementation((NSHttpUrlResponse)urlResponse, data)));
					return;
				}
				if (error != null)
				{
					_response.Reject(new Exception(error.ToString()));
					return;
				}
				_response.Reject(new Exception("Something wrong happened"));
			}
			catch (Exception e)
			{
				_response.Reject(e);
			}
		}
		
		public override void DidBecomeInvalid(NSUrlSession session, NSError error)
		{
			debug_log "DidBecomeInvalid";
		}

		public override void DidFinishEventsForBackgroundSession(NSUrlSession session)
		{
			debug_log "DidFinishEventsForBackgroundSession";
		}

		public override void DidReceiveChallenge(NSUrlSession session, NSUrlAuthenticationChallenge challenge, Action<NSUrlSessionAuthChallengeDisposition, NSUrlCredential> completionHandler)
		{
			if (_client.ServerCertificateValidationCallback != null)
			{
				var secCertificateRef = challenge.ProtectionSpace.ServerSecTrust;
				var protectionSpace = challenge.ProtectionSpace;
				//debug_log protectionSpace.Host;

				var secTrust = protectionSpace.ServerSecTrust;
				var certificate = secTrust[0];
 				var x509 = certificate.ToX509Certificate2();
				var c = new Fuse.Security.X509Certificate(x509.RawData);
				var result = _client.ServerCertificateValidationCallback(c, new Fuse.Security.X509Chain(), (SslPolicyErrors)(int)0);
				if (result)
				{
					if(protectionSpace.AuthenticationMethod == "NSURLAuthenticationMethodServerTrust")
					{
						//if(challenge.ProtectionSpace.Host == "uno-http-testing.azurewebsites.net")
						//{
							var credential = NSUrlCredential.FromTrust(challenge.ProtectionSpace.ServerSecTrust);
							completionHandler(NSUrlSessionAuthChallengeDisposition.UseCredential, credential);
							return;
						//}
					}
				}
			}
			completionHandler(NSUrlSessionAuthChallengeDisposition.CancelAuthenticationChallenge, null);
		}
	}
}
