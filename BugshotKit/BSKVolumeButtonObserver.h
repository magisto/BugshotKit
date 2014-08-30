//
//  BSKVolumeButtonObserver.h
//  Bloglovin
//
//  Created by Jared Sinclair on 8/29/14.
//  Copyright (c) 2014 Bloglovin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BSKVolumeButtonObserver : NSObject

/**
 Defaults to NO.
 */
@property (assign, nonatomic) BOOL allowBugshotWhenAudioIsPlaying;

/**
 Defaults to NO.
 */
@property (assign, nonatomic) BOOL allowBugshotWhenVideoIsPlaying;

@end
