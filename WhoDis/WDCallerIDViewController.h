//
//  WDCallerIDViewController.h
//  
//
//  Created by Matt Clarke on 08/10/2016.
//
//

#import <UIKit/UIKit.h>

@interface WDCallerIDViewController : UIViewController

-(void)didBeginRequestingData;
-(void)updateUIWithData:(NSDictionary*)data;

@end
