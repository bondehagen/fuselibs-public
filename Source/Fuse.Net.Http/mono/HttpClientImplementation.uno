using Uno;
using Uno.Threading;

namespace Fuse.Net.Http
{
	using Foundation;
	using global::Security;

	extern(DOTNET && HOST_MAC) class HttpClientImplementation : NSUrlSessionDataDelegate
	{
		Promise<Response> _response;
		HttpClient _client;
		bool _autoRedirect;

		public HttpClientImplementation(HttpClient client)
		{
			_client = client;
		}

		public Future<Response> SendAsync(Request request)
		{
			_response = new Promise<Response>();
			var url = NSUrl.FromString(request.Url);
			var nsUrlRequest = new NSMutableUrlRequest(url);
			nsUrlRequest.HttpMethod = request.Method;
			
			using (var configuration = NSUrlSessionConfiguration.DefaultSessionConfiguration)
			{
				if (_client.Proxy != null)
				{
					var values = new NSObject[]
					{
						NSObject.FromObject(_client.Proxy.Address.Host),
						NSNumber.FromInt32(_client.Proxy.Address.Port),
						NSNumber.FromInt32(1),

						NSObject.FromObject(_client.Proxy.Address.Host),
						NSNumber.FromInt32(_client.Proxy.Address.Port),
						NSNumber.FromInt32(1),
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
				}
				
				_autoRedirect = _client.AutoRedirect;

				
				if(_client.ClientCertificates != null && _client.ClientCertificates.Count > 0)
				{
					var c = _client.ClientCertificates[0];
					var password = c.Password;
					var certData = c.RawBytes;

					_identity = SecIdentity.Import(certData, password);
				}

				var _session = NSUrlSession.FromConfiguration(configuration, this, null);
				debug_log "ready to send";
				var task = _session.CreateDataTask(nsUrlRequest, Callback);
				task.Resume();
			}
			return _response;
		}
		
		SecIdentity _identity;
		
		void Callback(NSData data, NSUrlResponse urlResponse, NSError error) 
		{
			debug_log "callback";
			try
			{
				if (urlResponse != null)
				{
					_response.Resolve(new Response(new ResponseImplementation((NSHttpUrlResponse)urlResponse, data)));
					return;
				}
				if (error != null)
				{
					debug_log "callback error";
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
		}

		public override void DidFinishEventsForBackgroundSession(NSUrlSession session)
		{
		}
		
		public override void WillPerformHttpRedirection(NSUrlSession session, NSUrlSessionTask task, NSHttpUrlResponse response, NSUrlRequest newRequest, Action<NSUrlRequest> completionHandler)
		{
			if (response == null || _autoRedirect)
				completionHandler(newRequest);
			else
				completionHandler(null);
		}

		public override void DidReceiveChallenge(NSUrlSession session, NSUrlAuthenticationChallenge challenge, Action<NSUrlSessionAuthChallengeDisposition, NSUrlCredential> completionHandler)
		{
			debug_log "DidReceiveChallenge";
			try 
			{
				var protectionSpace = challenge.ProtectionSpace;
				var authenticationMethod = protectionSpace.AuthenticationMethod;
				
				if (authenticationMethod == "NSURLAuthenticationMethodClientCertificate")
				{
					if(_identity != null)
					{
						var trust = new SecTrust(_identity.Certificate, SecPolicy.CreateBasicX509Policy());
						SecCertificate[] certificates = new SecCertificate[] { _identity.Certificate };
						var credential = NSUrlCredential.FromIdentityCertificatesPersistance(_identity, certificates, NSUrlCredentialPersistence.ForSession);
						//var credential = new NSUrlCredential(trust);
						if(credential != null)
						{
							completionHandler(NSUrlSessionAuthChallengeDisposition.UseCredential, credential);
							return;
						}
					}
				}
				else if(authenticationMethod == "NSURLAuthenticationMethodServerTrust")
				{
					if (_client.ServerCertificateValidationCallback != null)
					{
						// Get remote certificate
						var serverTrust = protectionSpace.ServerSecTrust; // contains the server's SSL certificate data
						var certificate = serverTrust[0];

						// var hostname = challenge.ProtectionSpace.Host;
						var x509 = certificate.ToX509Certificate2();
						var c = new Fuse.Security.X509Certificate(x509.RawData);
						var result = _client.ServerCertificateValidationCallback(c, (Fuse.Security.SslPolicyErrors)(int)0);
						if (result)
						{
							var credential = NSUrlCredential.FromTrust(protectionSpace.ServerSecTrust);
							completionHandler(NSUrlSessionAuthChallengeDisposition.UseCredential, credential);
							return;
						}
					}
					else
					{
						// default behaviour
						completionHandler(NSUrlSessionAuthChallengeDisposition.PerformDefaultHandling, null);
						return;
					}
				}
				else
				{
					debug_log "can this happen?";
					completionHandler(NSUrlSessionAuthChallengeDisposition.PerformDefaultHandling, null);
					return;
				}


			} catch (Exception e)
			{
				debug_log e.Message;
				debug_log e.StackTrace;
			}

			completionHandler(NSUrlSessionAuthChallengeDisposition.CancelAuthenticationChallenge, null);
		}
	}
}
