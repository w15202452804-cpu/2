#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Forward declaration to avoid unknown type name error
@class XMLYVIPUnlocker;

static XMLYVIPUnlocker *g_unlocker = nil;

@interface XMLYVIPUnlocker : NSObject
- (id)processResponseJSON:(NSData *)jsonData forURL:(NSURL *)url;
- (BOOL)shouldInterceptURL:(NSURL *)url;
@end

@implementation XMLYVIPUnlocker

- (BOOL)shouldInterceptURL:(NSURL *)url {
    NSString *host = url.host.lowercaseString;
    return [host containsString:@"ximalaya"] || [host containsString:@"xmcdn"] || [host containsString:@"himalaya"];
}

- (id)processResponseJSON:(NSData *)jsonData forURL:(NSURL *)url {
    if (!jsonData || jsonData.length == 0) return nil;
    NSError *err = nil;
    id jsonObj = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&err];
    if (err || !jsonObj || ![jsonObj isKindOfClass:[NSDictionary class]]) return nil;
    NSMutableDictionary *dict = [(NSDictionary *)jsonObj mutableCopy];
    NSString *path = url.path;

    if ([path containsString:@"mobile-user/v2/homePage"] || [path containsString:@"mobile-user/v2"]) {
        NSMutableDictionary *d = dict[@"data"] ?: [@{} mutableCopy];
        d[@"isVip"] = @YES; d[@"vipLevel"] = @99; d[@"isMember"] = @YES;
        dict[@"data"] = d;
    }
    if ([path containsString:@"product/detail/v1"]) {
        NSMutableDictionary *d = dict[@"data"] ?: [@{} mutableCopy];
        d[@"isPaid"] = @NO; d[@"payType"] = @0; d[@"needPay"] = @NO;
        dict[@"data"] = d;
    }
    if ([path containsString:@"track/ts"] || [path containsString:@"baseInfo/ts"] || [path containsString:@"playpage/track"]) {
        NSMutableDictionary *d = dict[@"data"] ?: [@{} mutableCopy];
        d[@"canPlay"] = @YES; d[@"isFree"] = @YES; d[@"needPay"] = @NO;
        NSArray *list = d[@"list"];
        if ([list isKindOfClass:[NSArray class]]) {
            NSMutableArray *newList = [list mutableCopy];
            for (int i = 0; i < newList.count; i++) {
                NSMutableDictionary *item = newList[i];
                if ([item isKindOfClass:[NSMutableDictionary class]]) {
                    item[@"canPlay"] = @YES; item[@"isFree"] = @YES; item[@"needPay"] = @NO; item[@"needVip"] = @NO;
                }
            }
            d[@"list"] = newList;
        }
        dict[@"data"] = d;
    }
    if ([path containsString:@"qualityAndEffect"]) {
        NSMutableDictionary *d = dict[@"data"] ?: [@{} mutableCopy];
        NSArray *list = d[@"list"];
        if ([list isKindOfClass:[NSArray class]]) {
            NSMutableArray *newList = [list mutableCopy];
            for (int i = 0; i < newList.count; i++) {
                NSMutableDictionary *q = newList[i];
                if ([q isKindOfClass:[NSMutableDictionary class]]) {
                    q[@"canPlay"] = @YES; q[@"needVip"] = @NO; q[@"free"] = @YES;
                }
            }
            d[@"list"] = newList;
        }
        dict[@"data"] = d;
    }
    if ([path containsString:@"download/v2/track"] || [path containsString:@"mobile/download"]) {
        NSMutableDictionary *d = dict[@"data"] ?: [@{} mutableCopy];
        d[@"canDownload"] = @YES; d[@"downloadExpireTime"] = @0;
        NSArray *tl = d[@"trackList"];
        if ([tl isKindOfClass:[NSArray class]]) {
            NSMutableArray *newTl = [tl mutableCopy];
            for (int i = 0; i < newTl.count; i++) {
                NSMutableDictionary *t = newTl[i];
                if ([t isKindOfClass:[NSMutableDictionary class]]) {
                    t[@"canDownload"] = @YES; t[@"needVip"] = @NO;
                }
            }
            d[@"trackList"] = newTl;
        }
        dict[@"data"] = d;
    }
    if ([path containsString:@"decoratorV2"] || [path containsString:@"plant/grass"]) {
        NSMutableDictionary *d = dict[@"data"] ?: [@{} mutableCopy];
        d[@"isVip"] = @YES; d[@"unlockAll"] = @YES;
        dict[@"data"] = d;
    }
    if ([path containsString:@"album/price"] || [path containsString:@"promotion/v1"]) {
        NSMutableDictionary *d = dict[@"data"] ?: [@{} mutableCopy];
        d[@"price"] = @0; d[@"originalPrice"] = @0; d[@"needPay"] = @NO; d[@"isFree"] = @YES;
        dict[@"data"] = d;
    }
    if ([path containsString:@"playpage/tabs"]) {
        NSMutableDictionary *d = dict[@"data"] ?: [@{} mutableCopy];
        NSArray *tl = d[@"list"];
        if ([tl isKindOfClass:[NSArray class]]) {
            NSMutableArray *newList = [tl mutableCopy];
            for (int i = 0; i < newList.count; i++) {
                NSMutableDictionary *t = newList[i];
                if ([t isKindOfClass:[NSMutableDictionary class]]) {
                    t[@"isUnlocked"] = @YES; t[@"needVip"] = @NO;
                }
            }
            d[@"list"] = newList;
        }
        dict[@"data"] = d;
    }
    dict[@"code"] = @0;
    dict[@"status"] = @200;
    return dict;
}

@end

%hook AFJSONResponseSerializer
- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError * __autoreleasing *)error {
    if (!data || data.length == 0) return %orig;
    NSString *host = response.URL.host.lowercaseString;
    if (![host containsString:@"ximalaya"] && ![host containsString:@"xmcdn"] && ![host containsString:@"himalaya"]) { return %orig; }
    id result = %orig;
    if ([result isKindOfClass:[NSDictionary class]] && g_unlocker) {
        NSURL *url = response.URL;
        id modified = [g_unlocker processResponseJSON:data forURL:url];
        if (modified) return modified;
    }
    return result;
}
%end

%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLResponse *, NSData *, NSError *))completionHandler {
    NSString *host = request.URL.host.lowercaseString;
    if (![host containsString:@"ximalaya"] && ![host containsString:@"xmcdn"] && ![host containsString:@"himalaya"]) { return %orig; }
    NSURLSessionDataTask *task = %orig;
    __block void (^wrappedHandler)(NSURLResponse *, NSData *, NSError *) = ^(NSURLResponse *resp, NSData *body, NSError *err) {
        if (!g_unlocker) g_unlocker = [XMLYVIPUnlocker new];
        NSData *processed = nil;
        if (body && [g_unlocker shouldInterceptURL:request.URL]) {
            id modified = [g_unlocker processResponseJSON:body forURL:request.URL];
            if (modified && [modified isKindOfClass:[NSData class]]) processed = modified;
        }
        completionHandler(resp, processed ?: body, err);
    };
    Ivar ivar = class_getInstanceVariable(object_getClass(task), "_completionHandler");
    if (ivar) { void *slot = (void *)((char *)task + ivar.offset); *(void **)slot = ^id(id, id, id) { return wrappedHandler; }; }
    return task;
}
%end

%hook UIApplication
- (BOOL)openURL:(NSURL *)url {
    NSString *scheme = url.scheme.lowercaseString;
    if ([scheme hasPrefix:@"ximalaya"] || [scheme hasPrefix:@"xmcdn"]) { NSLog(@"[XMLY] Blocked: %@", url); return YES; }
    return %orig;
}
%end

%ctor {
    g_unlocker = [XMLYVIPUnlocker new];
    NSLog(@"[XMLY] Tweak loaded.");
}
