using Uno;
using Fuse.Net.Http;

namespace UnoHttp
{
    public class Main : Uno.Application
    {
        public Main() : base()
        {
            var h = new HttpAPI("POST", "http://192.168.1.187:300");
            h.SetTimeout(3000);
            h.EnableCache(true);
            h.SetHeader("x-test", "true");
            h.SendAsync("this is my data");
            //h.Abort();
        }
    }
}
