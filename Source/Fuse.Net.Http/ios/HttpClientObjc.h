#import <Foundation/Foundation.h>

@interface HttpClientObjc: NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

- (void)connect:(NSString *)url
		onCompleteHandler:(void (^)(NSString *))completeHandler
		onCheckServerCertificate:(void (^)(uint8_t *, NSUInteger)) cert;

@end
