#import "RevMobPlugin.h"

@interface RevMobPlugin ()

- (void)deviceOrientationChange:(NSNotification *)notification;

- (void)updateViewFrames;

@end

@implementation RevMobPlugin

#pragma mark - CDVPlugin

- (void)pluginInitialize {
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(deviceOrientationChange:)
                   name:UIDeviceOrientationDidChangeNotification
                 object:nil];

    self.containerView = self.webView.superview;
    self.containerView.backgroundColor = [UIColor blackColor];

    // precalculate all frame sizes and positions
    CGSize containerSize = self.containerView.frame.size;
    CGFloat max = MAX(containerSize.width, containerSize.height);
    CGFloat min = MIN(containerSize.width, containerSize.height);
    float bannerWidth = [UIScreen mainScreen].bounds.size.width;
    float bannerHeight;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        bannerHeight = 90;
    } else {
        bannerHeight = 50;
    }


    self.bannerFrameTopLandscape = CGRectMake(max / 2 - bannerWidth / 2, 0, bannerWidth, bannerHeight);
    self.bannerFrameBottomLandscape = CGRectMake(max / 2 - bannerWidth / 2, min - bannerHeight, bannerWidth, bannerHeight);
    self.webViewFrameTopLandscape = CGRectMake(0, bannerHeight, max, min - bannerHeight);
    self.webViewFrameBottomLandscape = CGRectMake(0, 0, max, min - bannerHeight);

    self.bannerFrameTopPortrait = CGRectMake(min / 2 - bannerWidth / 2, 0, bannerWidth, bannerHeight);
    self.bannerFrameBottomPortrait = CGRectMake(min / 2 - bannerWidth / 2, max - bannerHeight, bannerWidth, bannerHeight);
    self.webViewFrameTopPortrait = CGRectMake(0, bannerHeight, min, max - bannerHeight);
    self.webViewFrameBottomPortrait = CGRectMake(0, 0, min, max - bannerHeight);

    [self updateViewFrames];
}

#pragma mark - RevMobPlugin


- (void)init:(CDVInvokedUrlCommand *)command {

    self.eventCallback = command;
}

- (void)startSession:(CDVInvokedUrlCommand *)command {

    NSString *appId = [command argumentAtIndex:0];
    NSLog(@"Starting session for appId: %@", appId);
    [RevMobAds startSessionWithAppID:appId withSuccessHandler:^{

        self.sessionStarted = true;
        if (self.testingMode) {
            [RevMobAds session].testingMode = self.testingMode;
        }
        if (self.timeout) {
            [RevMobAds session].connectionTimeout = self.timeout;
        }
        if (self.pendingBanner) {
            [self showBannerAd:self.pendingBanner];
        }
        if (self.pendingInterstitial) {
            [self showInterstitialAd:self.pendingInterstitial];
        }
        if (self.pendingPopup) {
            [self showPopupAd:self.pendingPopup];
        }

        [self raiseEvent:@"revmobSessionStarted"];

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }                 andFailHandler:^(NSError *error) {

        NSDictionary *errorData = @{
                @"code": @(error.code),
                @"message": error.description
        };
        [self raiseEvent:@"revmodSessionStartFailed" withData:errorData];
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorData];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)raiseEvent:(NSString *)type {

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{
            @"type": type
    }];
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:self.eventCallback.callbackId];
}

- (void)raiseEvent:(NSString *)type withData:(NSDictionary *)data {

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{
            @"type": type,
            @"data": data
    }];
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:self.eventCallback.callbackId];
}

- (void)enableTestMode:(CDVInvokedUrlCommand *)command {

    RevMobAdsTestingMode testingMode = [[command argumentAtIndex:0 withDefault:@"YES"] boolValue] ? RevMobAdsTestingModeWithAds : RevMobAdsTestingModeWithoutAds;
    self.testingMode = testingMode;
    if (self.sessionStarted) {
        [RevMobAds session].testingMode = testingMode;
    }
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)disableTestMode:(CDVInvokedUrlCommand *)command {

    self.testingMode = RevMobAdsTestingModeOff;
    if (self.sessionStarted) {
        [RevMobAds session].testingMode = RevMobAdsTestingModeOff;
    }
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)openAdLink:(CDVInvokedUrlCommand *)command {

    // todo: make this work like everything else
    if (self.sessionStarted) {
        if (self.adLink == nil) {
            self.adLink = [[RevMobAds session] adLink];
        }
        [self.adLink loadWithSuccessHandler:^(RevMobAdLink *adLink) {
            [adLink openLink];
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }                andLoadFailHandler:^(RevMobAdLink *adLink, NSError *error) {
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"%@", error]];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }];
    } else {

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session Has Not Started"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }

}

- (void)showPopupAd:(CDVInvokedUrlCommand *)command {


    if (self.sessionStarted) {
        if (self.popupAd == nil) {
            self.popupAd = [[RevMobAds session] popup];
        }
        [self.popupAd loadWithSuccessHandler:^(RevMobPopup *popup) {
            [popup showAd];
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            [self raiseEvent:@"popupLoaded"];
            [self raiseEvent:@"revmobPopupLoaded"];

        }                 andLoadFailHandler:^(RevMobPopup *popup, NSError *error) {

            NSDictionary *errorData = @{
                    @"code": @(error.code),
                    @"message": error.description
            };
            [self raiseEvent:@"popupLoadFailed" withData:errorData];
            [self raiseEvent:@"revmobPopupLoadFailed" withData:errorData];
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorData];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

        }                     onClickHandler:^(RevMobPopup *popup) {

            NSLog(@"Popup Clicked");
            [self raiseEvent:@"popupClicked"];
            [self raiseEvent:@"revmobPopupClicked"];
        }];

    } else {

        self.pendingPopup = command;
    }
}

- (void)showInterstitialAd:(CDVInvokedUrlCommand *)command {

    if (self.sessionStarted) {
        if (self.interstitial == nil) {
            self.interstitial = [[RevMobAds session] fullscreen];
        }
        [self.interstitial loadWithSuccessHandler:^(RevMobFullscreen *fs) {
            [fs showAd];
            [self raiseEvent:@"interstitialLoaded"];
            [self raiseEvent:@"revmobInterstitialLoaded"];
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

        }                      andLoadFailHandler:^(RevMobFullscreen *fs, NSError *error) {
            NSDictionary *errorData = @{
                    @"code": @(error.code),
                    @"message": error.description
            };
            [self raiseEvent:@"popupLoadFailed" withData:errorData];
            [self raiseEvent:@"revmobPopupLoadFailed" withData:errorData];
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorData];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }                          onClickHandler:^() {

            [self raiseEvent:@"interstitialClicked"];
            [self raiseEvent:@"revmobInterstitialClicked"];
        }                          onCloseHandler:^() {

            [self raiseEvent:@"interstitialClosed"];
            [self raiseEvent:@"revmobInterstitialClosed"];
        }];

    } else {

        self.pendingInterstitial = command;
    }
}

- (void)printEnvironmentInformation:(CDVInvokedUrlCommand *)command {

    if (self.sessionStarted) {
        [[RevMobAds session] printEnvironmentInformation];
    }
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)setConnectionTimeout:(CDVInvokedUrlCommand *)command {

    self.timeout = (NSUInteger) [[command argumentAtIndex:0] intValue];
    if (self.sessionStarted) {
        [RevMobAds session].connectionTimeout = self.timeout;
    }
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)showBannerAd:(CDVInvokedUrlCommand *)command {

    if (self.sessionStarted) {
        BOOL claimBannerSpace = [[command argumentAtIndex:1 withDefault:@"YES"] boolValue];
        self.bannerAtTop = [[command argumentAtIndex:0 withDefault:@"NO"] boolValue];

        if (self.bannerView == nil) {
            self.bannerView = [[RevMobAds session] bannerView];
            self.bannerView.hidden = YES;
            [self.containerView insertSubview:self.bannerView belowSubview:self.webView];
        }

        [self.bannerView loadWithSuccessHandler:^(RevMobBannerView *banner) {

            [self updateViewFrames];
            self.bannerView.frame = self.bannerFrame;
            if (claimBannerSpace) {
                self.webView.frame = self.webViewFrame;
            }
            self.bannerView.hidden = NO;
            [self raiseEvent:@"bannerLoaded"];
            [self raiseEvent:@"revmobBannerLoaded"];
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

        }                    andLoadFailHandler:^(RevMobBannerView *banner, NSError *error) {

            NSDictionary *errorData = @{
                    @"code": @(error.code),
                    @"message": error.description
            };
            [self raiseEvent:@"bannerLoadFailed" withData:errorData];
            [self raiseEvent:@"revmobBannerLoadFailed" withData:errorData];
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorData];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

        }                        onClickHandler:^(RevMobBannerView *banner) {

            [self raiseEvent:@"bannerClicked"];
            [self raiseEvent:@"revmobBannerClicked"];
        }];

    } else {

        self.pendingBanner = command;
    }
}

- (void)hideBannerAd:(CDVInvokedUrlCommand *)command {

    BOOL releaseBannerSpace = [[command argumentAtIndex:0 withDefault:@"YES"] boolValue];
    if (releaseBannerSpace) {
        self.webView.frame = self.webView.superview.frame;
    }
    if (self.bannerView != nil) {
        self.bannerView.hidden = YES;
    }
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)claimBannerAdSpace:(CDVInvokedUrlCommand *)command {

    self.bannerAtTop = [[command argumentAtIndex:0 withDefault:@"NO"] boolValue];
    [self updateViewFrames];
    self.webView.frame = self.webViewFrame;
}

- (void)releaseBannerAdSpace:(CDVInvokedUrlCommand *)command {

    self.webView.frame = self.webView.superview.frame;
}

#pragma mark - internal stuff

- (void)deviceOrientationChange:(NSNotification *)notification {

    [self updateViewFrames];

    if (!self.bannerView.isHidden) {
        self.webView.frame = self.webViewFrame;
        self.bannerView.frame = self.bannerFrame;
    }
}

- (void)updateViewFrames {

    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

    if (UIInterfaceOrientationIsPortrait(orientation)) {
        // portrait
        if (self.bannerAtTop) {
            self.bannerFrame = self.bannerFrameTopPortrait;
            self.webViewFrame = self.webViewFrameTopPortrait;
        } else {
            self.bannerFrame = self.bannerFrameBottomPortrait;
            self.webViewFrame = self.webViewFrameBottomPortrait;
        }
    } else {

        // landscape
        if (self.bannerAtTop) {
            self.bannerFrame = self.bannerFrameTopLandscape;
            self.webViewFrame = self.webViewFrameTopLandscape;
        } else {
            self.bannerFrame = self.bannerFrameBottomLandscape;
            self.webViewFrame = self.webViewFrameBottomLandscape;
        }
    }
}
@end
