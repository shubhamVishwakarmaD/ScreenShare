//
//  ViewController.m
//
//
//  Copyright (c) LMS, Inc. All rights reserved.
//

#import "ViewController.h"
#import <OpenTok/OpenTok.h>
#import "AppDelegate.h"


// Replace with your group key
static NSString* const kGroupName = @"group.RSJL44J28C.com.Test.Lms";
// Replace with your Extension ID
static NSString* const kPreferredExtension = @"com.Test.Lms.BroadcastUpload";

@interface ViewController ()

@end




@implementation ViewController
//#if !(TARGET_OS_SIMULATOR)
API_AVAILABLE(ios(12.0))
RPSystemBroadcastPickerView *_broadcastPickerView;
NSUserDefaults *userDefaults;
NSTimer *timer;
UIImageView *phoneIcon;
UILabel *msgLbl;

UIDeviceOrientation newOrientation;



//#endif



#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleURLReceived:)
                                                 name:@"ScreenShareUrlReceived" object:nil];
    [self setupView];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];  // Call to the superclass method

    if (@available(iOS 11.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(capturedChange)
                                                     name:UIScreenCapturedDidChangeNotification object:nil];
    }
    if([UIScreen mainScreen].isCaptured)
    {
        self.ViewScreenShare.hidden = false;
        self.lblNoUrlMsg.hidden = true;
    }
}

-(void)setupView{
    userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kGroupName];
   
    
    
    if(![UIScreen mainScreen].isCaptured)
    {
        NSString *msg = [NSString stringWithFormat:@"Waiting for user to start screen share on ON24."];
        [userDefaults setObject:msg forKey:@"Broadcast_status"];
        [userDefaults synchronize];
        self.lblon24lbl.text = @"Waiting for user to start screen share on ON24.";
        [self.lblon24lbl setFont:[UIFont fontWithName:@"Raleway-Bold" size:[self isiPad] ?20:20]];
    }
    else{
        timer = [NSTimer scheduledTimerWithTimeInterval: 1.0
                                                 target: self
                                               selector: @selector(broadcastStatus:)
                                               userInfo: nil
                                                repeats: YES];
    }
    
    
    AppDelegate *appDelegate =  (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *dic = appDelegate.dicVonageInfo;
    
    if(dic != nil){
        [userDefaults setObject:[dic valueForKey:@"api"] forKey:@"apiKey"];
        [userDefaults setObject:[dic valueForKey:@"sessionId"] forKey:@"sessionId"];
        [userDefaults setObject:[dic valueForKey:@"token"] forKey:@"token"];
        
    }
    else
    {
        self.lblNoUrlMsg.hidden = false;
        if([timer isValid]){
            [timer invalidate];
            timer = nil;
            
        }
        
    }
    
#if !(TARGET_OS_SIMULATOR)
    if (@available(iOS 12.0, *)) {
        
        
        if([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            _broadcastPickerView =  [[RPSystemBroadcastPickerView alloc] init];
        }else if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            _broadcastPickerView =  [[RPSystemBroadcastPickerView alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
        }
        
        self.viewCenter.preferredExtension =kPreferredExtension;
        //_broadcastPickerView.center = self.view.center;
        self.viewCenter.showsMicrophoneButton = false;
        [self.viewCenter.layer setCornerRadius:10];
        [self.viewCenter.layer setMasksToBounds:YES];
        
        for (UIButton* button in self.viewCenter.subviews) {
            if([button isKindOfClass:[UIButton class]]){
                UIButton *newbtn = (UIButton *)button;
                [UIScreen mainScreen].isCaptured ? [newbtn setImage:[UIImage imageNamed:@"Icon"] forState:UIControlStateNormal] :[newbtn setImage:nil forState:UIControlStateNormal];
                [newbtn setTitle:[UIScreen mainScreen].isCaptured ? @" Stop Screenshare": @"Start Screenshare" forState:UIControlStateNormal];
                [newbtn.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Medium" size:8]];
                [newbtn setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
                [newbtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [newbtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
                [newbtn.layer setMasksToBounds:YES];
            }
        }
    } else {
        // Fallback on earlier versions
    }
#endif
    
    if(dic != nil){
       
        SEL buttonPressed = NSSelectorFromString(@"buttonPressed:");
        if([self.viewCenter respondsToSelector:buttonPressed]){
            
            [self.viewCenter performSelector:buttonPressed withObject:nil];
            
            if([UIScreen mainScreen].isCaptured)
            {
                [self.ViewScreenShare setHidden:false];
            }
            else
            {
                [self.ViewScreenShare setHidden:true];
            }
            
        }
    }
    else
    {
        self.ViewScreenShare.hidden = true;
    }
    
}

- (void)handleURLReceived:(NSNotification *)notification {
    [self setupView];
}

- (void)capturedChange {
    if (@available(iOS 11.0, *)) {
    NSLog(@"Recording Status: %s", [UIScreen mainScreen].isCaptured ? "true" : "false");
       
        
        for (UIButton* button in self.viewCenter.subviews){
              if([button isKindOfClass:[UIButton class]]){
                  UIButton *newbtn = (UIButton *)button;
                  [UIScreen mainScreen].isCaptured ? [newbtn setImage:[UIImage imageNamed:@"Icon"] forState:UIControlStateNormal] :[newbtn setImage:nil forState:UIControlStateNormal];
                  [newbtn setTitle:[UIScreen mainScreen].isCaptured ? @" Stop Screenshare": @"Start Screenshare" forState:UIControlStateNormal];
                  [newbtn.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Medium" size:[self isiPad] ?14:13]];
                  [newbtn setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
                  [newbtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                  [newbtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
                  [newbtn.layer setMasksToBounds:YES];
              }
        }
        
        
        if([UIScreen mainScreen].isCaptured)
        {
            self.ViewScreenShare.hidden = false;
            self.lblNoUrlMsg.hidden = true;
            
            timer = [NSTimer scheduledTimerWithTimeInterval: 1.0
                                 target: self
                                 selector: @selector(broadcastStatus:)
                                 userInfo: nil
                                                    repeats: YES];
           
        }
        else
        {
            self.ViewScreenShare.hidden = true;
            self.lblNoUrlMsg.hidden = false;
            if([timer isValid]){
                [timer invalidate];
                timer = nil;
                [self performSelector:@selector(broadcastStatus:) withObject:nil afterDelay:1.0];
           }
        }
        
    }
}



- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)shouldAutorotate {
    return UIUserInterfaceIdiomPhone != [[UIDevice currentDevice] userInterfaceIdiom];
}

-(BOOL)isiPad
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

-(void)broadcastStatus:(NSTimer *)timer{
   
    NSString *strMsg = [userDefaults valueForKey:@"Broadcast_status"];
    
   // NSLog(@"status %@",strMsg);
    if([strMsg isEqualToString:@"User started screenshare – connecting to vonage"])
    {
        self.lblStatus.text = @"";
        self.lblon24lbl.text = @"ON24 is sharing and recording your screen.";
        [self.lblon24lbl setFont:[UIFont fontWithName:@"Raleway-Bold" size:[self isiPad] ?20:20]];
        
    }
    
    if(![self.lblStatus.text containsString:strMsg])//||[strMsg isEqualToString:@"Subscriber Connected"]||[strMsg isEqualToString:@"Subscriber Disconnected"])
    {
        NSString *strStatus = [NSString stringWithFormat:@"%@ \n %@", self.lblStatus.text, strMsg];
        self.lblStatus.text = strStatus;
       self.lblon24lbl.text = @"ON24 is sharing and recording your screen.";
       [self.lblon24lbl setFont:[UIFont fontWithName:@"Raleway-Bold" size:[self isiPad] ?20:20]];

    
    }
    
    if([strMsg isEqualToString:@"Subscriber Disconnected"] || [strMsg isEqualToString:@"Session Disconnected"] )
    {
       // self.lblon24lbl.text = @"Waiting for user to start screen share on ON24.";
       // [self.lblon24lbl setFont:[UIFont fontWithName:@"Raleway-Bold" size:[self isiPad] ?20:16]];

    }
    if([strMsg isEqualToString:@"Session Disconnected"] )
    {
         self.lblon24lbl.text = @"Waiting for user to start screen share on ON24.";
         [self.lblon24lbl setFont:[UIFont fontWithName:@"Raleway-Bold" size:[self isiPad] ?20:20]];
    }
    if([strMsg isEqualToString:@"Subscriber Connected"])
    {
      //  self.lblon24lbl.text = @"ON24 is sharing and recording your screen";
       // [self.lblon24lbl setFont:[UIFont fontWithName:@"Raleway-Bold" size:[self isiPad] ?20:16]];

    }
    
    
   
}

@end
