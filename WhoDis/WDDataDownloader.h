//
//  WDDataDownloader.h
//  
//
//  Created by Matt Clarke on 08/10/2016.
//
//

#import <Foundation/Foundation.h>

@interface WDDataDownloader : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate> {
    NSMutableData *_data;
}

@property (nonatomic, copy) void (^callback)(NSData *data);

-(void)downloadFromURL:(NSString*)urlPath withCallback:(void(^)(NSData* data))callback;

@end
