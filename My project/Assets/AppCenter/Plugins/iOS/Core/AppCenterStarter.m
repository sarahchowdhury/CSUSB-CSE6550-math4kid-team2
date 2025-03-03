#define APPCENTER_UNITY_USE_DISTRIBUTE
#define APPCENTER_UNITY_USE_CRASHES
#define APPCENTER_UNITY_USE_ANALYTICS
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import "AppCenterStarter.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@import AppCenter;

#ifdef APPCENTER_UNITY_USE_CRASHES
@import AppCenterCrashes;
#endif

#ifdef APPCENTER_UNITY_USE_ANALYTICS
@import AppCenterAnalytics;
#endif

#ifdef APPCENTER_UNITY_USE_DISTRIBUTE
@import AppCenterDistribute;
#import "../Distribute/DistributeDelegate.h"
#endif

enum StartupMode {
  APPCENTER,
  ONECOLLECTOR,
  BOTH,
  NONE,
  SKIP
};

@implementation AppCenterStarter

static NSString *const kMSAppSecret = @"24f4de43-0694-4269-ad91-7cd04d72bfba";
static NSString *const kMSTargetToken = @"appcenter-transmission-target-token";
static NSString *const kMSCustomLogUrl = @"custom-log-url";
static NSString *const kMSCustomAllowNetworkRequests = @"YES";
static NSString *const kMSCustomApiUrl = @"custom-api-url";
static NSString *const kMSCustomInstallUrl = @"custom-install-url";
static NSString *const kMSStartTargetKey = @"MSAppCenterStartTargetUnityKey";
static NSString *const kMSStorageSizeKey = @"MSAppCenterMaxStorageSizeUnityKey";
static NSString *const kMSLogUrlKey = @"MSAppCenterLogUrlUnityKey";
static NSString *const kMSAppSecretKey = @"MSAppCenterAppSecretUnityKey";
static NSString *const kMSUpdateTrackKey = @"MSAppCenterUpdateTrackUnityKey";
static NSString *const kMSEnableManualSessionTrackerKey = @"NO";

static const int kMSLogLevel = 0 /*LOG_LEVEL*/;
static const int kMSStartupType = 0 /*STARTUP_TYPE*/;
static const int kMSUpdateTrack = 1;

+ (void)load {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(startAppCenter)
                                               name:UIApplicationDidFinishLaunchingNotification
                                             object:nil];
}

+ (void)startAppCenter {
  NSNumber *startTarget = [[NSUserDefaults standardUserDefaults] objectForKey:kMSStartTargetKey];
  int startTargetValue = startTarget == nil ? kMSStartupType : startTarget.intValue;
  [MSACAppCenter setLogLevel:(MSACLogLevel)kMSLogLevel];
  if (startTargetValue == SKIP) {
    return;
  }

  NSMutableArray<Class> *classes = [[NSMutableArray alloc] init];

  NSNumber *maxStorageSize = [[NSUserDefaults standardUserDefaults] objectForKey:kMSStorageSizeKey];
  if (maxStorageSize != nil) {
    [MSACAppCenter setMaxStorageSize:maxStorageSize
                 completionHandler:^void(BOOL result) {
                   if (!result) {
                     MSACLogWarning(@"MSACAppCenter", @"setMaxStorageSize failed");
                   }
                 }];
  } else {
#ifdef APPCENTER_USE_CUSTOM_MAX_STORAGE_SIZE
    [MSACAppCenter setMaxStorageSize:APPCENTER_MAX_STORAGE_SIZE
                 completionHandler:^void(BOOL result) {
                   if (!result) {
                     MSACLogWarning(@"MSACAppCenter", @"setMaxStorageSize failed");
                   }
                 }];
#endif
  }

#ifdef APPCENTER_UNITY_USE_ANALYTICS
  [classes addObject:MSACAnalytics.class];
#endif

#ifdef APPCENTER_UNITY_USE_DISTRIBUTE

[MSACDistribute setUpdateTrack:(MSACUpdateTrack)kMSUpdateTrack];
  
#ifdef APPCENTER_UNITY_USE_CUSTOM_API_URL
  [MSACDistribute setApiUrl:kMSCustomApiUrl];
#endif // APPCENTER_UNITY_USE_CUSTOM_API_URL

#ifdef APPCENTER_UNITY_USE_CUSTOM_INSTALL_URL
  [MSACDistribute setInstallUrl:kMSCustomInstallUrl];
#endif // APPCENTER_UNITY_USE_CUSTOM_INSTALL_URL

#ifdef APPCENTER_DISTRIBUTE_DISABLE_AUTOMATIC_CHECK_FOR_UPDATE
  [MSACDistribute disableAutomaticCheckForUpdate];
#endif // APPCENTER_DISTRIBUTE_DISABLE_AUTOMATIC_CHECK_FOR_UPDATE

#endif // APPCENTER_UNITY_USE_DISTRIBUTE

  NSString *customLogUrl = [[NSUserDefaults standardUserDefaults] objectForKey:kMSLogUrlKey];
  if (customLogUrl != nil) {
    [MSACAppCenter setLogUrl:customLogUrl];
  } else {
#ifdef APPCENTER_UNITY_USE_CUSTOM_LOG_URL
    [MSACAppCenter setLogUrl:kMSCustomLogUrl];
#endif
  }
  [MSACAppCenter setNetworkRequestsAllowed:[kMSCustomAllowNetworkRequests boolValue]];
  if ([kMSEnableManualSessionTrackerKey boolValue]) {
    [MSACAnalytics enableManualSessionTracker];
  }
  NSString *customAppSecret = [[NSUserDefaults standardUserDefaults] objectForKey:kMSAppSecretKey];
  NSString *customAppSecretValue = customAppSecret == nil ? kMSAppSecret : customAppSecret;
  switch (startTargetValue) {
    case APPCENTER:
      [MSACAppCenter start:customAppSecretValue withServices:classes];
      break;
    case ONECOLLECTOR:
      [MSACAppCenter start:[NSString stringWithFormat:@"target=%@", kMSTargetToken] withServices:classes];
      break;
    case BOTH:
      [MSACAppCenter start:[NSString stringWithFormat:@"appsecret=%@;target=%@", customAppSecretValue, kMSTargetToken] withServices:classes];
      break;
    case NONE:
      [MSACAppCenter startWithServices:classes];
      break;
  }
}

@end
