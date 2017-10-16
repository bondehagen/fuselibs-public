using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Net.Http
{
	[ForeignInclude(Language.Java, "com.fusetools.http.*")]
	extern(Android) class HttpClientImplementation
	{
		Uno.Threading.Promise<Response> _promise;
		HttpClient _client;

		public HttpClientImplementation(HttpClient client)
		{
			_client = client;
		}

		public Uno.Threading.Future<Response> SendAsync(Request request)
		{
			_promise = new Uno.Threading.Promise<Response>();
			debug_log "Run";

			connect(request.Url, Continue, ServerCertificateValidationCallback);

			return _promise;
		}
		
		bool ServerCertificateValidationCallback(string subject, string thumbprint)
		{
			if (_client.ServerCertificateValidationCallback != null)
			{
				var c = new X509Certificate(subject, "", thumbprint);
				return _client.ServerCertificateValidationCallback(c, new X509Chain(), (SslPolicyErrors)(int)0);
			}
			return false;
		}

		[Foreign(Language.Java)]
		void connect(string uri, Action<string> cont, Func<string, string, bool> serverCertificateValidationCallback)
		@{
			HttpTest client = new HttpTest();
			client.callback = new MyCallback() {
				public void onDone(String response) {
					cont.run(response);
				}
				public boolean onCheckServerTrusted(String subject, String thumbprint) {
					return serverCertificateValidationCallback.run(subject, thumbprint);
				}
			};
			client.createRequest(uri);
		@}

		void Continue(string response)
		{
			debug_log "IsCompleted " + response;
			if (response != null)
			{
				debug_log "got response";
				
				_promise.Resolve(new Response());
			}
			else
			{
				debug_log "err";
				_promise.Reject(new Exception("SendAsync failed"));
			}
		}
	}
}
