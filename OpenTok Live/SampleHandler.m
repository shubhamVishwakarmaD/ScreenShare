//
//  SampleHandler.m
//  OpenTok Live
//
//  Created .
//  Copyright © 2019 TokBox, Inc. All rights reserved.
//


#import "SampleHandler.h"
#import "OTBroadcastExtHelper.h"

#define IDIOM    [[UIDevice currentDevice]userInterfaceIdiom]
#define IPAD     UIUserInterfaceIdiomPad
#define kVideoFrameProcessEvery3rdFrame IDIOM == IPAD ? 3:3
#define kVideoFrameScaleFactor IDIOM == IPAD ? 0.45:0.30

// Replace with your group key
static NSString* const kGroupName = @"group.RSJL44J28C.com.Test.Lms";

@interface SampleHandler()<OTBroadcastExtHelperDelegate> {
    CGImagePropertyOrientation imageOrientation;
}



@end


@implementation SampleHandler
{
    CVPixelBufferPoolRef _pixelBufferPool;
    CVPixelBufferRef _pixelBuffer;
    int64_t _num_frames;
    bool skip_frame;
    CIContext * _ciContext;
    CIFilter* _scaleFilter;
    bool _capturing;
    
    OTBroadcastExtHelper *_broadcastHelper;
    
    dispatch_queue_t _capture_queue;
    
    NSUserDefaults *userDefaults;
    
    
}

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    
    userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kGroupName];
    [userDefaults setObject:@"User started screenshare – connecting to vonage" forKey:@"Broadcast_status"];
    [userDefaults synchronize];
    
    // Provide session id and token
    NSString *key = [userDefaults objectForKey:@"apiKey"];
    NSString *sessionId = [userDefaults objectForKey:@"sessionId"];
    NSString *token = [userDefaults objectForKey:@"token"];
    
    NSLog(@"apiKey %@ sessionId %@ token %@ in extension",key,sessionId,token);
    
    _broadcastHelper = [[OTBroadcastExtHelper alloc] initWithPartnerId:key
                                                             sessionId:sessionId
                                                              andToken:token
                                                         videoCapturer:self userDefault:userDefaults];
    
    
    _broadcastHelper.delegate = self;
    
    _capture_queue = dispatch_queue_create("com.tokbox.OTBroadcastVideoCapture",
                                           DISPATCH_QUEUE_SERIAL);
    
    _num_frames = 0;
    skip_frame = true;
    [self destroyPixelBuffers];
    [_broadcastHelper connect];
    
    
    
    
    // BroadcastUploaderExtension *memoryChecker = [[BroadcastUploaderExtension alloc] init];
    //[memoryChecker startMemoryPressureMonitoring];
    
}




- (void)broadcastAnnotatedWithApplicationInfo:(NSDictionary *)applicationInfo
{
    
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
    
    
    [self->_broadcastHelper disconnect];
    
    
}
- (void)finishBroadcastWithError:(NSError *)error
{
    NSString *msg = [NSString stringWithFormat:@"error - %@",error.localizedDescription];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
    
    
    
}



- (OTVideoOrientation)currentDeviceOrientation {
    // transforms are different for
    
    
    
    switch (self->imageOrientation) {
        case kCGImagePropertyOrientationLeft:
            // NSLog(@"orientation left");
            return OTVideoOrientationLeft;
        case kCGImagePropertyOrientationRight:
            // NSLog(@"orientation right");
            return OTVideoOrientationRight;
        case kCGImagePropertyOrientationUp:
            //NSLog(@"orientation portrait");
            return OTVideoOrientationUp;
        case kCGImagePropertyOrientationDown:
            //NSLog(@"orientation upsidedown");
            return OTVideoOrientationDown;
        default:
            //NSLog(@"orientation unkonown");
            return OTVideoOrientationUp;
    }
    
    
    return OTVideoOrientationUp;
}



- (void) processPixelBuffer:(CVPixelBufferRef)pixelBuffer timeStamp:(CMTime)ts
{
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer
                                               options:nil];
    
    
    
    //NSLog(@"width %f height %f",ciImage.extent.size.width,ciImage.extent.size.height);
    
    
    
    ciImage = [self scaleFilterImage:ciImage
                     withAspectRatio:1.0 scale:kVideoFrameScaleFactor];
    
    
    if(_pixelBufferPool == nil ||
       CVPixelBufferGetWidth(pixelBuffer) != CVPixelBufferGetWidth(_pixelBuffer) ||
       CVPixelBufferGetHeight(pixelBuffer) != CVPixelBufferGetHeight(_pixelBuffer))
    {
        [self destroyPixelBuffers];
        
        [self createPixelBufferPoolWithWidth:ciImage.extent.size.width
                                      height:ciImage.extent.size.height];
        
        //NSLog(@"width rs  %f height rs %f",ciImage.extent.size.width,ciImage.extent.size.height);
        
        CVPixelBufferPoolCreatePixelBuffer(NULL, _pixelBufferPool, &_pixelBuffer);
    }
    
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    if(IDIOM == IPAD ){
        
        [_ciContext render:ciImage toCVPixelBuffer:_pixelBuffer bounds:CGRectMake(0, 0, ciImage.extent.size.width/4, ciImage.extent.size.height/2) colorSpace:colorspace];
        [_ciContext render:ciImage toCVPixelBuffer:_pixelBuffer bounds:CGRectMake(ciImage.extent.size.width/4, 0, ciImage.extent.size.width/4, ciImage.extent.size.height/2) colorSpace:colorspace];
        [_ciContext render:ciImage toCVPixelBuffer:_pixelBuffer bounds:CGRectMake(ciImage.extent.size.width/2, 0, ciImage.extent.size.width/4, ciImage.extent.size.height/2) colorSpace:colorspace];
        [_ciContext render:ciImage toCVPixelBuffer:_pixelBuffer bounds:CGRectMake(ciImage.extent.size.width/2 + ciImage.extent.size.width/4, 0, ciImage.extent.size.width/4, ciImage.extent.size.height/2) colorSpace:colorspace];
        
    
        [_ciContext render:ciImage toCVPixelBuffer:_pixelBuffer bounds:CGRectMake(0, ciImage.extent.size.height/2, ciImage.extent.size.width/4, ciImage.extent.size.height/2) colorSpace:colorspace];
        [_ciContext render:ciImage toCVPixelBuffer:_pixelBuffer bounds:CGRectMake(ciImage.extent.size.width/4, ciImage.extent.size.height/2, ciImage.extent.size.width/4, ciImage.extent.size.height/2) colorSpace:colorspace];
        [_ciContext render:ciImage toCVPixelBuffer:_pixelBuffer bounds:CGRectMake(ciImage.extent.size.width/2, ciImage.extent.size.height/2, ciImage.extent.size.width/4, ciImage.extent.size.height/2) colorSpace:colorspace];
        [_ciContext render:ciImage toCVPixelBuffer:_pixelBuffer bounds:CGRectMake(ciImage.extent.size.width/2 + ciImage.extent.size.width/4, ciImage.extent.size.height/2, ciImage.extent.size.width/4, ciImage.extent.size.height/2) colorSpace:colorspace];
        
    }else {
        
        
        [_ciContext render:ciImage toCVPixelBuffer:_pixelBuffer bounds:CGRectMake(0, 0, ciImage.extent.size.width/2, ciImage.extent.size.height/2) colorSpace:colorspace];
        [_ciContext render:ciImage toCVPixelBuffer:_pixelBuffer bounds:CGRectMake(ciImage.extent.size.width/2, 0, ciImage.extent.size.width/2, ciImage.extent.size.height/2) colorSpace:colorspace];
        [_ciContext render:ciImage toCVPixelBuffer:_pixelBuffer bounds:CGRectMake(0, ciImage.extent.size.height/2, ciImage.extent.size.width/2, ciImage.extent.size.height/2) colorSpace:colorspace];
        [_ciContext render:ciImage toCVPixelBuffer:_pixelBuffer bounds:CGRectMake(ciImage.extent.size.width/2, ciImage.extent.size.height/2, ciImage.extent.size.width/2, ciImage.extent.size.height/2) colorSpace:colorspace];
        
    }
    
    CGColorSpaceRelease(colorspace);
    
    
    
    
    [self.videoCaptureConsumer consumeImageBuffer:_pixelBuffer
                                      orientation:[self currentDeviceOrientation]
                                        timestamp:ts
                                         metadata:nil];
    
}



- (bool)shouldSkipFrame
{
    
    if(_num_frames == 3)//kVideoFrameProcessEvery3rdFrame)
    {
        
        _num_frames = 0;
        return NO;
    } else
    {
        return YES;
    }
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    
    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
        {
            
            _num_frames++;
            if([self shouldSkipFrame])
                return;
            
            
            if([self->_broadcastHelper isConnected] && self->_capturing)
            {
                
                CFStringRef key = RPVideoSampleOrientationKey; // Assuming RPVideoSampleOrientationKey is a valid CFString
                NSNumber *orientationNumber = CMGetAttachment(sampleBuffer, key, (void *)&orientationNumber);
                //NSLog(@"orientation number %d",[orientationNumber intValue]);
                
                self->imageOrientation = [orientationNumber intValue];
                
                [self processPixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer)
                               timeStamp:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        
            }
        }
            break;
        case RPSampleBufferTypeAudioApp:
        {
            // Handle audio sample buffer for app audio
        }
            break;
        case RPSampleBufferTypeAudioMic:
        {
            
            // Handle audio sample buffer for mic audio
            if([_broadcastHelper isConnected])
            {
                [_broadcastHelper writeAudioSamples:sampleBuffer];
            }
           
        }
            break;
            
        default:
            break;
    }
}

- (void)initCapture {
    _scaleFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
    _ciContext = [CIContext contextWithOptions: nil];
}

- (void)releaseCapture {
    _ciContext = nil;
    _scaleFilter = nil;
    [self destroyPixelBuffers];
}

- (int32_t)startCapture
{
    dispatch_async(_capture_queue, ^{
        self->_capturing = YES;
    });
    return 0;
}

- (int32_t)stopCapture
{
    dispatch_async(_capture_queue, ^{
        self->_capturing = NO;
    });
    
    return 0;
}

- (BOOL)isCaptureStarted
{
    return _capturing;
}

- (int32_t)captureSettings:(OTVideoFormat*)videoFormat
{
    videoFormat.pixelFormat = OTPixelFormatARGB;
    return 0;
}

-(void)destroyPixelBuffers
{
    if(_pixelBuffer)
        CVPixelBufferRelease(_pixelBuffer);
    _pixelBuffer = nil;
    
    if(_pixelBufferPool)
        CVPixelBufferPoolRelease(_pixelBufferPool);
    _pixelBufferPool = nil;
}

- (void)createPixelBufferPoolWithWidth:(int)width height:(int)height
{
    
    [self destroyPixelBuffers];
    OSType pixelFormat =  kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
    
    
    CFMutableDictionaryRef sourcePixelBufferOptions = CFDictionaryCreateMutable( kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks );
    CFNumberRef number = CFNumberCreate( kCFAllocatorDefault, kCFNumberSInt32Type, &pixelFormat );
    CFDictionaryAddValue( sourcePixelBufferOptions, kCVPixelBufferPixelFormatTypeKey, number );
    CFRelease( number );
    
    number = CFNumberCreate( kCFAllocatorDefault, kCFNumberSInt32Type, &width );
    CFDictionaryAddValue( sourcePixelBufferOptions, kCVPixelBufferWidthKey, number );
    CFRelease( number );
    
    number = CFNumberCreate( kCFAllocatorDefault, kCFNumberSInt32Type, &height );
    CFDictionaryAddValue( sourcePixelBufferOptions, kCVPixelBufferHeightKey, number );
    CFRelease( number );
    
    ((__bridge NSMutableDictionary *)sourcePixelBufferOptions)[(id)kCVPixelBufferIOSurfacePropertiesKey] = @{ @"IOSurfaceIsGlobal" : @YES };
    
    CVPixelBufferPoolCreate( kCFAllocatorDefault, NULL, sourcePixelBufferOptions, &_pixelBufferPool);
    
}

- (CIImage*) scaleFilterImage: (CIImage*)inputImage withAspectRatio:(CGFloat)aspectRatio scale:(CGFloat)scale
{
    
    if(IDIOM == IPAD ){
        
        CGSize targetSize = CGSizeMake(568, 828);
        
        int targetHeight = targetSize.height; //+ (4 - ((int)(targetSize.height) % 4));
        float scale1 = targetHeight / inputImage.extent.size.height;
        float aspectRatio1 = targetSize.width/((inputImage.extent.size.width)*scale1);
        
        [_scaleFilter setValue:inputImage forKey:kCIInputImageKey];
        [_scaleFilter setValue:@(scale1) forKey:kCIInputScaleKey];
        [_scaleFilter setValue:@(aspectRatio1) forKey:kCIInputAspectRatioKey];
    }
    else
    {
        
        CGSize targetSize = [[UIScreen mainScreen] bounds].size;
        int targetWidth = targetSize.width + (4 - ((int)(targetSize.width) % 4));
        float scale1 = targetSize.height / inputImage.extent.size.height;
        float aspectRatio1 = targetWidth/((inputImage.extent.size.width)*scale1);
        
        [_scaleFilter setValue:inputImage forKey:kCIInputImageKey];
        [_scaleFilter setValue:@(scale1) forKey:kCIInputScaleKey];
        [_scaleFilter setValue:@(aspectRatio1) forKey:kCIInputAspectRatioKey];
    }
    
    return _scaleFilter.outputImage;
}





@synthesize videoContentHint;

#pragma mark -
#pragma mark === OTBroadcastExtHelperDelegate delegate callbacks ===

- (void)finishedStream:(NSString*)strMsg {
    
    NSString *domain = @"ScreenShare";
    NSString *desc = NSLocalizedString(strMsg, @"");
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
    NSError *error = [NSError errorWithDomain:domain code:-1 userInfo:userInfo];
    
    
    [super finishBroadcastWithError:error];
    
}



@end





