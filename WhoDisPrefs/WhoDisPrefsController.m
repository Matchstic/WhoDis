//
//  WhoDisPrefsController.m
//  WhoDisPrefs
//
//  Created by Matt Clarke on 11/10/2016.
//  Copyright (c) 2016 __MyCompanyName__. All rights reserved.
//

#import "WhoDisPrefsController.h"
#import <Preferences/PSSpecifier.h>

@implementation WhoDisPrefsController

// Override this to load in settings specifiers from a given plist file.
-(id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [self loadSpecifiersFromPlistName:@"Root" target:self];
        
        _specifiers = testingSpecs;
        _specifiers = [self localizedSpecifiersForSpecifiers:_specifiers];
    }
    
    return _specifiers;
}

-(NSArray *)localizedSpecifiersForSpecifiers:(NSArray *)s {
    int i;
    for (i=0; i<[s count]; i++) {
        if ([[s objectAtIndex: i] name]) {
            [[s objectAtIndex: i] setName:[[self bundle] localizedStringForKey:[[s objectAtIndex: i] name] value:[[s objectAtIndex: i] name] table:nil]];
        }
        if ([[s objectAtIndex: i] titleDictionary]) {
            NSMutableDictionary *newTitles = [[NSMutableDictionary alloc] init];
            for(NSString *key in [[s objectAtIndex: i] titleDictionary]) {
                [newTitles setObject: [[self bundle] localizedStringForKey:[[[s objectAtIndex: i] titleDictionary] objectForKey:key] value:[[[s objectAtIndex: i] titleDictionary] objectForKey:key] table:nil] forKey: key];
            }
            [[s objectAtIndex: i] setTitleDictionary: newTitles];
        }
    }
    
    return s;
}

- (void)githubLaunch:(id)specifier {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/Matchstic/WhoDis"]];
}

@end