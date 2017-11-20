#import <Foundation/Foundation.h>

@interface HttpClientObjc: NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

- (void)addClientCertificate:(const uint8_t *) data length:(NSUInteger)length password:(NSString *)pass;
- (void)connect:(NSString *)url
		onCompleteHandler:(void (^)(NSHTTPURLResponse *, uint8_t *, NSUInteger))completeHandler
		onCheckServerCertificate:(BOOL (^)(uint8_t *, NSUInteger)) cert;

@end
