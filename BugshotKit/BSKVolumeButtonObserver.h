//
//  BSKVolumeButtonObserver.h
//  Bloglovin
//
//  Created by Jared Sinclair on 8/29/14.
//  Copyright (c) 2014 Bloglovin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BSKVolumeButtonObserver : NSObject

+ (UIView *)firstDescendentOfView:(UIView *)view passingTest:(BOOL (^)(UIView *view))handler;

@end
