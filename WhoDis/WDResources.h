//
//  WDResources.h
//  
//
//  Created by Matt Clarke on 11/10/2016.
//
//

#import <Foundation/Foundation.h>

@interface WDResources : NSObject

+(BOOL)displayOnIncomingCalls;
+(BOOL)displayOnOutgoingCalls;
+(void)reloadSettings;

@end
