//
//  ViewController.h
//
//
//  Copyright (c) LMS, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ReplayKit/ReplayKit.h>


@interface ViewController : UIViewController
@property (strong, nonatomic) IBOutlet UILabel *lblStatus;
@property (strong, nonatomic) IBOutlet UILabel *lblon24lbl;
@property (strong, nonatomic) IBOutlet UILabel *lblNoUrlMsg;
@property (strong, nonatomic) IBOutlet UIView *ViewScreenShare;
@property (strong, nonatomic) IBOutlet RPSystemBroadcastPickerView *viewCenter;

@end
