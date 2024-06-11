//
//  SampleHandler.h
//  OpenTok Live
//
//  Created .
//  Copyright © 2019 TokBox, Inc. All rights reserved.
//

#import <ReplayKit/ReplayKit.h>
#import <OpenTok/OpenTok.h>

@interface SampleHandler : RPBroadcastSampleHandler <OTVideoCapture>
{
    
}

@property(atomic, weak) id<OTVideoCaptureConsumer> _Nullable videoCaptureConsumer;
@end
