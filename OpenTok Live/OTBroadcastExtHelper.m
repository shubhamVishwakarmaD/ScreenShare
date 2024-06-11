//
//  OTBroadcastExtHelper.m
//  OpenTok Live
//
//  Created .
//  Copyright © 2019 TokBox, Inc. All rights reserved.
//

#import "OTBroadcastExtHelper.h"
#import "OTBroadcastExtAudioDevice.h"



@interface OTBroadcastExtHelper () <OTSessionDelegate, OTSubscriberKitDelegate, OTPublisherDelegate,OTPublisherKitNetworkStatsDelegate>
{
   
   
}
@end

@implementation OTBroadcastExtHelper
{
    NSString *_partnerId;
    NSString *_sessionId;
    NSString *_token;
    
    // OT vars
    OTSession* _session;
    OTPublisher* _publisher;
    OTSubscriber* _subscriber;
    OTBroadcastExtAudioDevice* _audioDevice;
    
    
    id <OTVideoCapture> _videoCapturer;
    NSUserDefaults *userDefaults;
    
    
    
}
@synthesize delegate;

-(instancetype)initWithPartnerId:(NSString *)partnerId
                       sessionId:(NSString *)sessionId
                        andToken:(NSString *)token
                   videoCapturer:(id <OTVideoCapture>)videoCapturer userDefault:(nonnull NSUserDefaults *)userDefault
{
    self = [super init];
    if (self) {
        _partnerId = partnerId;
        _sessionId = sessionId;
        _token = token;
        _videoCapturer = videoCapturer;
        userDefaults = userDefault;
    }
    return self;
    
}





-(void)showMessage:(NSString *)message
{
    // for now we log to the console.
    NSLog(@"[ERROR] %@",message);
    
    NSString *msg = [NSString stringWithFormat:@"[ERROR] %@",message];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
    
}

-(void)connect
{
    
   
    
    if (_partnerId.length == 0 || _sessionId.length == 0 || _token.length == 0)
    {
        [self showMessage:@"[ERROR] Invalid OpenTok session info."];
        return;
    }
    
    if(_session.sessionConnectionStatus == OTSessionConnectionStatusConnected)
    {
        [self showMessage:@"[ERROR] Session already connected!"];
        return;
    }
    
    if(!_audioDevice)
    {
        _audioDevice =
        [[OTBroadcastExtAudioDevice alloc] init];
        [OTAudioDeviceManager setAudioDevice:_audioDevice];
    }
    
    _session = [[OTSession alloc] initWithApiKey:_partnerId
                                       sessionId:_sessionId
                                        delegate:self];
    
    OTError *error = nil;
    [_session connectWithToken:_token error:&error];
    if (error)
    {
        [self showMessage:[error localizedDescription]];
    }
    
}



-(void)disconnect
{
    
    
    NSString *msg = [NSString stringWithFormat:@"Users initiated screenshare stop"];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
    
    
    [self doUnPublish];
    
    OTError *error = nil;
    [_session disconnect:&error];
    if (error)
    {
        [self showMessage:[error localizedDescription]];
    }
    else
    {
        [self cleanupPublisher];
        NSString *msg = [NSString stringWithFormat:@"Session Disconnected"];
        [userDefaults setObject:msg forKey:@"Broadcast_status"];
        [userDefaults synchronize];
    }
}

- (void)doPublish
{
    OTPublisherSettings *settings = [[OTPublisherSettings alloc] init];
    settings.videoCapture = _videoCapturer;
    settings.name = [[UIDevice currentDevice] name];
    
    // settings.scalableScreenshare = true;
    
    _publisher = [[OTPublisher alloc] initWithDelegate:self
                                              settings:settings];
    
    _publisher.publishAudio = false;
    _publisher.videoType = OTPublisherKitVideoTypeScreen;
    
    _publisher.networkStatsDelegate = self;
    
    
    
    OTError *error = nil;
    [_session publish:_publisher error:&error];
    if (error)
    {
        [self showMessage:[error localizedDescription]];
    }
    else
    {
        NSString *msg = [NSString stringWithFormat:@"Screenshare started"];
        [userDefaults setObject:msg forKey:@"Broadcast_status"];
        [userDefaults synchronize];
        
        [self sendSignal];
    }
}
-(void)doUnPublish
{
    OTError *error = nil;
    [_session unpublish:_publisher error:&error];
    if (error)
    {
        [self showMessage:[error localizedDescription]];
    }
    else
    {
        NSString *msg = [NSString stringWithFormat:@"Screenshare stopped"];
        [userDefaults setObject:msg forKey:@"Broadcast_status"];
        [userDefaults synchronize];
    }
    
}

- (void)doSubscribe:(OTStream*)stream
{
    OTSubscriber *subscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
    subscriber.subscribeToVideo = NO; // Nothing to show on the broadcast extension.
    
    OTError *error = nil;
    [_session subscribe:subscriber error:&error];
    if (error)
    {
        [self showMessage:[error localizedDescription]];
    }
}

- (void)cleanupPublisher
{
    _publisher = nil;
}

- (void)cleanupSubscriber
{
    _subscriber = nil;
}

- (void)cleanupSession
{
    _session = nil;
}

- (BOOL)isConnected
{
    return _session.sessionConnectionStatus == OTSessionConnectionStatusConnected;
}
-(void)writeAudioSamples:(CMSampleBufferRef)sampleBuffer
{
    [_audioDevice writeAudioSamples:sampleBuffer];
}


#pragma mark -
#pragma mark === OTSession delegate callbacks ===

- (void)sessionDidConnect:(OTSession*)session
{
    NSLog(@"sessionDidConnect (%@)", session.sessionId);
    NSString *msg = [NSString stringWithFormat:@"Session Connected "];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
    
    [self doPublish];
    
}

- (void)sessionDidDisconnect:(OTSession*)session
{
    NSLog(@"sessionDidDisconnect (%@)", session.sessionId);
    NSString *msg = [NSString stringWithFormat:@"Session Disconnected"];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
    
    
    [self cleanupPublisher];
    [self cleanupSubscriber];
    [self cleanupSession];
    
    
}

- (void)session:(OTSession*)mySession streamCreated:(OTStream *)stream
{
    NSLog(@"session streamCreated (Id: %@, Name: %@, ConnectionId: %@)", stream.streamId, stream.name, stream.connection.connectionId);
    
    NSString *msg = [NSString stringWithFormat:@"Session streamCreated"];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
}


- (void)session:(OTSession*)session streamDestroyed:(OTStream *)stream
{
    NSLog(@"session streamDestroyed (Id: %@, Name: %@, ConnectionId: %@)", stream.streamId, stream.name, stream.connection.connectionId);
    
    if([_subscriber.stream.streamId isEqualToString:stream.streamId])
        [self cleanupSubscriber];
    
    NSString *msg = [NSString stringWithFormat:@"Session streamDestroyed"];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
}

- (void)session:(OTSession *)session connectionCreated:(OTConnection *)connection
{
    NSLog(@"session connectionCreated (%@)", connection.connectionId);
    
    NSString *msg = [NSString stringWithFormat:@"Subscriber Connected"];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
}

- (void)session:(OTSession *)session connectionDestroyed:(OTConnection *)connection
{
    NSLog(@"session connectionDestroyed (%@)", connection.connectionId);
    if([_subscriber.stream.connection.connectionId isEqualToString:connection.connectionId])
        [self cleanupSubscriber];
    
    NSString *msg = [NSString stringWithFormat:@"Subscriber Disconnected"];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
    
    
    
}

- (void)session:(OTSession*)session didFailWithError:(OTError*)error
{
    NSLog(@"didFailWithError: (%@)", error);
    
    NSString *msg = [NSString stringWithFormat:@"didFailWithError: (%@)", error.localizedDescription];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
    
    [self.delegate finishedStream:error.localizedDescription];
}

- (void)   session:(OTSession*)session
receivedSignalType:(NSString*)type
    fromConnection:(OTConnection*)connection
        withString:(NSString*)string
{
    NSLog(@"Received receivedSignalType %@  fromConnection %@ withString %@",type,connection.data,string);
    
    Boolean fromSelf = NO;
    if ([connection.connectionId isEqualToString:session.connection.connectionId]) {
        fromSelf = YES;
        NSLog(@"self signal");
    }
    else if([type isEqualToString:@"cfs"])
    {
        NSString *jsonString = string;
        
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *error = nil;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        
        if (!jsonDict) {
            NSLog(@"Error parsing JSON string: %@", error);
            
        }
        
        NSLog(@"JSON dictionary: %@", jsonDict);
        
        NSDictionary *dicData = jsonDict[@"data"];
        NSString *message = jsonDict[@"message"];
        if([message isEqualToString:@"call.main.room.participant.kick_out"] )
        {
            [self.delegate finishedStream:@"Meeting end"];
        }
        else if(dicData != nil)
        {
            NSNumber *publishNumber = dicData[@"publish"];
            BOOL publisher;
            if (publishNumber != nil) {
                publisher = [publishNumber boolValue];
                NSLog(@"Key 'publish' is here");
                if (!publisher)
                {
                    [self.delegate finishedStream:@"Another device has started screen share"];
                }
            } else {
                // Key 'publish' is not present in the dictionary
                NSLog(@"Key 'publish' is not present in the dictionary");
            }
        }
    }
}
#pragma mark -
- (void) sendSignal
{
    //    NSDictionary *data = @{
    //                @"data": @{
    //                    @"publish": @NO
    //                }
    //            };
    NSDictionary *data = @{
        @"channel0": @"cfs",
        @"channel1": @"all",
        @"data": @{
            @"exclude": @[],//@"OT_515fcb58-cbbc-4b07-894f-8003a0b21453"
            @"publish": @NO
        },
        @"direction": @"broadcast",
        @"id": @"",//@"1714470803185-716167-msg"
        @"message": @"call.presentation.room.participant.video.publish",
        @"path": @[
            @{
                @"type0": @"cfs.call.presentation",
                @"type1": @""//f4148aa8-aa9b-4dae-820d-0a1a9c30a3e7
            }
        ]
    };
    
    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&err];
    
    if (!jsonData) {
        NSLog(@"Error creating JSON data: %@", err);
        
    }
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"JSON string: %@", jsonString);
    
    
    
    
    OTError* error = nil;
    [_session signalWithType:@"cfs" string:jsonString connection:nil retryAfterReconnect:NO error:&error];
    
    if (error) {
        NSLog(@"Signal error: %@", error);
    } else {
        
    }
    
}


#pragma mark -
#pragma mark === OTSubscriber delegate callbacks ===

- (void)subscriberDidConnectToStream:(OTSubscriberKit*)subscriber
{
    NSLog(@"subscriberDidConnectToStream: %@ (connectionId: %@, video type: %d)", subscriber.stream.name, subscriber.stream.connection.connectionId, subscriber.stream.videoType);
}

- (void)subscriber:(OTSubscriberKit*)subscriber didFailWithError:(OTError*)error
{
    NSLog(@"subscriber %@ didFailWithError %@", subscriber.stream.streamId, error);
}

- (void)subscriberVideoDisabled:(OTSubscriberKit*)subscriber reason:(OTSubscriberVideoEventReason)reason
{
    NSLog(@"subscriberVideoDisabled %@, reason : %d", subscriber, reason);
}

- (void)subscriberVideoEnabled:(OTSubscriberKit*)subscriber reason:(OTSubscriberVideoEventReason)reason
{
    NSLog(@"subscriberVideoEnabled %@, reason : %d", subscriber, reason);
}

#pragma mark -
#pragma mark === OTPublisher delegate callbacks ===

- (void)publisher:(OTPublisherKit *)publisher streamCreated:(OTStream *)stream
{
    // This is safe since ReplayKit doesn't send any audio samples, if mic is disabled.
    _publisher.publishAudio = false;
    NSLog(@"publisher streamCreated: %@", stream);
    // NSLog(@"publisher stream connection id: %@", stream.connection.connectionId);
    
    NSString *msg = [NSString stringWithFormat:@"Screenshare in process"];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
    
   
}

- (void)publisher:(OTPublisherKit*)publisher streamDestroyed:(OTStream *)stream
{
    [self cleanupPublisher];
    
   
}

- (void)publisher:(OTPublisherKit*)publisher didFailWithError:(OTError*) error
{
    NSString *msg = [NSString stringWithFormat:@"publisher didFailWithError: (%@)", error.localizedDescription];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
    
    
    NSLog(@"publisher didFailWithError %@", error);
    [self cleanupPublisher];
}


#pragma mark -
#pragma mark === Publisher NetworkStats Delegate callbacks ===

- (void)publisher:(nonnull OTPublisherKit*)publisher
videoNetworkStatsUpdated:(nonnull NSArray<OTPublisherKitVideoNetworkStats*>*)stats;
{
    // NSLog(@"stats connectionId %@ subscriberId %@ \n %lld \n %lld  \n %lld",stats.firstObject.connectionId,stats.firstObject.subscriberId,stats.firstObject.videoPacketsSent,stats.firstObject.videoPacketsLost,stats.firstObject.videoBytesSent);
}

@end
