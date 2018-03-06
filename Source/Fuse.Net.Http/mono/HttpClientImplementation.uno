using Uno;
using Uno.Threading;

namespace Fuse.Net.Http
{
	using Foundation;
	using global::Security;

	extern(DOTNET && HOST_MAC) class HttpClientImplementation : NSUrlSessionDataDelegate, INSUrlSessionStreamDelegate
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
			nsUrlRequest.TimeoutInterval = _client.Timeout;

			foreach(var h in request.Headers)
			{
				// NOTE/TODO: Xamarin does not support addValue:forHttpHeaderField, only setValue: thus the next hack to support multiple header fields with same key. This is allowed according to 7230 spec, except for Set-Cookie header!
				var hv = "";
				foreach(var v in h.Value)
			 	{
			 		if(hv.Length > 0) hv += ",";
			 		hv += v;
				}
				nsUrlRequest[h.Key] = hv;
			}

			using (var configuration = NSUrlSessionConfiguration.DefaultSessionConfiguration)
			{
				if (_client.Proxy != null)
				{
					configuration.ConnectionProxyDictionary = ConvertProxy(_client.Proxy);
				}
				
				_autoRedirect = _client.AutoRedirect;
				
				if (_client.ClientCertificates != null && _client.ClientCertificates.Count > 0)
				{
					var c = _client.ClientCertificates[0];
					var password = c.Password;
					var certData = c.RawBytes;

					_identity = SecIdentity.Import(certData, password);
				}

				configuration.HttpShouldUsePipelining = false;
				var _session = NSUrlSession.FromConfiguration(configuration, this, null);
				debug_log "ready to send";
				//var task = _session.CreateDataTask(nsUrlRequest, Callback);
				var task = _session.CreateDataTask(nsUrlRequest);
				task.Resume();
				_session.FinishTasksAndInvalidate();
			}
			return _response;
		}
		
		NSDictionary ConvertProxy(NetworkProxy proxy)
		{
			if (proxy == null)
				throw new ArgumentNullException("proxy");

			var values = new NSObject[]
			{
				NSObject.FromObject(proxy.Address.Host),
				NSNumber.FromInt32(proxy.Address.Port),
				NSNumber.FromInt32(1),

				NSObject.FromObject(proxy.Address.Host),
				NSNumber.FromInt32(proxy.Address.Port),
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
			return NSDictionary.FromObjectsAndKeys(values, keys);
		}

		SecIdentity _identity;
		
		/*void Callback(NSData data, NSUrlResponse urlResponse, NSError error) 
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
		}*/
		
		public override void DidBecomeInvalid(NSUrlSession session, NSError error)
		{
			debug_log "DidBecomeInvalid";
		}

		/*public override void DidFinishEventsForBackgroundSession(NSUrlSession session)
		{
			debug_log "DidFinishEventsForBackgroundSession";
		}*/

		public override void DidBecomeStreamTask(NSUrlSession session, NSUrlSessionDataTask dataTask, NSUrlSessionStreamTask streamTask)
		{
			debug_log "DidBecomeStreamTask";

			streamTask.CaptureStreams();
		}

		// NOTE: This is an implementation of a	 method on INSUrlSessionStreamDelegate. The method is optional and the reason for using the Export attribute.
		[Export("URLSession:streamTask:didBecomeInputStream:outputStream:")]
		public virtual void CompletedTaskCaptureStreams(NSUrlSession session, NSUrlSessionStreamTask streamTask, NSInputStream inputStream, NSOutputStream outputStream)
		{
			debug_log "complete capture";
			debug_log streamTask.State;
			
			using (var sr = new Uno.IO.StreamReader(new MacStream(inputStream, outputStream)))
			{
				debug_log sr.ReadToEnd();
			}
		}

		[Export("URLSession:betterRouteDiscoveredForStreamTask:")]
		public virtual void BetterRouteDiscovered(NSUrlSession session, NSUrlSessionStreamTask streamTask)
		{
			debug_log "BetterRouteDiscovered";
		}

		[Export("URLSession:readClosedForStreamTask:")]
		public virtual void ReadClosed(NSUrlSession session, NSUrlSessionStreamTask streamTask)
		{
			debug_log "ReadClosed";
		}
		
		[Export("URLSession:writeClosedForStreamTask:")]
		public virtual void WriteClosed(NSUrlSession session, NSUrlSessionStreamTask streamTask)
		{
			debug_log "WriteClosed";
		}

		public override void DidReceiveData(NSUrlSession session, NSUrlSessionDataTask dataTask, NSData data)
		{
			debug_log "DidReceiveData";
			// will be called until all data is received
			debug_log data.ToString();
		}

		public override void DidReceiveResponse(NSUrlSession session, NSUrlSessionDataTask dataTask, NSUrlResponse response, Action<NSUrlSessionResponseDisposition> completionHandler)
		{
			debug_log "DidReceiveResponse";
			debug_log "BytesReceived: " + dataTask.BytesReceived;
			debug_log dataTask.State;

			//NOTE: At this point we got the headers
			var httpResponse = response as NSHttpUrlResponse;
			if (httpResponse != null)
			{
				debug_log httpResponse.StatusCode;
			}

			//completionHandler(NSUrlSessionResponseDisposition.Allow); // this will call DidReceiveData next
			completionHandler(NSUrlSessionResponseDisposition.BecomeStream);
		}

		public override void WillPerformHttpRedirection(NSUrlSession session, NSUrlSessionTask task, NSHttpUrlResponse response, NSUrlRequest newRequest, Action<NSUrlRequest> completionHandler)
		{
			debug_log "WillPerformHttpRedirection " + newRequest.Url.AbsoluteString;
			if (response == null || _autoRedirect)
				completionHandler(newRequest);
			else
				completionHandler(null);
		}
		
		public override void WillCacheResponse(NSUrlSession session, NSUrlSessionDataTask dataTask, NSCachedUrlResponse proposedResponse, Action<NSCachedUrlResponse> completionHandler)
		{
			debug_log "WillCacheResponse " + proposedResponse.StoragePolicy;
		}

		public override void DidCompleteWithError (NSUrlSession session, NSUrlSessionTask task, NSError error) 
		{
			if(error == null) {
				return;
			}
			debug_log "DidCompleteWithError";
			debug_log error.LocalizedFailureReason;
			debug_log error.ToString();
			debug_log task.GetType();
			debug_log "---";
		}
		
		public override void DidSendBodyData (NSUrlSession session, NSUrlSessionTask task, int bytesSent, int totalBytesSent, int totalBytesExpectedToSend)
		{
			debug_log "DidSendBodyData";
		}

		public override void DidReceiveChallenge(NSUrlSession session, NSUrlAuthenticationChallenge challenge, Action<NSUrlSessionAuthChallengeDisposition, NSUrlCredential> completionHandler)
		{
			debug_log "DidReceiveChallenge";
			try 
			{
				var protectionSpace = challenge.ProtectionSpace;
				var authenticationMethod = protectionSpace.AuthenticationMethod;
				debug_log authenticationMethod;
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
							var credential = NSUrlCredential.FromTrust(serverTrust);
							completionHandler(NSUrlSessionAuthChallengeDisposition.UseCredential, credential);
							return;
						}
					}
				}

				debug_log "default handling";
				completionHandler(NSUrlSessionAuthChallengeDisposition.PerformDefaultHandling, null);
				return;
			}
			catch (Exception e)
			{
				debug_log e.Message;
				debug_log e.StackTrace;
			}

			completionHandler(NSUrlSessionAuthChallengeDisposition.CancelAuthenticationChallenge, null);
		}
	}
}
