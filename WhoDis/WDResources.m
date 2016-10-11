//
//  WDResources.m
//  
//
//  Created by Matt Clarke on 11/10/2016.
//
//

#import "WDResources.h"

#define settingsKey "com.matchstic.whodis"

static NSDictionary *settings;

@implementation WDResources

+(BOOL)displayOnIncomingCalls {
    id value = settings[@"displayOnIncomingCalls"];
    return (value ? [value boolValue] : YES);
}

+(BOOL)displayOnOutgoingCalls {
    id value = settings[@"displayOnOutgoingCalls"];
    return (value ? [value boolValue] : YES);
}

+(void)reloadSettings {
    CFPreferencesAppSynchronize(CFSTR(settingsKey));
    settings = nil;
    
    settings = (__bridge NSDictionary *)CFPreferencesCopyMultiple(CFPreferencesCopyKeyList(CFSTR(settingsKey), kCFPreferencesCurrentUser, kCFPreferencesAnyHost), CFSTR(settingsKey), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}

@end
