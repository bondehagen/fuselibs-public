# Mutual authentication with HTTPS between mobile client to a server
In this example we show how you can use custom validation and authentication against a HTTPS server. We show you how to load a password protected pkcs12 certificate from a bundle and using it for client authentication. We also show an example of custom validating the self-signed certificate from the server.

## About the files in this solution
We have two projects in this solution. `Fuse.Net.Http` is the implementation that eventually will become part of the default public Fuse library when it's feature complete. This package also includes the namespace `Fuse.Security`.
The other package is the example were we demonstrate usage of this API and is name `TlsExample`. When you select `TlsExample.unproj` in the Fuse tooling, it will include `Fuse.Net.Http` as a dependency as long as the two project folders exists next to each other.
In `TlsExample` we have included a set of self-signed certificates that can be used for testing out the project on your own server infrastructure. A log of how the certificates was created using openssl is also included in the certs folder.

# Walkthrough
In this guide we will go through how the previous example is put together.

## Create a Uno module that we can talk to from JavaScript
We first create a native module that we use to talk to Uno code from a Javascript context. More documentation about native modules can be found here https://www.fusetools.com/docs/native-interop/native-js-modules.
```
using Uno;
using Uno.UX;
using Uno.Threading;
using Fuse.Scripting;

[UXGlobalModule]
public class SecureHttp : NativeModule
{
	static readonly SecureHttp _instance;

	public SecureHttp()
	{
		if(_instance != null) return;
		Resource.SetGlobalKey(_instance = this, "SecureHttp");

		AddMember(new NativePromise<string, Fuse.Scripting.Object>("sendRequest", SendRequest, null));
	}

	Future<string> SendRequest(object[] args)
	{
		return new Promise<string>("hello");
	}
}
```
This can now be called from javascript like this.
```
<JavaScript>
	var client = require("SecureHttp");
	client.sendRequest().then(function(payload) {});
</JavaScript>
```

## Add a HttpClient and log result
To be able to do a http request you need to first create a `HttpClient` then create a `Request` and eventually call `Send`. This will then return a promise that we need to handle in two other method.
```
var client = new HttpClient();
client.Send(new Request("GET", "https://<yourhost>")).Then(HandleResponse, HandleError);
```
If the connection could be established, we will get a `Response` object back that we can use to inspect the message.
```
void HandleResponse(Response response) {}
void HandleError(Exception response) {}
```
In the file `SecureHttp.uno` we show how you combine this with the NativeModule we created earlier.

## Load client certificate
If you have a server that requires that the client authenticates it self using a certificate you can set this using the `SetClientCertificate` method. You need to get the certificate using the `Uno.IO.File` API or bundling it with your app as a bundle like we do in this example. To add something as a bundle spesify that in the `.unoproj` file. Here is how that is done in this project:
```
{
  "Packages": [
  	"Fuse",
    "FuseJS"
  ],
  "Projects": [
    "../Fuse.Net.Http.unoproj"
  ],
  "Includes": [
    "*",
    "certs/client/sender.pfx:Bundle",
    "certs/server/receiver.crt:Bundle",
  ]
}

```
The following show how you load the certificate and add it to the httpclient.
```
var client = new HttpClient();
var bundleFile = Bundle.Get().GetFile("certs/client/sender.pfx");
var password = "1234";
client.SetClientCertificate(new X509Certificate(bundleFile.ReadAllBytes(), password));
```

## SSL pinning
If you are using a self-signed certificate or for some other reason need to override how the server certificate is validated, you can set a method to the `ServerCertificateValidationCallback`. In our example we compare the server certificate to a local version to check if they are equal. The parameter `sslPolicyErrors` can be used to check if the default validation accepted the certificate. You need to set this callback before you call `Send` on your http client object.
```
client.ServerCertificateValidationCallback = ValidateServerCertificate;
```
Here is a implementation of the callback that skip validation.
```
bool ValidateServerCertificate(X509Certificate serverCert, SslPolicyErrors sslPolicyErrors)
{
	return true;
}
```

# API
The public API used in this example is listed below.

## HttpClient
The http client has support for sending a client certificate for authenticating against servers. It is also possible to do custom server validation (for example self-signed certicates).

 * SetClientCertificate(X509Certificate certificate)
 * Func<X509Certificate, SslPolicyErrors, bool> ServerCertificateValidationCallback
 * Promise<Response> Send(Request request)

## Request
The request take http method and a URI string for the resource as an argument. Currently only GET http method is supported.

 * constructor(string method, string uri)

## Response
 * int StatusCode
 * string ReasonPhrase 
 * IEnumerable<string> GetHeader(string key)
 * IDictionary<string, IEnumerable<string>> GetHeaders()
 * byte[] GetBodyAsByteArray()
 * string GetBodyAsString()

## X509Certificate
The certificates can load data from the following formats der/crt/pem/pfx.

 * constructor(string certData)
 * constructor(byte[] certData, string password)
 * byte[] DerEncodedData
 * CertificateToBeSigned Certificate
 * string Algorithm
 * byte[] Signature
 * IList<X509v3Extension> Extensions
 * string ToString()

## X509v3Extension
 * Oid Id
 * bool IsCritical
 * string Value

## CertificateToBeSigned
 * int Version
 * string SerialNumber
 * Oid SignatureAlgorithm
 * RelativeDistinguishedName Issuer
 * Validity Validity
 * RelativeDistinguishedName Subject
 * SubjectPublicKeyInfo SubjectPublicKeyInfo

## RelativeDistinguishedName
 * string Name
 * Oid Oid
 * byte[] RawData

## SubjectPublicKeyInfo
 * AlgorithmIdentifier Algorithm
 * byte[] SubjectPublicKey
 * ulong Exponent

## AlgorithmIdentifier
 * Oid Algorithm
 * Object parameters

## Validity
 * Uno.Time.ZonedDateTime NotBefore
 * Uno.Time.ZonedDateTime NotAfter

## Oid
 * string FriendlyName
 * string Value
