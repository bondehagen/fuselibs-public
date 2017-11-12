#import <Foundation/Foundation.h>

@interface HttpClientObjc: NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

- (void)connect:(NSString *)url
		onCompleteHandler:(void (^)(NSHTTPURLResponse *, NSString *, uint8_t *, NSUInteger))completeHandler
		onCheckServerCertificate:(BOOL (^)(uint8_t *, NSUInteger)) cert;

@end
