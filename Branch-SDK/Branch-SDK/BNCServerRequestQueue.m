//
//  BNCServerRequestQueue.m
//  Branch-SDK
//
//  Created by Qinwei Gong on 9/6/14.
//
//

#import "BNCServerRequestQueue.h"
#import "BranchServerInterface.h"
#import "BNCConfig.h"

#define STORAGE_KEY     @"BNCServerRequestQueue"


@interface BNCServerRequestQueue()

@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic) dispatch_queue_t asyncQueue;

- (void)persist;
+ (NSMutableArray *)retrieve;

@end


@implementation BNCServerRequestQueue

- (id)init {
    if (self = [super init]) {
        self.queue = [NSMutableArray array];
        self.asyncQueue = dispatch_queue_create("brnch_persist_queue", NULL);
    }
    return self;
}

- (void)enqueue:(BNCServerRequest *)request {
    if (request) {
        @synchronized(self.queue) {
            [self.queue addObject:request];
            [self persist];
        }
    }
}

- (void)insert:(BNCServerRequest *)request at:(unsigned int)index {
    if (index > self.queue.count) {
        Debug(@"Invalid queue operation: index out of bound!");
        return;
    }
    
    if (request) {
        @synchronized(self.queue) {
            [self.queue insertObject:request atIndex:index];
            [self persist];
        }
    }
}

- (BNCServerRequest *)dequeue {
    BNCServerRequest *request = nil;
    
    if (self.queue.count > 0) {
        @synchronized(self.queue) {
            request = [self.queue objectAtIndex:0];
            [self.queue removeObjectAtIndex:0];
            [self persist];
        }
    }
    
    return request;
}

- (BNCServerRequest *)removeAt:(unsigned int)index {
    if (index >= self.queue.count) {
        Debug(@"Invalid queue operation: index out of bound!");
        return nil;
    }
    
    BNCServerRequest *request;
    @synchronized(self.queue) {
        request = [self.queue objectAtIndex:index];
        [self.queue removeObjectAtIndex:index];
        [self persist];
    }
    
    return request;
}


- (BNCServerRequest *)peek {
    return [self peekAt:0];
}

- (BNCServerRequest *)peekAt:(unsigned int)index {
    if (index >= self.queue.count) {
        Debug(@"Invalid queue operation: index out of bound!");
        return nil;
    }
    
    BNCServerRequest *request = nil;
    request = [self.queue objectAtIndex:index];
    
    return request;
}

- (unsigned int)size {
    return (unsigned int)self.queue.count;
}

- (NSString *)description {
    return [self.queue description];
}

- (BOOL)containsInstallOrOpen {
    for (int i = 0; i < self.queue.count; i++) {
        BNCServerRequest *req = [self.queue objectAtIndex:i];
        if ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL] || [req.tag isEqualToString:REQ_TAG_REGISTER_OPEN]) {
            return YES;
        }
    }
    return NO;
}

- (void)moveInstallOrOpen:(NSString *)tag ToFront:(NSInteger)networkCount {
    for (int i = 0; i < self.queue.count; i++) {
        BNCServerRequest *req = [self.queue objectAtIndex:i];
        if ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL] || [req.tag isEqualToString:REQ_TAG_REGISTER_OPEN]) {
            [self removeAt:i];
            break;
        }
    }
    
    BNCServerRequest *req = [[BNCServerRequest alloc] initWithTag:tag];
    if (networkCount == 0) {
        [self insert:req at:0];
    } else {
        [self insert:req at:1];
    }
}

- (BOOL)containsClose {
    for (int i = 0; i < self.queue.count; i++) {
        BNCServerRequest *req = [self.queue objectAtIndex:i];
        if ([req.tag isEqualToString:REQ_TAG_REGISTER_CLOSE]) {
            return YES;
        }
    }
    return NO;
}


#pragma mark - Private method

- (void)persist {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    dispatch_async(self.asyncQueue, ^{
        @synchronized(self.queue) {
            NSMutableArray *arr = [NSMutableArray array];
            
            for (BNCServerRequest *req in self.queue) {
                NSData *encodedReq = [NSKeyedArchiver archivedDataWithRootObject:req];
                [arr addObject:encodedReq];
            }
            
            [defaults setObject:arr forKey:STORAGE_KEY];
        }
        [defaults synchronize];
    });
}

+ (NSMutableArray *)retrieve {
    NSMutableArray *queue = [NSMutableArray array];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id data = [defaults objectForKey:STORAGE_KEY];
    if (!data) {
        return queue;
    }
    
    NSArray *arr = (NSArray *)data;
    for (NSData *encodedRequest in arr) {
        BNCServerRequest *request = [NSKeyedUnarchiver unarchiveObjectWithData:encodedRequest];
        [queue addObject:request];
    }
    
    return queue;
}

#pragma mark - Singleton method

+ (id)getInstance {
    static BNCServerRequestQueue *sharedQueue = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedQueue = [[BNCServerRequestQueue alloc] init];
        sharedQueue.queue = [BNCServerRequestQueue retrieve];
        Debug(@"Retrieved from Persist: %@", sharedQueue);
    });
    
    return sharedQueue;
}

@end
