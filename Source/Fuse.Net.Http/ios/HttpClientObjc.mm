#import "ios/HttpClientObjc.h"

#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>
#import <Foundation/Foundation.h>

@interface HttpClientObjc ()

	@property (nonatomic, copy) BOOL (^onCheckServerCertificate)(uint8_t *, NSUInteger);

@end

@implementation HttpClientObjc

- (id)init {
	self = [super init];
	if (self) {

	}

	return self;
}

- (void)connect:(NSString *)url onCompleteHandler:(void (^)(NSHTTPURLResponse *))completeHandler onCheckServerCertificate:(BOOL (^)(uint8_t *, NSUInteger))checkServerCertificate {

	self.onCheckServerCertificate = checkServerCertificate;

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"GET"];
	//[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	//[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
	sessionConfiguration.timeoutIntervalForRequest = 5;
	NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:Nil];

	__block NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		NSLog(@"completeHandler block");
		if (error!=nil)
		{
			NSLog(@"error %@" , error);
			completeHandler(nil);
		}
		else
		{
			if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
				NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
				completeHandler(httpResponse);
				/*NSInteger statusCode = [httpResponse statusCode];
				NSDictionary *dictionary = [httpResponse allHeaderFields];
				NSString *requestReply = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];*/
			}
		}
		[task suspend];
		[session finishTasksAndInvalidate];
	}];
	[task resume];
}

- (void)dealloc {
	//[super dealloc];
	NSLog(@"dealloc");
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
	// https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/URLLoadingSystem/Articles/RequestChanges.html
	NSURLRequest *newRequest = request;
	/*if (redirectResponse) {
		newRequest = nil;
	}*/

	completionHandler(newRequest);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
	completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
	//https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/URLLoadingSystem/Articles/AuthenticationChallenges.html#//apple_ref/doc/uid/TP40009507-SW1
	NSLog(@"didReceiveChallenge");
	NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
	__block NSURLCredential *credential = nil;
	completionHandler(disposition, credential);
/*	
	SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
	
    NSString* summary = (NSString*)CFBridgingRelease(SecCertificateCopySubjectSummary(certificate));
    NSLog(@"Cert summary: %@", summary);
    
    CFDataRef dataref = SecCertificateCopyData(certificate);
    
    NSData* data = CFBridgingRelease(dataref);
	BOOL res = self.onCheckServerCertificate((uint8_t *)[data bytes], [data length]);

	completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);*/
}

/*
#pragma mark - NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p, session: %@, operationQueue: %@>", NSStringFromClass([self class]), self, self.session, self.operationQueue];
}

- (BOOL)respondsToSelector:(SEL)selector {
	if (selector == @selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:)) {
		return self.taskWillPerformHTTPRedirection != nil;
	} else if (selector == @selector(URLSession:dataTask:didReceiveResponse:completionHandler:)) {
		return self.dataTaskDidReceiveResponse != nil;
	} else if (selector == @selector(URLSession:dataTask:willCacheResponse:completionHandler:)) {
		return self.dataTaskWillCacheResponse != nil;
	} else if (selector == @selector(URLSessionDidFinishEventsForBackgroundURLSession:)) {
		return self.didFinishEventsForBackgroundURLSession != nil;
	}

	return [[self class] instancesRespondToSelector:selector];
}

#pragma mark - NSURLSessionDelegate
*/
- (void)URLSession:(NSURLSession *)session
didBecomeInvalidWithError:(NSError *)error
{
    NSLog(@"didBecomeInvalidWithError %@", error);
    [session finishTasksAndInvalidate];
}
/*
- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
	NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
	__block NSURLCredential *credential = nil;

	if (self.sessionDidReceiveAuthenticationChallenge) {
		disposition = self.sessionDidReceiveAuthenticationChallenge(session, challenge, &credential);
	} else {
		if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
			if ([self.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
				credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
				if (credential) {
					disposition = NSURLSessionAuthChallengeUseCredential;
				} else {
					disposition = NSURLSessionAuthChallengePerformDefaultHandling;
				}
			} else {
				disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
			}
		} else {
			disposition = NSURLSessionAuthChallengePerformDefaultHandling;
		}
	}

	if (completionHandler) {
		completionHandler(disposition, credential);
	}
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
			  task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
		newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler
{
	NSURLRequest *redirectRequest = request;

	if (self.taskWillPerformHTTPRedirection) {
		redirectRequest = self.taskWillPerformHTTPRedirection(session, task, response, request);
	}

	if (completionHandler) {
		completionHandler(redirectRequest);
	}
}

- (void)URLSession:(NSURLSession *)session
			  task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
	NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
	__block NSURLCredential *credential = nil;

	if (self.taskDidReceiveAuthenticationChallenge) {
		disposition = self.taskDidReceiveAuthenticationChallenge(session, task, challenge, &credential);
	} else {
		if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
			if ([self.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
				disposition = NSURLSessionAuthChallengeUseCredential;
				credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
			} else {
				disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
			}
		} else {
			disposition = NSURLSessionAuthChallengePerformDefaultHandling;
		}
	}

	if (completionHandler) {
		completionHandler(disposition, credential);
	}
}

- (void)URLSession:(NSURLSession *)session
			  task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler
{
	NSInputStream *inputStream = nil;
	
	if (self.taskNeedNewBodyStream) {
		inputStream = self.taskNeedNewBodyStream(session, task);
	} else if (task.originalRequest.HTTPBodyStream && [task.originalRequest.HTTPBodyStream conformsToProtocol:@protocol(NSCopying)]) {
		inputStream = [task.originalRequest.HTTPBodyStream copy];
	}

	if (completionHandler) {
		completionHandler(inputStream);
	}
}

- (void)URLSession:(NSURLSession *)session
			  task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
	totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
	
	int64_t totalUnitCount = totalBytesExpectedToSend;
	if(totalUnitCount == NSURLSessionTransferSizeUnknown) {
		NSString *contentLength = [task.originalRequest valueForHTTPHeaderField:@"Content-Length"];
		if(contentLength) {
			totalUnitCount = (int64_t) [contentLength longLongValue];
		}
	}
	
	AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:task];
	[delegate URLSession:session task:task didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalUnitCount];

	if (self.taskDidSendBodyData) {
		self.taskDidSendBodyData(session, task, bytesSent, totalBytesSent, totalUnitCount);
	}
}

- (void)URLSession:(NSURLSession *)session
			  task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
	AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:task];

	// delegate may be nil when completing a task in the background
	if (delegate) {
		[delegate URLSession:session task:task didCompleteWithError:error];

		[self removeDelegateForTask:task];
	}

	if (self.taskDidComplete) {
		self.taskDidComplete(session, task, error);
	}

}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
		  dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
	NSURLSessionResponseDisposition disposition = NSURLSessionResponseAllow;

	if (self.dataTaskDidReceiveResponse) {
		disposition = self.dataTaskDidReceiveResponse(session, dataTask, response);
	}

	if (completionHandler) {
		completionHandler(disposition);
	}
}

- (void)URLSession:(NSURLSession *)session
		  dataTask:(NSURLSessionDataTask *)dataTask
didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
	AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:dataTask];
	if (delegate) {
		[self removeDelegateForTask:dataTask];
		[self setDelegate:delegate forTask:downloadTask];
	}

	if (self.dataTaskDidBecomeDownloadTask) {
		self.dataTaskDidBecomeDownloadTask(session, dataTask, downloadTask);
	}
}

- (void)URLSession:(NSURLSession *)session
		  dataTask:(NSURLSessionDataTask *)dataTask
	didReceiveData:(NSData *)data
{
	AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:dataTask];
	[delegate URLSession:session dataTask:dataTask didReceiveData:data];

	if (self.dataTaskDidReceiveData) {
		self.dataTaskDidReceiveData(session, dataTask, data);
	}
}

- (void)URLSession:(NSURLSession *)session
		  dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler
{
	NSCachedURLResponse *cachedResponse = proposedResponse;

	if (self.dataTaskWillCacheResponse) {
		cachedResponse = self.dataTaskWillCacheResponse(session, dataTask, proposedResponse);
	}

	if (completionHandler) {
		completionHandler(cachedResponse);
	}
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
	if (self.didFinishEventsForBackgroundURLSession) {
		dispatch_async(dispatch_get_main_queue(), ^{
			self.didFinishEventsForBackgroundURLSession(session);
		});
	}
}
/*
#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
	  downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
	if (self.downloadTaskDidFinishDownloading) {
		NSURL *fileURL = self.downloadTaskDidFinishDownloading(session, downloadTask, location);
		if (fileURL) {
			NSError *error = nil;
			[[NSFileManager defaultManager] moveItemAtURL:location toURL:fileURL error:&error];
			if (error) {
				[[NSNotificationCenter defaultCenter] postNotificationName:AFURLSessionDownloadTaskDidFailToMoveFileNotification object:downloadTask userInfo:error.userInfo];
			}

			return;
		}
	}
	
	AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:downloadTask];
	if (delegate) {
		[delegate URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
	}
}

- (void)URLSession:(NSURLSession *)session
	  downloadTask:(NSURLSessionDownloadTask *)downloadTask
	  didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
	AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:downloadTask];
	[delegate URLSession:session downloadTask:downloadTask didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];

	if (self.downloadTaskDidWriteData) {
		self.downloadTaskDidWriteData(session, downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
	}
}

- (void)URLSession:(NSURLSession *)session
	  downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
	AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:downloadTask];
	[delegate URLSession:session downloadTask:downloadTask didResumeAtOffset:fileOffset expectedTotalBytes:expectedTotalBytes];

	if (self.downloadTaskDidResume) {
		self.downloadTaskDidResume(session, downloadTask, fileOffset, expectedTotalBytes);
	}
}*/

@end
