//
//  TimeoutDisplay.m
//  TouchTracker
//
//  Created by Jonathan Taylor on 05/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TimeoutDisplay.h"

@interface TimeoutDisplay()
{
    NSTimer* _timer;
    int _secondsRemaining;
}

@end

static const int MIN_TIMEOUT = 10;
static const int MAX_TIMEOUT = 10;
static const int GETTING_LOW_THRESHOLD = 5;

@implementation TimeoutDisplay

@synthesize timeoutDisplayDelegate;

#pragma mark -
#pragma mark NSObject overrides

- (void) dealloc {
    NSLog(@"TimeoutDisplay dealloc");
    [self killTimer];
    [super dealloc];
}


#pragma mark -
#pragma mark Public instance methods


- (id) initWithFrame:(CGRect)callersFrame {
    
    self = [super init];
    
    if (self != nil) {
        
        [self setHidden:YES];
        _timer = nil;
        _secondsRemaining = 0;
        
        self.borderColor = [UIColor whiteColor].CGColor;
        self.borderWidth = 2.0f;
        self.cornerRadius = 5.0f;
        self.masksToBounds = YES;
        
        [self setFrame:callersFrame];
    }
    
    return self;
}


- (void) start:(int)seconds {
    
    NSLog(@"start:");
    NSLog(@"seconds: %d", seconds);
    
    if (seconds < MIN_TIMEOUT) {
        seconds = MIN_TIMEOUT;
    }
    
    if (seconds > MAX_TIMEOUT) {
        seconds = MAX_TIMEOUT;
    }
    
    _secondsRemaining = seconds;
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                              target:self
                                            selector:@selector(timerFireMethod:)
                                            userInfo:nil
                                             repeats:YES];
    [_timer retain];

    [self setHidden:NO];
    [self setNeedsDisplay];
}


- (void) stop {
    NSLog(@"stop");
    [self killTimer];
    [self setHidden:YES];
}


#pragma mark -
#pragma mark Private instance methods


- (void) killTimer {
    
    NSLog(@"killTimer");
    
    if (_timer != nil) {
        NSLog(@"Invalidating timer");
        [_timer invalidate];
        [_timer release];
        _timer = nil;
    }
}


- (void) timerFireMethod:(NSTimer*)theTimer {

    NSLog(@"timerFireMethod:");

    // Let it go negative so that we actually see 0 displayed.
    if (--_secondsRemaining < 0) {
        [self setHidden:YES];
        [self killTimer];
        [self raiseDidTimeoutInTimeoutDisplay];
    }
    else {
        [self setNeedsDisplay];
    }
}


- (void) raiseDidTimeoutInTimeoutDisplay {
    
    NSLog(@"raiseDidTimeoutInTimeoutDisplay");
    
    if ([[self timeoutDisplayDelegate] respondsToSelector:@selector(didTimeoutInTimeoutDisplay:)]) {
        [[self timeoutDisplayDelegate] didTimeoutInTimeoutDisplay:self];
    }
}


#pragma mark -
#pragma mark CALayer overrides


- (void) drawInContext:(CGContextRef)theContext {
    
    NSLog(@"TimeoutDisplay drawInContext:");
    
    NSString* label = [NSString stringWithFormat:@"%d", _secondsRemaining];
    
	UIFont* font = [UIFont fontWithName:@"Helvetica" size:20.0f];
	CGSize textSize = [label sizeWithFont:font];
    
	// The height returned by sizeWithFont never seems to be correct.
	// Using the following for the height calculation seems to work better.
	textSize.height = font.capHeight + -font.descender;
    
    CGRect frame = [self frame];
    CGFloat x = (frame.size.width - textSize.width) / 2;
    /*
     * drawAtPoint:withFont: seems to want the point to be at the
     * TOP left corner of where the text is to be drawn (more or less).
     */
    CGFloat y = ((frame.size.height - textSize.height) / 2) - (textSize.height - font.capHeight);
    
    x = roundf(x);
    y = roundf(y);
    
    BOOL isCritical = (_secondsRemaining <= GETTING_LOW_THRESHOLD);
    UIColor* colour = (isCritical) ? [UIColor redColor] : [UIColor whiteColor];
    
	CGContextBeginPath(theContext);
	CGContextSetFillColorWithColor(theContext, colour.CGColor);	
	CGContextSetTextDrawingMode(theContext, kCGTextFill);
	CGAffineTransform flip = CGAffineTransformMake(1, 0, 0, -1, 0, 0);
	CGContextSetTextMatrix(theContext, flip);
    
    UIGraphicsPushContext(theContext);
    [label drawAtPoint:CGPointMake(x, y) withFont:font];
    UIGraphicsPopContext();
    
	CGContextFillPath(theContext);
}


@end
