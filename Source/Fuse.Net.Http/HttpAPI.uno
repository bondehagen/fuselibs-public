using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Net.Http.Implementation;

namespace Fuse.Net.Http
{
    public class HttpAPI : IHttpRequest
    {
    	HttpClient _client;
    	Request _request;
    	Response _response;

        public HttpAPI(string method, string url)
        {
        	_client = new HttpClient();
        	_client.Proxy = new NetworkProxy(new Uno.Net.Http.Uri("http://192.168.1.233:8080"));
        	_client.AutoRedirect = true;
        	_request = new Request(method, url);
        }

        public void OnAborted()
        {
        	debug_log "OnAborted";
        }

        public void OnError(Exception exception)
        {
			debug_log "OnError " + exception.Message;
        }

        public void OnTimeout()
        {
        	debug_log "OnTimeout";
        }

        public void OnDone(Response response)
        {
            debug_log "OnDone";
            _response = response;
            debug_log GetResponseContentString();
        }

        public void OnHeadersReceived()
        {
            debug_log "OnHeadersReceived";
            //TODO debug_log GetResponseStatus();
        }

        public void OnProgress(int current, int total, bool hasTotal)
        {
            debug_log "OnProgress " + current + " " + total + " " + hasTotal;
        }

        public void EnableCache(bool enableCache)
        {
        	_request.EnableCache = true;
        }

        public void SetHeader(string name, string value)
        {
        	_request.SetHeader(name, value);
        }

        public void SetTimeout(int timeoutInMilliseconds)
        {
			_client.Timeout = timeoutInMilliseconds;
        }

        public void SendAsync(byte[] data)
        {
        	_request.SetBody(data);
        	_client.Send(_request).Then(OnDone, OnError);
        }

        public void SendAsync(string data)
        {
        	_request.SetBody(data);
        	_client.Send(_request).Then(OnDone, OnError);
        }

        public void SendAsync()
        {
        	_client.Send(_request).Then(OnDone, OnError);
        }

        public void Abort()
        {
			_client.AbortAllRequest();
        }

        public int GetResponseStatus()
        {
        	return _response.StatusCode;
        }

        public string GetResponseHeader(string name)
        {
        	return null;
        }

        public string GetResponseHeaders()
        {
        	return null;
        }

        public string GetResponseContentString()
        {
        	return _response.GetBodyAsString();
        }

        public byte[] GetResponseContentByteArray()
        {
            return _response.GetBodyAsByteArray();
        }

        public void Dispose()
        {
        	/*_request.Dispose();
        	_response.Dispose();
        	_httpClient.Dispose();*/
        }
    }
}
