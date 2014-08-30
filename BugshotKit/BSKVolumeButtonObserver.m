//
//  BSKVolumeButtonObserver.m
//  Bloglovin
//
//  Created by Jared Sinclair on 8/29/14.
//  Copyright (c) 2014 Bloglovin. All rights reserved.
//

#import "BSKVolumeButtonObserver.h"

#import "BugshotKit.h"

static NSString * BSKVolumeObserver_SystemVolumeChangeNotification = @"AVSystemController_SystemVolumeDidChangeNotification";
static NSString * BSKVolumeObserver_SystemVolumeChangeReasonKey = @"AVSystemController_AudioVolumeChangeReasonNotificationParameter";
static NSString * BSKVolumeObserver_SystemVolumeChangeReason_Explicit = @"ExplicitVolumeChange";

@import AVFoundation;
@import MediaPlayer;

typedef BOOL(^BSKVolumeButtonObserverViewHierarchySearchHandler)(UIView *view);

@interface BSKVolumeButtonObserver ()

@property (strong, nonatomic) MPVolumeView *volumeViewForEnablingVolumeNotifications;

@end

@implementation BSKVolumeButtonObserver

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:BSKVolumeObserver_SystemVolumeChangeNotification
                                                  object:nil];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
        _volumeViewForEnablingVolumeNotifications = [[MPVolumeView alloc] initWithFrame:CGRectZero];
        _volumeViewForEnablingVolumeNotifications.alpha = 0;
        _volumeViewForEnablingVolumeNotifications.isAccessibilityElement = NO;
        [[UIApplication sharedApplication].keyWindow addSubview:_volumeViewForEnablingVolumeNotifications];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(volumeChanged:)
                                                     name:BSKVolumeObserver_SystemVolumeChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)volumeChanged:(NSNotification *)notification {
    
    // If app is not active, don't do anything.
    // EARLY RETURN
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        return;
    }
    
    // If the volume change is not an explicit volume change,
    // don't do anything.
    // EARLY RETURN
    NSString *reason = notification.userInfo[BSKVolumeObserver_SystemVolumeChangeReasonKey];
    if (reason != nil && ![reason isEqualToString:BSKVolumeObserver_SystemVolumeChangeReason_Explicit]) {
        return;
    }
    
    // If external audio is playing, don’t do anything.
    // EARLY RETURN
    if ([[AVAudioSession sharedInstance] isOtherAudioPlaying]) {
        if (self.allowBugshotWhenAudioIsPlaying == NO) {
            return;
        }
    }
    
    // If there’s any view in the hierarchy with an “MP” prefix, don’t do anything
    // This is a bit aggressive, it means that even when a movie is paused or stopped, we won’t take over the button
    // But the user can always just tap & hold or use the action button instead.
    // EARLY RETURN
    typeof(self) __weak weakSelf = self;
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIView *moviePlayerView = [self.class firstDescendentOfView:window passingTest:^BOOL(UIView *view) {
        BOOL passes = NO;
        if ([view isDescendantOfView:weakSelf.volumeViewForEnablingVolumeNotifications] == NO) {
            NSString *classString = NSStringFromClass([view class]);
            passes = [classString hasPrefix:@"MP"];
        }
        return passes;
    }];
    if (moviePlayerView && self.allowBugshotWhenVideoIsPlaying == NO) {
        return;
    }
    
    // OKAY, show Bugshot if the volume was changed twice in less than 0.5 seconds.
    static CFTimeInterval lastVolumeChangeInterval = 0.0;
    const CFTimeInterval kFLVolumePressReportBugInterval = 0.5;
    if (CACurrentMediaTime() - lastVolumeChangeInterval < kFLVolumePressReportBugInterval) {
        [BugshotKit show];
    }
    lastVolumeChangeInterval = CACurrentMediaTime();
}

+ (UIView *)firstDescendentOfView:(UIView *)view passingTest:(BOOL (^)(UIView *view))handler {
    
    UIView __block *matchingView = nil;
    
    for (UIView *subview in view.subviews) {
        if (handler(subview)) {
            matchingView = subview;
        } else {
            [self firstDescendentOfView:subview passingTest:^BOOL(UIView *view) {
                BOOL matches = handler(view);
                if (matches) {
                    matchingView = view;
                }
                return matches;
            }];
        }
        if (matchingView) {
            break;
        }
    }
    
    return matchingView;
}

@end




