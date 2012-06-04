//
//  TouchDrawView.m
//  TouchTracker
//
//  Created by Jonathan Taylor on 21/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TouchDrawView.h"
#import "Line.h"

@interface TouchDrawView()
{
    NSMutableDictionary* _linesInProgess;
    NSMutableDictionary* _linesInProgessRemote;
    NSMutableArray* _completeLines;
}
@end


@implementation TouchDrawView

@synthesize lineColour;
@synthesize remoteLineColour;
@synthesize ignoreTouches;
@synthesize delegate;

- (id) initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    if (self != nil) {
        
        [self setLineColour:[UIColor redColor]];
        [self setRemoteLineColour:[UIColor redColor]];
        [self setDelegate:nil];
        
        _linesInProgess = [[NSMutableDictionary alloc] init];
        _linesInProgessRemote = [[NSMutableDictionary alloc] init];
        _completeLines = [[NSMutableArray alloc] init];
        
        [self setBackgroundColor:[UIColor whiteColor]];
        [self setMultipleTouchEnabled:YES];
    }
    
    return self;
}


- (void) dealloc {

    [lineColour release];
    [remoteLineColour release];
    
    [_linesInProgess release];
    [_linesInProgessRemote release];
    [_completeLines release];
    
    [super dealloc];
}


- (void) drawRect:(CGRect)rect {
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(c, 10.0f);
    CGContextSetLineCap(c, kCGLineCapRound);
    CGContextSetLineDash(c, 0.0f, NULL, 0);
    
    for (Line* line in _completeLines) {
        [[line colour] set];
        CGContextMoveToPoint(c, [line from].x, [line from].y);
        CGContextAddLineToPoint(c, [line to].x, [line to].y);
        CGContextStrokePath(c);
    }
    
    CGFloat dashLengths[] = { 20.0f, 20.0f };
    size_t numDashLengths =  sizeof(dashLengths) / sizeof(*dashLengths);
    CGContextSetLineDash(c, 0.0f, dashLengths, numDashLengths);
    
    for (NSValue* key in _linesInProgess) {
        Line* line = [_linesInProgess objectForKey:key];
        [[line colour] set];
        CGContextMoveToPoint(c, [line from].x, [line from].y);
        CGContextAddLineToPoint(c, [line to].x, [line to].y);
        CGContextStrokePath(c);
    }
    
    for (NSValue* key in _linesInProgessRemote) {
        Line* line = [_linesInProgessRemote objectForKey:key];
        [[line colour] set];
        CGContextMoveToPoint(c, [line from].x, [line from].y);
        CGContextAddLineToPoint(c, [line to].x, [line to].y);
        CGContextStrokePath(c);
    }
}


- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    
    if (ignoreTouches) {
        return;
    }
    
    for (UITouch* touch in touches) {
        
        if ([touch tapCount] > 1) {
            [self clearScreen];
            [[self delegate] didClearScreen];
            return;
        }
        
        NSValue* key = [NSValue valueWithNonretainedObject:touch];
        
        CGPoint from;
        CGPoint to;
        from = to = [touch locationInView:self];
        
        [self addLineInProgressWithKey:key from:from to:to isRemote:NO];
        [[self delegate] didAddLineInProgressWithKey:[self makeKeyString:touch] from:from to:to];
    }
}


- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    
    if (ignoreTouches) {
        return;
    }
    
    for (UITouch* touch in touches) {
        
        NSValue* key = [NSValue valueWithNonretainedObject:touch];
        Line* line = [_linesInProgess objectForKey:key];
        
        if (line != nil) {
            
            [line setTo:[touch locationInView:self]];
            
            if ([line isReadyForRemoteUpdate]) {
                [[self delegate] didUpdateLineInProgressWithKey:[self makeKeyString:touch] from:[line from] to:[line to]];
            }
        }
    }
    
    [self setNeedsDisplay];
}


- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    
    if (ignoreTouches) {
        return;
    }
    
    [self endTouches:touches];
}


- (void) touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
    
    if (ignoreTouches) {
        return;
    }
    
    [self endTouches:touches];
}


- (void) endTouches:(NSSet*)touches {
    
    for (UITouch* touch in touches) {
        
        NSValue* key = [NSValue valueWithNonretainedObject:touch];
        Line* line = [_linesInProgess objectForKey:key];
        
        if (line != nil) {
            
            [line retain];
            
            [_linesInProgess removeObjectForKey:key];
            [[self delegate] didRemoveLineInProgressWithKey:[self makeKeyString:touch]];
            
            [self addLineFrom:[line from] to:[line to] isRemote:NO];
            [[self delegate] didAddLineFrom:[line from] to:[line to]];
            
            [line release];
        }
    }
    
    [self setNeedsDisplay];
}


- (NSString*) makeKeyString:(UITouch*)touch {
    NSString* keyString = [NSString stringWithFormat:@"%08X", touch];
    return keyString;
}


- (void) addLineFrom:(CGPoint)from to:(CGPoint)to isRemote:(BOOL)isRemote {
    
    Line* line = [[[Line alloc]
                   initFrom:from
                   to:to
                   colour:(isRemote) ? remoteLineColour : lineColour]
                  autorelease];
    [_completeLines addObject:line];
    
    [self setNeedsDisplay];
}


- (void) addLineInProgressWithKey:(id)key from:(CGPoint)from to:(CGPoint)to isRemote:(BOOL)isRemote {
    
    Line* line = [[[Line alloc]
                   initFrom:from
                   to:to
                   colour:(isRemote) ? remoteLineColour : lineColour]
                  autorelease];
    
    if (isRemote) {
        [_linesInProgessRemote setObject:line forKey:key];
    }
    else {
        [_linesInProgess setObject:line forKey:key];
    }
    
    [self setNeedsDisplay];
}


- (void) updateLineInProgressWithKey:(NSString*)key from:(CGPoint)from to:(CGPoint)to {
    
    Line* line = [_linesInProgessRemote objectForKey:key];
    
    if (line != nil) {
        
        [line setFrom:from];
        [line setTo:to];
        
        [self setNeedsDisplay];
    }
}


- (void) removeLineInProgressWithKey:(NSString*)key {
    [_linesInProgessRemote removeObjectForKey:key];
    [self setNeedsDisplay];
}


- (void) clearScreen {
    
    [_completeLines removeAllObjects];
    [_linesInProgess removeAllObjects];
    [_linesInProgessRemote removeAllObjects];
    
    [self setNeedsDisplay];
}

@end
