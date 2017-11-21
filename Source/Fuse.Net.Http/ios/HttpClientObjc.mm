#import "ios/HttpClientObjc.h"

#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>
#import <Foundation/Foundation.h>

@interface HttpClientObjc ()

	@property (nonatomic, copy) BOOL (^onCheckServerCertificate)(uint8_t *, NSUInteger);
	@property SecIdentityRef identity;

@end

@implementation HttpClientObjc

- (id)init {
	self = [super init];
	if (self) {

	}

	return self;
}

- (void)addClientCertificate:(const uint8_t *)data length:(NSUInteger)length password:(NSString *)pass {
	NSData * p12Data = [NSData dataWithBytes: data length: sizeof(unsigned char) * length];
	OSStatus securityError = errSecSuccess;
	
	CFStringRef password = (__bridge CFStringRef)pass;
	const void *keys[] = { kSecImportExportPassphrase };
	const void *values[] = { password };
	
	CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
	
	CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
	securityError = SecPKCS12Import((__bridge CFDataRef)p12Data, options, &items);
	
	if (securityError == errSecSuccess) {
		CFDictionaryRef myIdentityAndTrust = (CFDictionaryRef)CFArrayGetValueAtIndex(items, 0);
		self.identity = (SecIdentityRef)CFDictionaryGetValue(myIdentityAndTrust, kSecImportItemIdentity);

		
		CFIndex count = CFArrayGetCount(items);
		NSLog(@"Certificates found: %ld",count);
	}
	
	if (options) {
		CFRelease(options);
	}
}

- (void)connect:(NSString *)url onCompleteHandler:(void (^)(NSHTTPURLResponse *, uint8_t *, NSUInteger))completeHandler onCheckServerCertificate:(BOOL (^)(uint8_t *, NSUInteger))checkServerCertificate {

	self.onCheckServerCertificate = checkServerCertificate;

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"GET"];

	NSString* proxyHost = @"localhost";
	NSNumber* proxyPort = [NSNumber numberWithInt: 8080];

	NSDictionary *proxyDict = @{
		@"HTTPEnable"  : [NSNumber numberWithInt:1],
		(NSString *)kCFStreamPropertyHTTPProxyHost  : proxyHost,
		(NSString *)kCFStreamPropertyHTTPProxyPort  : proxyPort,

		@"HTTPSEnable" : [NSNumber numberWithInt:1],
		(NSString *)kCFStreamPropertyHTTPSProxyHost : proxyHost,
		(NSString *)kCFStreamPropertyHTTPSProxyPort : proxyPort,
	};

	NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
	//sessionConfiguration.connectionProxyDictionary = proxyDict;
	sessionConfiguration.timeoutIntervalForRequest = 5;
	NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:Nil];

	__block NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		NSLog(@"completeHandler block");
		if (error!=nil)
		{
			NSLog(@"error %@" , error);
		}
		else
		{
			if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
				NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
				completeHandler(httpResponse, (uint8_t *)[data bytes], [data length]);
			}
		}
		[task suspend];
		[session finishTasksAndInvalidate];
	}];
	[task resume];
}

- (void)dealloc {
}

- (void)URLSession:(NSURLSession *)session
			  task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
	NSLog(@"Error %@", error);
	[session finishTasksAndInvalidate];
}

- (void)URLSession:(NSURLSession *)session
		task:(NSURLSessionTask *)task
		willPerformHTTPRedirection:(NSHTTPURLResponse *)redirectResponse
		newRequest:(NSURLRequest *)request
		completionHandler:(void (^)(NSURLRequest *))completionHandler {
	NSLog(@"redirect?");
	NSURLRequest *newRequest = request;
	completionHandler(newRequest);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
	completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
	NSURLProtectionSpace *protectionSpace = [challenge protectionSpace];
	NSString *authenticationMethod = [protectionSpace authenticationMethod];
	
	NSLog(@"auth %@", authenticationMethod);
	if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate])
	{
		SecCertificateRef certificateRef = NULL;
		SecIdentityCopyCertificate(self.identity, &certificateRef);

		NSArray *certificateArray = [[NSArray alloc] initWithObjects:(__bridge_transfer id)(certificateRef), nil];
		NSURLCredentialPersistence persistence = NSURLCredentialPersistenceForSession;

		NSURLCredential *credential = [[NSURLCredential alloc] initWithIdentity:self.identity
																   certificates:certificateArray
																	persistence:persistence];

		if ( credential == nil )
		{
			[[challenge sender] cancelAuthenticationChallenge:challenge];
		}
		else
		{
			completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
		}
	}
	else if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
	{

		SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
		SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, 0);

		NSString* summary = (NSString*)CFBridgingRelease(SecCertificateCopySubjectSummary(certificate));
		NSLog(@"Cert summary: %@", summary);

		CFDataRef dataref = SecCertificateCopyData(certificate);

		NSData* data = CFBridgingRelease(dataref);
		BOOL res = self.onCheckServerCertificate((uint8_t *)[data bytes], [data length]);
		if (res)
		{
			completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
			return;
		}
	}
	NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
	__block NSURLCredential *credential = nil;
	completionHandler(disposition, credential);
}

- (void)URLSession:(NSURLSession *)session
didBecomeInvalidWithError:(NSError *)error
{
	NSLog(@"didBecomeInvalidWithError %@", error);
	[session finishTasksAndInvalidate];
}

@end
