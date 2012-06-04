//
//  Line.m
//  TouchTracker
//
//  Created by Jonathan Taylor on 21/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Line.h"

@interface Line()
{
    CGPoint _previousFrom;
    CGPoint _previousTo;
    NSTimeInterval _lastRemoteUpdateTimestamp;
}

@end

@implementation Line

@synthesize from;
@synthesize to;
@synthesize colour;


- (id) initFrom:(CGPoint)callersFrom to:(CGPoint)callersTo colour:(UIColor*)callersColour {

    self = [super init];
    
    if (self != nil) {
        [self setFrom:callersFrom];
        [self setTo:callersTo];
        [self setColour:callersColour];
        _previousFrom = CGPointZero;
        _previousTo = CGPointZero;
        _lastRemoteUpdateTimestamp = CFAbsoluteTimeGetCurrent();
    }
    
    return self;
}


- (void) dealloc {
    NSLog(@"Line dealloc (%p)", self);
    [colour release];
    [super dealloc];
}


- (BOOL) isReadyForRemoteUpdate {
    
    BOOL result = NO;
    
    // Return YES if :-
    // - the "from" or "to" point has moved more than a threshold amount (in the X or Y direction)
    // or
    // - the interval since the last remote update is more than a threshold duration
    
    const static float MOVEMENT_THRESHOLD = 3.0f;
    const static NSTimeInterval TIME_SINCE_LAST_REMOTE_UPDATE_THRESHOLD = 0.2f;
    
    float deltaFromX = fabs([self from].x - _previousFrom.x);
    float deltaFromY = fabs([self from].y - _previousFrom.y);
    float deltaToX = fabs([self to].x - _previousTo.x);
    float deltaToY = fabs([self to].y - _previousTo.y);
    NSTimeInterval deltaRemoteUpdateTimestamp = CFAbsoluteTimeGetCurrent() - _lastRemoteUpdateTimestamp;

    NSLog(@"deltaBeginX: %f; deltaBeginY: %f; deltaEndX: %f; deltaEndY: %f", deltaFromX, deltaFromY, deltaToX, deltaToY);
    NSLog(@"deltaUpdateTimestamp: %f", deltaRemoteUpdateTimestamp);
    
    if (deltaFromX >= MOVEMENT_THRESHOLD ||
        deltaFromY >= MOVEMENT_THRESHOLD ||
        deltaToX >= MOVEMENT_THRESHOLD ||
        deltaToY >= MOVEMENT_THRESHOLD ||
        deltaRemoteUpdateTimestamp >= TIME_SINCE_LAST_REMOTE_UPDATE_THRESHOLD)
    {
        result = YES;
    }
    
    if (result) {
        _previousFrom = [self from];
        _previousTo = [self to];
        _lastRemoteUpdateTimestamp = CFAbsoluteTimeGetCurrent();
    }
    
    return result;
}


@end
