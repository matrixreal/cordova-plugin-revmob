#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>
#import <RevMobAds/RevMobAds.h>
#import <RevMobAds/RevMobAdsDelegate.h>

@interface RevMobPlugin : CDVPlugin

- (void)init:(CDVInvokedUrlCommand *)command;

- (void)startSession:(CDVInvokedUrlCommand *)command;

- (void)openAdLink:(CDVInvokedUrlCommand *)command;

- (void)showPopupAd:(CDVInvokedUrlCommand *)command;

- (void)showBannerAd:(CDVInvokedUrlCommand *)command;

- (void)hideBannerAd:(CDVInvokedUrlCommand *)command;

- (void)showInterstitialAd:(CDVInvokedUrlCommand *)command;

- (void)printEnvironmentInformation:(CDVInvokedUrlCommand *)command;

- (void)setConnectionTimeout:(CDVInvokedUrlCommand *)command;

- (void)enableTestMode:(CDVInvokedUrlCommand *)command;

- (void)disableTestMode:(CDVInvokedUrlCommand *)command;

- (void)claimBannerAdSpace:(CDVInvokedUrlCommand *)command;

- (void)releaseBannerAdSpace:(CDVInvokedUrlCommand *)command;

@property(nonatomic, strong) RevMobBannerView *bannerView;
@property(nonatomic, strong) RevMobFullscreen *interstitial;
@property(nonatomic, assign) RevMobPopup *popupAd;
@property(nonatomic, assign) RevMobAdLink *adLink;
@property(nonatomic, strong) UIView *containerView;
@property(nonatomic) CGRect bannerFrameTopLandscape;
@property(nonatomic) CGRect bannerFrameBottomLandscape;
@property(nonatomic) CGRect webViewFrameTopLandscape;
@property(nonatomic) CGRect webViewFrameBottomLandscape;
@property(nonatomic) CGRect bannerFrameTopPortrait;
@property(nonatomic) CGRect bannerFrameBottomPortrait;
@property(nonatomic) CGRect webViewFrameTopPortrait;
@property(nonatomic) CGRect webViewFrameBottomPortrait;
@property(nonatomic) CGRect webViewFrame;
@property(nonatomic) CGRect bannerFrame;
@property(nonatomic, getter=isBannerAtTop) BOOL bannerAtTop;
@property(nonatomic) BOOL sessionStarted;
@property(nonatomic) RevMobAdsTestingMode testingMode;
@property(nonatomic) NSUInteger timeout;
@property(nonatomic) CDVInvokedUrlCommand *eventCallback;
@property(nonatomic, strong) CDVInvokedUrlCommand *pendingInterstitial;
@property(nonatomic, strong) CDVInvokedUrlCommand *pendingBanner;
@property(nonatomic, strong) CDVInvokedUrlCommand *pendingPopup;
@end