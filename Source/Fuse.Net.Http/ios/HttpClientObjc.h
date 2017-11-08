#import <Foundation/Foundation.h>

@interface HttpClientObjc: NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

- (void)connect:(NSString *)url
		onCompleteHandler:(void (^)(NSHTTPURLResponse *httpResponse))completeHandler
		onCheckServerCertificate:(BOOL (^)(uint8_t *, NSUInteger)) cert;

@end
