#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import <CoreLocation/CoreLocation.h>

@interface NBLocationPermissionHandler : NSObject <CLLocationManagerDelegate>
@property(nonatomic, strong) CLLocationManager *locationManager;
@property(nonatomic, copy) FlutterResult pendingResult;
- (void)ensurePermission:(FlutterResult)result;
@end

@implementation NBLocationPermissionHandler

- (void)ensurePermission:(FlutterResult)result {
  CLAuthorizationStatus status;
  if (@available(iOS 14.0, *)) {
    status = CLLocationManager.authorizationStatus;
  } else {
    status = [CLLocationManager authorizationStatus];
  }

  switch (status) {
  case kCLAuthorizationStatusAuthorizedAlways:
  case kCLAuthorizationStatusAuthorizedWhenInUse:
    result(@YES);
    return;
  case kCLAuthorizationStatusDenied:
  case kCLAuthorizationStatusRestricted:
    result(@NO);
    return;
  case kCLAuthorizationStatusNotDetermined:
    if (self.pendingResult != nil) {
      result([FlutterError errorWithCode:@"permission_request_in_progress"
                                 message:@"A location permission request is already in progress."
                                 details:nil]);
      return;
    }
    if (![CLLocationManager locationServicesEnabled]) {
      result(@NO);
      return;
    }
    self.pendingResult = result;
    if (self.locationManager == nil) {
      self.locationManager = [[CLLocationManager alloc] init];
      self.locationManager.delegate = self;
    }
    [self.locationManager requestWhenInUseAuthorization];
    return;
  }
}

- (void)completeWithStatus:(CLAuthorizationStatus)status {
  if (self.pendingResult == nil) {
    return;
  }

  BOOL granted = status == kCLAuthorizationStatusAuthorizedAlways ||
                 status == kCLAuthorizationStatusAuthorizedWhenInUse;
  self.pendingResult(@(granted));
  self.pendingResult = nil;
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager API_AVAILABLE(ios(14.0)) {
  [self completeWithStatus:manager.authorizationStatus];
}

- (void)locationManager:(CLLocationManager *)manager
    didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
  [self completeWithStatus:status];
}

@end

@interface AppDelegate ()
@property(nonatomic, strong) NBLocationPermissionHandler *permissionHandler;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];

  FlutterViewController *controller = (FlutterViewController *)self.window.rootViewController;
  FlutterMethodChannel *permissionsChannel = [FlutterMethodChannel
      methodChannelWithName:@"nb_maps_flutter_example/permissions"
            binaryMessenger:controller.binaryMessenger];
  self.permissionHandler = [[NBLocationPermissionHandler alloc] init];
  [permissionsChannel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
    if ([@"ensureLocationPermission" isEqualToString:call.method]) {
      [self.permissionHandler ensurePermission:result];
    } else {
      result(FlutterMethodNotImplemented);
    }
  }];

  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
