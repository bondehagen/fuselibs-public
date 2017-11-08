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
			debug_log "Run";
			var url = NSUrl.FromString(request.Url);
			debug_log url.AbsoluteString;

			var nsUrlRequest = NSUrlRequest.FromUrl(url);

			using (var configuration = NSUrlSessionConfiguration.DefaultSessionConfiguration)
			{
				var _session = NSUrlSession.FromConfiguration(configuration, this, null);
				//var _session = NSUrlSession.SharedSession;
				debug_log "CreateDataTask";
				var task = _session.CreateDataTask(nsUrlRequest, Callback);
				task.Resume();
			}
			debug_log "done run";
			return _response;
		}

		void Callback(NSData data, NSUrlResponse response, NSError error) 
		{
			try
			{
				debug_log "Log:!!";
				if (response == null)
				{
					debug_log "response is null";
				}
				else
				{
					var httpResponse = new Response();
					httpResponse.ContentLength = response.ExpectedContentLength.ToString();
					_response.Resolve(httpResponse);
					return;
				}

				if (data == null)
					debug_log "data is null";
				/*else
					debug_log data.ToString();*/
				//response.Dispose();
				_response.Reject(new Exception("Something wrong happened"));
			}
			catch (Exception e)
			{
				debug_log "Errorlol " + e.Message;
				_response.Reject(e);
			}
			debug_log "log end!";
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
			debug_log "DidReceiveChallenge";
			if (_client.ServerCertificateValidationCallback != null)
			{
				
				/*
				SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    			SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
SecCertificateCopySubjectSummary(secCertificateRef)
				*/
				var secCertificateRef = challenge.ProtectionSpace.ServerSecTrust;
				var protectionSpace = challenge.ProtectionSpace;
				//debug_log protectionSpace.Host;

				var secTrust = protectionSpace.ServerSecTrust;
				var certificate = secTrust[0];
 				var x509 = certificate.ToX509Certificate2();
				var c = new Fuse.Security.X509Certificate(x509.RawData);
				var restult = _client.ServerCertificateValidationCallback(c, new Fuse.Security.X509Chain(), (SslPolicyErrors)(int)0);
			}

			
			if(challenge.ProtectionSpace.AuthenticationMethod == "NSURLAuthenticationMethodServerTrust")
			{
				if(challenge.ProtectionSpace.Host == "uno-http-testing.azurewebsites.net")
				{
					var credential = NSUrlCredential.FromTrust(challenge.ProtectionSpace.ServerSecTrust);
					completionHandler(NSUrlSessionAuthChallengeDisposition.UseCredential, credential);
					return;
				}
			}
			completionHandler(NSUrlSessionAuthChallengeDisposition.CancelAuthenticationChallenge, null);
		}
	}
}
