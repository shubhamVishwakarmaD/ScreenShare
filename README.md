On24 iOS screen sharing App
===========================
 
** The app will only work with properly H264 video codec and with other codec we might have neneory crashes. Make sure that your API key is enabled for it.
 
Setup Guideline
 
Dynamically set the OpenTok session ID and token in the setupInfo object passed into the broadcastStartedWithSetupInfo: method (in SampleHandler.m) from the webpage.
 
Restriction: This app will not work in the Simulator. You need to use a real device.
 
The project includes two targets:
 
On24ScreenShare: This is the main application target and uses RPSystemBroadcastPickerView to launch the iOS broadcast extension UI dialog with "OpenTok Live" as the only available extension.

OpenTok Live: This target handles the OpenTok functionality, including a custom video capturer (SampleHandler). The OTBroadcastExtHelper class manages OpenTok objects. Video samples are scaled down using a CILanczosScaleTransform CIFilter and a CVPixelBufferPool to manage memory efficiently.
 
For more information on the iOS Broadcast Upload Extension, see the Apple App Extension and ReplayKit documentation.
[app extension](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/index.html)
and [ReplayKit](https://developer.apple.com/documentation/replaykit) documentation.
has context menu.
 
Guide to Run the Application

## OS and Tools Requirement:
1. Xcode 15.3 or later
2. iOS 13 or later


##Project Setup Instructions:

Navigate to the On24ScreenShare folder.
Open On24ScreenShare.xcworkspace.
Configure the Bundle Identifier and App Groups at the Apple Developer portal, follow URL to setup required things. (https://developer.apple.com/help/account/manage-identifiers/register-an-app-id).
Change the App group name and preferredExtension in ViewController.
Build and run the app in real device.



