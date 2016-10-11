//
//  WDCallerIDViewController.m
//  
//
//  Created by Matt Clarke on 08/10/2016.
//
//

#import "WDCallerIDViewController.h"

@interface WDCallerIDViewController ()
@property (nonatomic, strong) UILabel *name;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UILabel *spamScore;
@property (nonatomic, strong) NSDictionary *currentData;
@end

@implementation WDCallerIDViewController

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor clearColor];
    
    self.name = [[UILabel alloc] initWithFrame:CGRectZero];
    self.name.text = @"";
    self.name.textAlignment = NSTextAlignmentCenter;
    self.name.textColor = [UIColor whiteColor];
    self.name.font = [UIFont systemFontOfSize:17];
    self.name.hidden = YES;
    
    [self.view addSubview:self.name];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.spinner.frame = CGRectMake(0, 0, 25, 25);
    self.spinner.hidden = YES;
    
    [self.view addSubview:self.spinner];
    
    self.spamScore = [[UILabel alloc] initWithFrame:CGRectZero];
    self.spamScore.text = @"";
    self.spamScore.textAlignment = NSTextAlignmentCenter;
    self.spamScore.textColor = [UIColor whiteColor];
    self.spamScore.font = [UIFont systemFontOfSize:17];
    self.spamScore.hidden = YES;
    
    [self.view addSubview:self.spamScore];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Layout items.
    self.spinner.center = CGPointMake(self.view.frame.size.width/2, self.spinner.frame.size.height/2);
    
    self.name.frame = CGRectMake(self.view.frame.size.width*0.1, 0, self.view.frame.size.width*0.8, 23);
    self.spamScore.frame = CGRectMake(self.view.frame.size.width*0.1, 23, self.view.frame.size.width*0.8, 23);
}

-(void)didBeginRequestingData {
    self.spinner.alpha = 0.0;
    self.spinner.hidden = NO;
    [self.spinner startAnimating];
    
    self.name.hidden = YES;
    self.spamScore.hidden = YES;
    
    self.name.text = @"";
    self.spamScore.text = @"";
    
    [UIView animateWithDuration:0.3 animations:^{
        self.spinner.alpha = 1.0;
    }];
}

-(void)updateUIWithData:(NSDictionary *)data {
    NSString *nameText = [data objectForKey:@"name"];
    NSString *spamText = @"";
    
    NSString *spamType = [data objectForKey:@"spamType"];
    
    if ([spamType isEqualToString:@"TOP_SPAMMER"]) {
        spamText = @"Marked as spam";
    } else if ([spamType isEqualToString:@"SPAMMER"]) {
        spamText = @"Potential spam";
    }
    
    self.name.text = nameText;
    self.spamScore.text = spamText;
    
    // And now, animate in.
    
    self.name.alpha = 0.0;
    self.name.hidden = NO;
    self.spamScore.alpha = 0.0;
    self.spamScore.hidden = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.name.alpha = 1.0;
        self.spamScore.alpha = 1.0;
        self.spinner.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.spinner stopAnimating];
        self.spinner.hidden = YES;
    }];
}

@end
