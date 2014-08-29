//
//  BSKVolumeButtonObserver.m
//  Bloglovin
//
//  Created by Jared Sinclair on 8/29/14.
//  Copyright (c) 2014 Bloglovin. All rights reserved.
//

#import "BSKVolumeButtonObserver.h"

#import "BugshotKit.h"

static void * BSKVolumeButtonObserverContext = "BSKVolumeButtonObserverContext";
static NSString * BSKVolumeButtonObserver_AudioSession_OutputVolumeKeyPath = @"outputVolume";

@import AVFoundation;

typedef BOOL(^BSKVolumeButtonObserverViewHierarchySearchHandler)(UIView *view);

@implementation BSKVolumeButtonObserver

- (void)dealloc {
    [self removeObservationsFrom:[AVAudioSession sharedInstance]];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        [self addObservationsTo:[AVAudioSession sharedInstance]];
    }
    return self;
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

#pragma mark - KVO

- (void)addObservationsTo:(NSObject *)object {
    [object addObserver:self forKeyPath:BSKVolumeButtonObserver_AudioSession_OutputVolumeKeyPath options:NSKeyValueObservingOptionNew context:BSKVolumeButtonObserverContext];
}

- (void)removeObservationsFrom:(NSObject *)object {
    [object removeObserver:self forKeyPath:BSKVolumeButtonObserver_AudioSession_OutputVolumeKeyPath context:BSKVolumeButtonObserverContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == BSKVolumeButtonObserverContext) {
        if (object == [AVAudioSession sharedInstance]) {
            if ([keyPath isEqualToString:BSKVolumeButtonObserver_AudioSession_OutputVolumeKeyPath]) {
                // If external audio is playing, don’t do anything.
                if ([[AVAudioSession sharedInstance] isOtherAudioPlaying]) {
                    return;
                }
                
                // If there’s any view in the hierarchy with an “MP” prefix, don’t do anything
                // This is a bit aggressive, it means that even when a movie is paused or stopped, we won’t take over the button
                // But the user can always just tap & hold or use the action button instead.
                UIWindow *window = [UIApplication sharedApplication].keyWindow;
                UIView *moviePlayerView = [self.class firstDescendentOfView:window passingTest:^BOOL(UIView *view) {
                    NSString *classString = NSStringFromClass([view class]);
                    return [classString hasPrefix:@"MP"];
                }];
                if (moviePlayerView) {
                    return;
                }
                
                static CFTimeInterval lastVolumeChangeInterval = 0.0;
                const CFTimeInterval kFLVolumePressReportBugInterval = 0.5;
                if (CACurrentMediaTime() - lastVolumeChangeInterval < kFLVolumePressReportBugInterval) {
                    [BugshotKit show];
                }
                lastVolumeChangeInterval = CACurrentMediaTime();
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end




