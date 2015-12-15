//
//  BackgroundTimeRemainingUtility.h
//  NSURLSessionUploadTaskExample
//
//  Created by Bob Dugan on 10/8/15.
//  Copyright © 2015 Bob Dugan. All rights reserved.
//

#ifndef BackgroundTimeRemainingUtility_h
#define BackgroundTimeRemainingUtility_h
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface BackgroundTimeRemainingUtility:NSObject

+(void) NSLog;
+(double) backgroundTimeRemainingDouble;

@property (readonly) double backgroundTimeRemainingDouble;
@property (readonly) NSString *backgroundTimeRemainingString;
@property (readonly) UIApplicationState UIApplicationStateEnum;
@property (readonly) NSString *UIApplicationStateString;

@end
#endif /* BackgroundTimeRemainingUtility_h */
