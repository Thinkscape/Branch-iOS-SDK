//
//  BNCServerRequestQueue.h
//  Branch-SDK
//
//  Created by Qinwei Gong on 9/6/14.
//
//

#import "BNCServerRequest.h"

@interface BNCServerRequestQueue : NSObject

@property (nonatomic, readonly) unsigned int size;

- (void)enqueue:(BNCServerRequest *)request;
- (BNCServerRequest *)dequeue;
- (BNCServerRequest *)peek;
- (BNCServerRequest *)peekAt:(unsigned int)index;
- (void)insert:(BNCServerRequest *)request at:(unsigned int)index;
- (BNCServerRequest *)removeAt:(unsigned int)index;
- (void)persist;

- (BOOL)containsInstallOrOpen;
- (BOOL)containsClose;
- (void)moveInstallOrOpen:(NSString *)tag ToFront:(NSInteger)networkCount;

+ (id)getInstance;

@end
