using Uno;
using Uno.Threading;

namespace Fuse.Net.Http
{
	using Foundation;
	using Security;

	extern(DOTNET && HOST_MAC) class HttpClientImplementation : NSUrlSessionDataDelegate
	{
		Promise<Response> _response;
		HttpClient _client;

		public HttpClientImplementation(HttpClient client)
		{
			_client = client;
			//NSApplication.Init();
		}

		public Future<Response> SendAsync(Request request)
		{
			_response = new Promise<Response>();
			var url = NSUrl.FromString(request.Url);
			var nsUrlRequest = new NSMutableUrlRequest(url);
			nsUrlRequest.HttpMethod = request.Method;

			var proxyhost = "192.168.1.20";
			var proxyport = 8080;
			var enableProxy = 1;
			using (var configuration = NSUrlSessionConfiguration.DefaultSessionConfiguration)
			{
				var values = new NSObject[]
				{
					NSObject.FromObject(proxyhost),
					NSNumber.FromInt32(proxyport),
					NSNumber.FromInt32(enableProxy),

					NSObject.FromObject(proxyhost),
					NSNumber.FromInt32(proxyport),
					NSNumber.FromInt32(enableProxy),
				};
				var keys = new NSObject[]
				{
					NSObject.FromObject("HTTPProxy"),
					NSObject.FromObject("HTTPPort"),
					NSObject.FromObject("HTTPEnable"),
					NSObject.FromObject("HTTPSProxy"),
					NSObject.FromObject("HTTPSPort"),
					NSObject.FromObject("HTTPSEnable")
				};
				var proxyDict = NSDictionary.FromObjectsAndKeys(values, keys);
				configuration.ConnectionProxyDictionary = proxyDict;

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

			// FinishTasksAndInvalidate() ?
		}
		
		public override void DidBecomeInvalid(NSUrlSession session, NSError error)
		{
			debug_log "DidBecomeInvalid";
		}

		public override void DidFinishEventsForBackgroundSession(NSUrlSession session)
		{
			debug_log "DidFinishEventsForBackgroundSession";
		}
		
		public override void WillPerformHttpRedirection(NSUrlSession session, NSUrlSessionTask task, NSHttpUrlResponse response, NSUrlRequest newRequest, Action<NSUrlRequest> completionHandler)
		{
			debug_log "WillPerformHttpRedirection";
			completionHandler(newRequest);
		}

		public override void DidReceiveChallenge(NSUrlSession session, NSUrlAuthenticationChallenge challenge, Action<NSUrlSessionAuthChallengeDisposition, NSUrlCredential> completionHandler)
		{
			if (_client.ServerCertificateValidationCallback != null)
			{
				var protectionSpace = challenge.ProtectionSpace;

				// Get remote certificate
				var serverTrust = protectionSpace.ServerSecTrust; // contains the server's SSL certificate data
				var certificate = serverTrust[0];


				var x509 = certificate.ToX509Certificate2();
				var c = new Fuse.Security.X509Certificate(x509.RawData);
				var result = _client.ServerCertificateValidationCallback(c, (SslPolicyErrors)(int)0);
				if (result)
				{
					if(protectionSpace.AuthenticationMethod == "NSURLAuthenticationMethodServerTrust")
					{
						//if(challenge.ProtectionSpace.Host == "uno-http-testing.azurewebsites.net")
						//{
							var credential = NSUrlCredential.FromTrust(protectionSpace.ServerSecTrust);
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
