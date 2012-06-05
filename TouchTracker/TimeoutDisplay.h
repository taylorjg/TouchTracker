//
//  TimeoutDisplay.h
//  TouchTracker
//
//  Created by Jonathan Taylor on 05/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class TimeoutDisplay;

@protocol TimeoutDisplayDelegate <NSObject>
@optional
- (void) didTimeoutInTimeoutDisplay:(TimeoutDisplay*)timeoutDisplay;
@end

@interface TimeoutDisplay : CALayer

@property (nonatomic, assign) id <TimeoutDisplayDelegate> timeoutDisplayDelegate;

- (id) initWithFrame:(CGRect)frame;
- (void) start:(int)seconds;
- (void) stop;

@end
