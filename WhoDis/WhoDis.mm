#line 1 "/Users/Matt/iOS/Projects/WhoDis/WhoDis/WhoDis.xm"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "WDCallerIDViewController.h"
#import "WDDataDownloader.h"
#import "WDResources.h"




@interface CTCarrier : NSObject
@property (nonatomic, retain) NSString *isoCountryCode;
@end

@interface CTTelephonyNetworkInfo : NSObject
@property (retain) CTCarrier *subscriberCellularProvider;
@end

@interface LSApplicationProxy : NSObject
+ (instancetype)applicationProxyForIdentifier:(NSString*)arg1;
- (NSUUID*)deviceIdentifierForVendor;
@property (nonatomic, readonly) NSURL *dataContainerURL;
@end

@interface PHSingleCallParticipantLabelView : UIView
@property(retain) UILabel *statusLabel;
@end

@interface PHCallParticipantsView : UIView
@property(retain) UILabel *singleDurationTimerLabel;
@property(retain) UILabel *nameOverrideLabel;
@property(retain) PHSingleCallParticipantLabelView *singleCallLabelView;
@end

@interface PHCallParticipantsViewController : UIViewController
@property(retain) PHCallParticipantsView *participantsView;
- (id)callForParticipantAtIndex:(unsigned long long)arg1 inParticipantsView:(id)arg2;
- (id)nameForParticipantAtIndex:(unsigned long long)arg1 inParticipantsView:(id)arg2;
- (id)contactForParticipantAtIndex:(unsigned long long)arg1 inParticipantsView:(id)arg2;
@end

@interface PHAudioCallViewController : UIViewController
@property(retain) PHCallParticipantsViewController *callParticipantsViewController;
@end

@interface TUProxyCall : NSObject
- (id)contactIdentifier;
@end

@interface TUCallGroup : NSObject
@property (retain) NSArray *calls;
@end

@interface CPDistributedMessagingCenter : NSObject
+(CPDistributedMessagingCenter*)centerNamed:(NSString*)serverName;
-(BOOL)sendMessageName:(NSString*)name userInfo:(NSDictionary*)info;
-(NSDictionary*)sendMessageAndReceiveReplyName:(NSString*)name userInfo:(NSDictionary*)info;
-(void)runServerOnCurrentThread;
-(void)stopServer;
-(void)registerForMessageName:(NSString*)messageName target:(id)target selector:(SEL)selector;
-(void)sendMessageAndReceiveReplyName:(NSString*)name userInfo:(NSDictionary*)info toTarget:(id)target selector:(SEL)selector context:(void*)context;
@end

@interface SBUserAgent : NSObject
+ (id)sharedUserAgent;
- (_Bool)applicationInstalledForDisplayID:(id)arg1;
@end




extern "C" {
    void rocketbootstrap_distributedmessagingcenter_apply(CPDistributedMessagingCenter *messaging_center);
}

NSDictionary *constructParametersForNumber(NSString *number);
NSString *formatDictionaryIntoURLString(NSDictionary *dict);
void getTruecallerInformatonForNumber(NSString *number);
void analyseResultingData(NSData *data);




static CPDistributedMessagingCenter *sbCenter;
static CPDistributedMessagingCenter *inCallCenter;
static WDCallerIDViewController *callerIDController;
static WDDataDownloader *dataDownloader;
static NSString *inCallCurrentDownloadNumber;




#include <logos/logos.h>
#include <substrate.h>
@class SpringBoard; @class InCallServiceApplication; @class PHAudioCallViewController; 


#line 92 "/Users/Matt/iOS/Projects/WhoDis/WhoDis/WhoDis.xm"
static void (*_logos_orig$InCallService$PHAudioCallViewController$setCurrentState$animated$)(PHAudioCallViewController*, SEL, unsigned short, _Bool); static void _logos_method$InCallService$PHAudioCallViewController$setCurrentState$animated$(PHAudioCallViewController*, SEL, unsigned short, _Bool); static void (*_logos_orig$InCallService$PHAudioCallViewController$viewDidLayoutSubviews)(PHAudioCallViewController*, SEL); static void _logos_method$InCallService$PHAudioCallViewController$viewDidLayoutSubviews(PHAudioCallViewController*, SEL); static id (*_logos_orig$InCallService$InCallServiceApplication$init)(InCallServiceApplication*, SEL); static id _logos_method$InCallService$InCallServiceApplication$init(InCallServiceApplication*, SEL); static NSDictionary * _logos_method$InCallService$InCallServiceApplication$_whodis_handleMessageNamed$withUserInfo$(InCallServiceApplication*, SEL, NSString *, NSDictionary *); 


NSDictionary *constructParametersForNumber(NSString *number) {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    
    number = [number stringByReplacingOccurrencesOfString:@"-" withString:@""];
    number = [number stringByReplacingOccurrencesOfString:@" " withString:@""];
    number = [number stringByReplacingOccurrencesOfString:@"(" withString:@""];
    number = [number stringByReplacingOccurrencesOfString:@")" withString:@""];
    number = [number stringByReplacingOccurrencesOfString:@"+" withString:@"00"];
    
    
    NSDictionary *reply = [inCallCenter sendMessageAndReceiveReplyName:@"getThing" userInfo:nil];
    NSString *myNumber = [reply objectForKey:@"myNumber"];
    if (!myNumber)
        myNumber = @"";
    
    
    LSApplicationProxy *proxy = [LSApplicationProxy applicationProxyForIdentifier:@"com.truesoftware.TrueCallerOther"];
    NSString *defaultsPath = [[proxy.dataContainerURL absoluteString] stringByAppendingString:@"/Library/Preferences/com.truesoftware.TrueCallerOther.plist"];
    defaultsPath = [defaultsPath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
    
    NSString *requestId = [defaults objectForKey:@"id"];
    if (!requestId)
        requestId = @"";
    
    
    CTTelephonyNetworkInfo *network_Info = [CTTelephonyNetworkInfo new];
    CTCarrier *carrier = network_Info.subscriberCellularProvider;
    NSString *countryCode = [carrier.isoCountryCode lowercaseString];
    
    NSString *locAddr = @"";
    NSString *pageId = @"";
    NSString *type = @"4";
    
    [dict setObject:countryCode forKey:@"countryCode"];
    [dict setObject:locAddr forKey:@"locAddr"];
    [dict setObject:myNumber forKey:@"myNumber"];
    [dict setObject:pageId forKey:@"pageId"];
    [dict setObject:number forKey:@"q"];
    [dict setObject:requestId forKey:@"registerId"];
    [dict setObject:type forKey:@"type"];
    
    return dict;
}


NSString *formatDictionaryIntoURLString(NSDictionary *dict) {
    NSMutableString *string = [@"https://search5.truecaller.com/v2/search?client_id=1&clientId=1" mutableCopy];
    
    for (NSString *key in [dict allKeys]) {
        [string appendFormat:@"&%@=%@", key, [dict objectForKey:key]];
    }
    
    return string;
}


void getTruecallerInformatonForNumber(NSString *number) {
    
    
    if (![inCallCurrentDownloadNumber isEqualToString:number]) {
        NSDictionary *params = constructParametersForNumber(number);
        NSString *jsonURL = formatDictionaryIntoURLString(params);
    
        
        
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        [info setObject:jsonURL forKey:@"url"];
        [inCallCenter sendMessageName:@"downloadFromURL" userInfo:info];
        
        inCallCurrentDownloadNumber = number;
    }
}


void analyseResultingData(NSData *dataIn) {
    inCallCurrentDownloadNumber = @"";
    
    if (!dataIn || dataIn.length == 0) {
        
        NSMutableDictionary *finalData = [NSMutableDictionary dictionary];
        [finalData setObject:@"No connection" forKey:@"name"];
        [finalData setObject:@"NONE" forKey:@"spamType"];
        [finalData setObject:[NSNumber numberWithInt:0] forKey:@"spamScore"];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [callerIDController updateUIWithData:finalData];
        });
        
        return;
    }
    
    NSError *error;
    NSDictionary *jsonDict;
    if (dataIn) {
        jsonDict = [NSJSONSerialization JSONObjectWithData:dataIn options:kNilOptions error:&error];
    }
    
    if (error || !dataIn) {
        
        NSMutableDictionary *finalData = [NSMutableDictionary dictionary];
        [finalData setObject:@"Download error" forKey:@"name"];
        [finalData setObject:@"NONE" forKey:@"spamType"];
        [finalData setObject:[NSNumber numberWithInt:0] forKey:@"spamScore"];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [callerIDController updateUIWithData:finalData];
        });
        
        return;
    }
    
    NSArray *data = [jsonDict objectForKey:@"data"];
    
    if (!data) {
        
        
        NSMutableDictionary *finalData = [NSMutableDictionary dictionary];
        [finalData setObject:@"Unauthorised connection" forKey:@"name"];
        [finalData setObject:@"NONE" forKey:@"spamType"];
        [finalData setObject:[NSNumber numberWithInt:0] forKey:@"spamScore"];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [callerIDController updateUIWithData:finalData];
        });
        
        return;
    }
    
    if ([data count] == 0) {
        
        NSMutableDictionary *finalData = [NSMutableDictionary dictionary];
        [finalData setObject:@"No data available" forKey:@"name"];
        [finalData setObject:@"NONE" forKey:@"spamType"];
        [finalData setObject:[NSNumber numberWithInt:0] forKey:@"spamScore"];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [callerIDController updateUIWithData:finalData];
        });
        return;
    }
    
    
    
    NSString *identifier = [[data firstObject] objectForKey:@"id"];
    
    NSArray *phones = [[data firstObject] objectForKey:@"phones"];
    NSDictionary *phone = [NSDictionary dictionary];
    
    for (NSDictionary *dict in phones) {
        NSString *identifier2 = [dict objectForKey:@"id"];
        
        if ([identifier isEqualToString:identifier2]) {
            phone = dict;
            break;
        }
    }
    
    







    
    



    
    
    
    
    
    NSNumber *spamScore = [phone objectForKey:@"spamScore"];
    if (!spamScore)
        spamScore = [NSNumber numberWithInt:0];
    NSString *spamType = [phone objectForKey:@"spamType"];
    if (!spamType)
        spamType = @"NONE"; 
    NSString *name = [[data firstObject] objectForKey:@"name"];
    if (!name)
        name = @"No caller name available";
    
    
    
    NSMutableDictionary *finalData = [NSMutableDictionary dictionary];
    [finalData setObject:name forKey:@"name"];
    [finalData setObject:spamType forKey:@"spamType"];
    [finalData setObject:spamScore forKey:@"spamScore"];
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [callerIDController updateUIWithData:finalData];
    });
}















static void _logos_method$InCallService$PHAudioCallViewController$setCurrentState$animated$(PHAudioCallViewController* self, SEL _cmd, unsigned short arg1, _Bool arg2) {
    if (arg1 != 0 && arg1 != 1) {
        
        
        if (callerIDController.view.alpha != 0.0) {
            callerIDController.view.alpha = 0.0;
            
            
            [inCallCenter sendMessageName:@"cancelDownload" userInfo:nil];
        }
    } else if (arg1 == 0 || arg1 == 1) {
        
        [WDResources reloadSettings];
        BOOL shouldShow = (arg1 == 0 ? [WDResources displayOnIncomingCalls] : [WDResources displayOnOutgoingCalls]);
        
        
        
        @try {
            
            
            NSString *numberOrName = [self.callParticipantsViewController nameForParticipantAtIndex:0 inParticipantsView:self.callParticipantsViewController.participantsView];
            
            
            
            
            
        
            NSError *error = NULL;
            NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypePhoneNumber error:&error];
        
            NSRange inputRange = NSMakeRange(0, [numberOrName length]);
            NSArray *matches = [detector matchesInString:numberOrName options:0 range:inputRange];
        
            BOOL isPhoneNumber = NO;
        
            if ([matches count] > 0) {
                isPhoneNumber = YES;
            }
        
            if (isPhoneNumber && shouldShow) {
                getTruecallerInformatonForNumber(numberOrName);
            
                
                if (!callerIDController) {
                    callerIDController = [[WDCallerIDViewController alloc] init];
                }
            
                [self.view addSubview:callerIDController.view];
            
                [callerIDController didBeginRequestingData];
            
                if (callerIDController.view.alpha != 1.0) {
                    callerIDController.view.alpha = 1.0;
                }
            }
        } @catch (NSException *e) {
            NSLog(@"[WhoDis] :: Something has gone very wrong...!\n%@", e);
        }
    }
    
    _logos_orig$InCallService$PHAudioCallViewController$setCurrentState$animated$(self, _cmd, arg1, arg2);
}

static void _logos_method$InCallService$PHAudioCallViewController$viewDidLayoutSubviews(PHAudioCallViewController* self, SEL _cmd) {
    _logos_orig$InCallService$PHAudioCallViewController$viewDidLayoutSubviews(self, _cmd);
    
    
    
    
    PHCallParticipantsView *participants = self.callParticipantsViewController.participantsView;
    UILabel *statusLabel = participants.singleCallLabelView.statusLabel;
    
    CGFloat yOrigin = ([statusLabel.text isEqualToString:@""] ? statusLabel.frame.origin.y : participants.frame.size.height + participants.frame.origin.y) + 10;
    
    CGRect frame = CGRectMake(0, yOrigin, participants.frame.size.width, 50);
    callerIDController.view.frame = frame;
}





static id _logos_method$InCallService$InCallServiceApplication$init(InCallServiceApplication* self, SEL _cmd) {
    id orig = _logos_orig$InCallService$InCallServiceApplication$init(self, _cmd);
    
    
    
    sbCenter = [CPDistributedMessagingCenter centerNamed:@"com.matchstic.whodis.incall"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/librocketbootstrap.dylib"])
        rocketbootstrap_distributedmessagingcenter_apply(sbCenter);
        
    [sbCenter runServerOnCurrentThread];
    [sbCenter registerForMessageName:@"finishedDownload" target:orig selector:@selector(_whodis_handleMessageNamed:withUserInfo:)];
    
    return orig;
}


static NSDictionary * _logos_method$InCallService$InCallServiceApplication$_whodis_handleMessageNamed$withUserInfo$(InCallServiceApplication* self, SEL _cmd, NSString * name, NSDictionary * userinfo) {
    if ([name isEqualToString:@"finishedDownload"]) {
        NSData *data = [userinfo objectForKey:@"data"];
        analyseResultingData(data);
    }
    
    return nil;
}





static void (*_logos_orig$SpringBoard$SpringBoard$applicationDidFinishLaunching$)(SpringBoard*, SEL, id); static void _logos_method$SpringBoard$SpringBoard$applicationDidFinishLaunching$(SpringBoard*, SEL, id); static NSDictionary * _logos_method$SpringBoard$SpringBoard$_whodis_handleMessageNamed$withUserInfo$(SpringBoard*, SEL, NSString *, NSDictionary *); 



static void _logos_method$SpringBoard$SpringBoard$applicationDidFinishLaunching$(SpringBoard* self, SEL _cmd, id application) {
    _logos_orig$SpringBoard$SpringBoard$applicationDidFinishLaunching$(self, _cmd, application);
    
    sbCenter = [CPDistributedMessagingCenter centerNamed:@"com.matchstic.whodis"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/librocketbootstrap.dylib"])
        rocketbootstrap_distributedmessagingcenter_apply(sbCenter);
        
    [sbCenter runServerOnCurrentThread];
    [sbCenter registerForMessageName:@"getThing" target:self selector:@selector(_whodis_handleMessageNamed:withUserInfo:)];
    [sbCenter registerForMessageName:@"downloadFromURL" target:self selector:@selector(_whodis_handleMessageNamed:withUserInfo:)];
    [sbCenter registerForMessageName:@"cancelDownload" target:self selector:@selector(_whodis_handleMessageNamed:withUserInfo:)];
    
    
    BOOL installed = [[objc_getClass("SBUserAgent") sharedUserAgent] applicationInstalledForDisplayID:@"com.truesoftware.TrueCallerOther"];
    if (!installed) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Who Dis?" message:@"Install and setup the Truecaller app from the App Store to use this tweak." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [av show];
    }
}


static NSDictionary * _logos_method$SpringBoard$SpringBoard$_whodis_handleMessageNamed$withUserInfo$(SpringBoard* self, SEL _cmd, NSString * name, NSDictionary * userinfo) {
    if ([name isEqualToString:@"getThing"]) {
        
        
        LSApplicationProxy *proxy = [LSApplicationProxy applicationProxyForIdentifier:@"com.truesoftware.TrueCallerOther"];
        NSUUID *uuid = [proxy deviceIdentifierForVendor];
        NSString *myNumber = [uuid UUIDString];
        myNumber = [myNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
        myNumber = [myNumber lowercaseString];
    
        if (!myNumber)
            myNumber = @"";
        
        NSMutableDictionary *output = [NSMutableDictionary dictionary];
        [output setObject:myNumber forKey:@"myNumber"];
    
        return output;
    } else if ([name isEqualToString:@"downloadFromURL"]) {
        NSString *url = [userinfo objectForKey:@"url"];
        
        if (!dataDownloader) {
            dataDownloader = [[WDDataDownloader alloc] init];
        } else {
            [dataDownloader cancelDownloadIfNecessary];
        }
        
        [dataDownloader downloadFromURL:url withCallback:^(NSData *data) {
            
            if (!data) {
                data = [NSData new];
            }
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setObject:data forKey:@"data"];
            
            [inCallCenter sendMessageName:@"finishedDownload" userInfo:dict];
        }];
        
        return nil;
    } else if ([name isEqualToString:@"cancelDownload"]) {
        [dataDownloader cancelDownloadIfNecessary];
        return nil;
    } else {
        return nil;
    }
}





static void WhoDisSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [WDResources reloadSettings];
}

static __attribute__((constructor)) void _logosLocalCtor_b145a852() {
    {}
    
    
    
    BOOL sb = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"];
    [WDResources reloadSettings];
    
    CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(r, NULL, WhoDisSettingsChanged, CFSTR("com.matchstic.whodis/settingsChanged"), NULL, 0);
    
    if (sb) {
        {Class _logos_class$SpringBoard$SpringBoard = objc_getClass("SpringBoard"); MSHookMessageEx(_logos_class$SpringBoard$SpringBoard, @selector(applicationDidFinishLaunching:), (IMP)&_logos_method$SpringBoard$SpringBoard$applicationDidFinishLaunching$, (IMP*)&_logos_orig$SpringBoard$SpringBoard$applicationDidFinishLaunching$);{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(NSDictionary *), strlen(@encode(NSDictionary *))); i += strlen(@encode(NSDictionary *)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(NSString *), strlen(@encode(NSString *))); i += strlen(@encode(NSString *)); memcpy(_typeEncoding + i, @encode(NSDictionary *), strlen(@encode(NSDictionary *))); i += strlen(@encode(NSDictionary *)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$SpringBoard, @selector(_whodis_handleMessageNamed:withUserInfo:), (IMP)&_logos_method$SpringBoard$SpringBoard$_whodis_handleMessageNamed$withUserInfo$, _typeEncoding); }}
        
        inCallCenter = [CPDistributedMessagingCenter centerNamed:@"com.matchstic.whodis.incall"];
        
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/librocketbootstrap.dylib"])
            rocketbootstrap_distributedmessagingcenter_apply(inCallCenter);

    } else {
        {Class _logos_class$InCallService$PHAudioCallViewController = objc_getClass("PHAudioCallViewController"); MSHookMessageEx(_logos_class$InCallService$PHAudioCallViewController, @selector(setCurrentState:animated:), (IMP)&_logos_method$InCallService$PHAudioCallViewController$setCurrentState$animated$, (IMP*)&_logos_orig$InCallService$PHAudioCallViewController$setCurrentState$animated$);MSHookMessageEx(_logos_class$InCallService$PHAudioCallViewController, @selector(viewDidLayoutSubviews), (IMP)&_logos_method$InCallService$PHAudioCallViewController$viewDidLayoutSubviews, (IMP*)&_logos_orig$InCallService$PHAudioCallViewController$viewDidLayoutSubviews);Class _logos_class$InCallService$InCallServiceApplication = objc_getClass("InCallServiceApplication"); MSHookMessageEx(_logos_class$InCallService$InCallServiceApplication, @selector(init), (IMP)&_logos_method$InCallService$InCallServiceApplication$init, (IMP*)&_logos_orig$InCallService$InCallServiceApplication$init);{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(NSDictionary *), strlen(@encode(NSDictionary *))); i += strlen(@encode(NSDictionary *)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(NSString *), strlen(@encode(NSString *))); i += strlen(@encode(NSString *)); memcpy(_typeEncoding + i, @encode(NSDictionary *), strlen(@encode(NSDictionary *))); i += strlen(@encode(NSDictionary *)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$InCallService$InCallServiceApplication, @selector(_whodis_handleMessageNamed:withUserInfo:), (IMP)&_logos_method$InCallService$InCallServiceApplication$_whodis_handleMessageNamed$withUserInfo$, _typeEncoding); }}
        
        inCallCenter = [CPDistributedMessagingCenter centerNamed:@"com.matchstic.whodis"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/librocketbootstrap.dylib"])
            rocketbootstrap_distributedmessagingcenter_apply(inCallCenter);
    }
}
