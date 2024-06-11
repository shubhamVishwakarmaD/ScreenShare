//
//  OTBroadcastExtHelper.h
//  OpenTok Live
//
//  Created .
//  Copyright © 2019 TokBox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenTok/OpenTok.h>


NS_ASSUME_NONNULL_BEGIN

@protocol OTBroadcastExtHelperDelegate<NSObject>
- (void)finishedStream:(NSString*)strMsg;

@end





@interface OTBroadcastExtHelper : NSObject
{
    
}
@property (nonatomic, weak) id <OTBroadcastExtHelperDelegate> delegate;
-(instancetype)initWithPartnerId:(NSString *)partnerId
                       sessionId:(NSString *)sessionId
                        andToken:(NSString *)token
                   videoCapturer:(id <OTVideoCapture>)videoCapturer userDefault:(NSUserDefaults *)userDefault;

-(void)connect;
-(void)disconnect;
- (BOOL)isConnected;

-(void)writeAudioSamples:(CMSampleBufferRef)sampleBuffer;



@end

NS_ASSUME_NONNULL_END
