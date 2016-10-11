#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "WDCallerIDViewController.h"
#import "WDDataDownloader.h"
#import "WDResources.h"

//////////////////////////////////////////////////////////////////////
// Internal headers

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

///////////////////////////////////////////////////////////////////////////
// Function definitions

extern "C" {
    void rocketbootstrap_distributedmessagingcenter_apply(CPDistributedMessagingCenter *messaging_center);
}

NSDictionary *constructParametersForNumber(NSString *number);
NSString *formatDictionaryIntoURLString(NSDictionary *dict);
void getTruecallerInformatonForNumber(NSString *number);
void analyseResultingData(NSData *data);

///////////////////////////////////////////////////////////////////////////
// Globals

static CPDistributedMessagingCenter *sbCenter;
static CPDistributedMessagingCenter *inCallCenter;
static WDCallerIDViewController *callerIDController;
static WDDataDownloader *dataDownloader;
static NSString *inCallCurrentDownloadNumber;

///////////////////////////////////////////////////////////////////////////
// Actual code

%group InCallService

// Construct parameters to send to the Truecaller API
NSDictionary *constructParametersForNumber(NSString *number) {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    // q is phone number coming in - need to strip it as needed.
    number = [number stringByReplacingOccurrencesOfString:@"-" withString:@""];
    number = [number stringByReplacingOccurrencesOfString:@" " withString:@""];
    number = [number stringByReplacingOccurrencesOfString:@"(" withString:@""];
    number = [number stringByReplacingOccurrencesOfString:@")" withString:@""];
    number = [number stringByReplacingOccurrencesOfString:@"+" withString:@"00"];
    
    // myNumber - gotta get SB to pull this due to an entitlement.
    NSDictionary *reply = [inCallCenter sendMessageAndReceiveReplyName:@"getThing" userInfo:nil];
    NSString *myNumber = [reply objectForKey:@"myNumber"];
    if (!myNumber)
        myNumber = @"";
    
    // requestId
    LSApplicationProxy *proxy = [LSApplicationProxy applicationProxyForIdentifier:@"com.truesoftware.TrueCallerOther"];
    NSString *defaultsPath = [[proxy.dataContainerURL absoluteString] stringByAppendingString:@"/Library/Preferences/com.truesoftware.TrueCallerOther.plist"];
    defaultsPath = [defaultsPath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
    
    NSString *requestId = [defaults objectForKey:@"id"];
    if (!requestId)
        requestId = @"";
    
    // countryCode
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

// Create full URL string.
NSString *formatDictionaryIntoURLString(NSDictionary *dict) {
    NSMutableString *string = [@"https://search5.truecaller.com/v2/search?client_id=1&clientId=1" mutableCopy];
    
    for (NSString *key in [dict allKeys]) {
        [string appendFormat:@"&%@=%@", key, [dict objectForKey:key]];
    }
    
    return string;
}

// One function to call when needed, rather than 4.
void getTruecallerInformatonForNumber(NSString *number) {
    // XXX: We only want to initiate a download if the number is different to what we had previously.
    
    if (![inCallCurrentDownloadNumber isEqualToString:number]) {
        NSDictionary *params = constructParametersForNumber(number);
        NSString *jsonURL = formatDictionaryIntoURLString(params);
    
        // XXX: We want SpringBoard to do the downloading for us too.
        // This is to ensure that InCallService doesn't show up in the Battery usage tab
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        [info setObject:jsonURL forKey:@"url"];
        [inCallCenter sendMessageName:@"downloadFromURL" userInfo:info];
        
        inCallCurrentDownloadNumber = number;
    }
}

// And finally, parse the JSON data downloaded from SpringBoard.
void analyseResultingData(NSData *dataIn) {
    inCallCurrentDownloadNumber = @"";
    
    if (!dataIn || dataIn.length == 0) {
        // Handle no data accessible
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
        // Handle error in parsing data
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
        // Unauthorised - requestId or myNumber are invalid.
        // Might want to check that Truecaller is installed?
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
        // No data available.
        NSMutableDictionary *finalData = [NSMutableDictionary dictionary];
        [finalData setObject:@"No data available" forKey:@"name"];
        [finalData setObject:@"NONE" forKey:@"spamType"];
        [finalData setObject:[NSNumber numberWithInt:0] forKey:@"spamScore"];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [callerIDController updateUIWithData:finalData];
        });
        return;
    }
    
    // Gor through and parse all the data that's available.
    
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
    
    /* Data:
     altName
     about
     image - direct URL
     jobTitle
     companyName
     access
     */
    
    /* internet addresses:
     service
     email
     */
    
    // images1.truecaller.com
    
    //NSString *countryCode = [phone objectForKey:@"countryCode"];
    //NSString *carrier = [phone objectForKey:@"carrier"];
    NSNumber *spamScore = [phone objectForKey:@"spamScore"];
    if (!spamScore)
        spamScore = [NSNumber numberWithInt:0];
    NSString *spamType = [phone objectForKey:@"spamType"];
    if (!spamType)
        spamType = @"NONE"; // TOP_SPAMMER, SPAMMER
    NSString *name = [[data firstObject] objectForKey:@"name"];
    if (!name)
        name = @"No caller name available";
    
    // update UI as needed.
    
    NSMutableDictionary *finalData = [NSMutableDictionary dictionary];
    [finalData setObject:name forKey:@"name"];
    [finalData setObject:spamType forKey:@"spamType"];
    [finalData setObject:spamScore forKey:@"spamScore"];
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [callerIDController updateUIWithData:finalData];
    });
}

%hook PHAudioCallViewController

/*
 States:
 0 = incoming call
 1 = outgoing call
 2 = 
 3 = answered pressed
 4 =
 5 = ending
 6 = ended
 7 = disconnect at baseband level?
 */

- (void)setCurrentState:(unsigned short)arg1 animated:(_Bool)arg2 {
    if (arg1 != 0 && arg1 != 1) {
        // Hide the view since no longer incoming state.
        
        if (callerIDController.view.alpha != 0.0) {
            callerIDController.view.alpha = 0.0;
            
            // Cancel the download if there's one still going, as we don't need it now.
            [inCallCenter sendMessageName:@"cancelDownload" userInfo:nil];
        }
    } else if (arg1 == 0 || arg1 == 1) {
        // Show view if needed.
        [WDResources reloadSettings];
        BOOL shouldShow = (arg1 == 0 ? [WDResources displayOnIncomingCalls] : [WDResources displayOnOutgoingCalls]);
        
        // TODO: Should we also display for outgoing calls too? It's not like it's hard.
        
        @try {
            // Sometimes, this function will do a stupid and crash InCallService. This will make a lot of people very angry
            // and is widely regarded as a bad move.
            NSString *numberOrName = [self.callParticipantsViewController nameForParticipantAtIndex:0 inParticipantsView:self.callParticipantsViewController.participantsView];
            
            // Check if the number shown is a phone number. This should in theory nicely handle when "No caller ID" is
            // shown, or when it's a contact - don't want to run on those two anyway.
            //
            // This might also be able to handle FaceTime video or Audio when the other party uses a phone number.
        
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
            
                // Make caller ID view visible pls.
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
    
    %orig;
}

-(void)viewDidLayoutSubviews {
    %orig;
    
    // We want to plonk our UI down where the "mobile", or "home" string is usually placed.
    // Note that sometimes iOS can judge the geolocation of an unknown call, so we don't to place our text over that.
    
    PHCallParticipantsView *participants = self.callParticipantsViewController.participantsView;
    UILabel *statusLabel = participants.singleCallLabelView.statusLabel;
    
    CGFloat yOrigin = ([statusLabel.text isEqualToString:@""] ? statusLabel.frame.origin.y : participants.frame.size.height + participants.frame.origin.y) + 10;
    
    CGRect frame = CGRectMake(0, yOrigin, participants.frame.size.width, 50);
    callerIDController.view.frame = frame;
}

%end

%hook InCallServiceApplication

-(id)init {
    id orig = %orig;
    
    // XXX: We reuse the sbCenter var here since it's nil anyway in this process, and listen for data coming
    // back from SpringBoard.
    sbCenter = [CPDistributedMessagingCenter centerNamed:@"com.matchstic.whodis.incall"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/librocketbootstrap.dylib"])
        rocketbootstrap_distributedmessagingcenter_apply(sbCenter);
        
    [sbCenter runServerOnCurrentThread];
    [sbCenter registerForMessageName:@"finishedDownload" target:orig selector:@selector(_whodis_handleMessageNamed:withUserInfo:)];
    
    return orig;
}

%new
-(NSDictionary *)_whodis_handleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userinfo {
    if ([name isEqualToString:@"finishedDownload"]) {
        NSData *data = [userinfo objectForKey:@"data"];
        analyseResultingData(data);
    }
    
    return nil;
}

%end

%end

%group SpringBoard

%hook SpringBoard

-(void)applicationDidFinishLaunching:(id)application {
    %orig;
    
    sbCenter = [CPDistributedMessagingCenter centerNamed:@"com.matchstic.whodis"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/librocketbootstrap.dylib"])
        rocketbootstrap_distributedmessagingcenter_apply(sbCenter);
        
    [sbCenter runServerOnCurrentThread];
    [sbCenter registerForMessageName:@"getThing" target:self selector:@selector(_whodis_handleMessageNamed:withUserInfo:)];
    [sbCenter registerForMessageName:@"downloadFromURL" target:self selector:@selector(_whodis_handleMessageNamed:withUserInfo:)];
    [sbCenter registerForMessageName:@"cancelDownload" target:self selector:@selector(_whodis_handleMessageNamed:withUserInfo:)];
    
    // XXX: Since I fully expect users to not read, display a popup on appFinishLaunch if they don't have Truecaller installed.
    BOOL installed = [[objc_getClass("SBUserAgent") sharedUserAgent] applicationInstalledForDisplayID:@"com.truesoftware.TrueCallerOther"];
    if (!installed) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Who Dis?" message:@"Install and setup the Truecaller app from the App Store to use this tweak." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [av show];
    }
}

%new
-(NSDictionary *)_whodis_handleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userinfo {
    if ([name isEqualToString:@"getThing"]) {
        // TODO: I really should cache myNumber, saves having to query against lsd every time a phone call comes in.
        
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
            // Communicate *back* to InCallService with NSData in dict.
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

%end

%end

static void WhoDisSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [WDResources reloadSettings];
}

%ctor {
    %init;
    
    // XXX: We need to go multi-process so that we can leverage an entitlement from SB to talk to lsd.
    
    BOOL sb = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"];
    [WDResources reloadSettings];
    
    CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(r, NULL, WhoDisSettingsChanged, CFSTR("com.matchstic.whodis/settingsChanged"), NULL, 0);
    
    if (sb) {
        %init(SpringBoard);
        
        inCallCenter = [CPDistributedMessagingCenter centerNamed:@"com.matchstic.whodis.incall"];
        
        // Sanity check, just in case the user is a little dim and decided to disable rocketbootstrap somehow.
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/librocketbootstrap.dylib"])
            rocketbootstrap_distributedmessagingcenter_apply(inCallCenter);

    } else {
        %init(InCallService);
        
        inCallCenter = [CPDistributedMessagingCenter centerNamed:@"com.matchstic.whodis"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/librocketbootstrap.dylib"])
            rocketbootstrap_distributedmessagingcenter_apply(inCallCenter);
    }
}