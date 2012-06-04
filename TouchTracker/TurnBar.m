//
//  TurnBar.m
//  TouchTracker
//
//  Created by Jonathan Taylor on 01/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TurnBar.h"
#import "Player.h"

@interface TurnBar()
{
    @private
    UIView* _parentView;
    UIBarButtonItem* _doneButton;
    UIToolbar* _toolbar;
    NSString* _turnText;
    Player* _currentPlayer;
}

@end


@implementation TurnBar

@synthesize turnBarDelegate;

/*
 * For this property, I am using explicit getter/setter methods below.
 * This is because I have extra work to do in the setter.
 * @synthesize currentPlayer;
 */


- (id) initInParentView:(UIView*)parentView {

    self = [super init];
    
    if (self != nil) {
        
        // http://stackoverflow.com/questions/5414631/retina-display-core-graphics-font-quality
        if ([self respondsToSelector:@selector(setContentsScale:)]) {
            [self setContentsScale:[[UIScreen mainScreen] scale]];
        }
        
        _parentView = parentView;
        
        _toolbar = [[UIToolbar alloc] init];
        [_toolbar sizeToFit];
        [_toolbar setHidden:YES];
        [_toolbar setBarStyle:UIBarStyleBlack];
        [_toolbar setTranslucent:NO];
        [_parentView addSubview:_toolbar];
        
        _doneButton = [[UIBarButtonItem alloc]
                       initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                       target:self
                       action:@selector(doneButtonPressed:)];

        [_toolbar setItems:[NSArray arrayWithObjects:_doneButton, nil]];
        
        CGRect parentViewBounds = _parentView.bounds;
        const CGFloat toolbarHeight = [_toolbar frame].size.height;
        
        CGRect rect = CGRectZero;
        rect.origin.x = 0.0f;
        rect.origin.y = parentViewBounds.size.height - toolbarHeight;
        rect.size.width = parentViewBounds.size.width;
        rect.size.height = toolbarHeight;
        
        [self setFrame:rect];
        [[_parentView layer] addSublayer:self];
        [self setHidden:YES];
        [self setNeedsDisplay];
        
        _turnText = nil;
        _currentPlayer = nil;
    }
    
    return self;
}


- (void) dealloc {
    
    [_doneButton release];
    [_toolbar removeFromSuperview];
    [_toolbar release];
    [_turnText release];
    [_currentPlayer release];
    
    [super dealloc];
}


- (void) show {
    
    CGRect parentViewBounds = _parentView.bounds;
    CGPoint centreFrom = CGPointZero;
    CGPoint centreTo = CGPointZero;
    
    const CGFloat toolbarHeight = [_toolbar frame].size.height;
    
    centreFrom.x = parentViewBounds.size.width / 2.0f;
    centreFrom.y = parentViewBounds.size.height + (toolbarHeight / 2.0f);
    
    centreTo.x = parentViewBounds.size.width / 2.0f;
    centreTo.y = parentViewBounds.size.height - (toolbarHeight / 2.0f);
    
    _toolbar.center = centreFrom;
    _toolbar.hidden = NO;
    
    [UIView beginAnimations:@"ShowTurnBar" context:NULL];
    [UIView setAnimationDuration:0.5f];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showTurnBarAnimationDidStop:finished:context:)];
    _toolbar.center = centreTo;
    // TODO: we could reduce the height of the parent view here...
    [UIView commitAnimations];
}


- (void) hide {
    
    CGRect parentViewBounds = _parentView.bounds;
    CGPoint centreFrom = CGPointZero;
    CGPoint centreTo = CGPointZero;
	
    const CGFloat toolbarHeight = [_toolbar frame].size.height;
    
    centreFrom.x = parentViewBounds.size.width / 2.0f;
    centreFrom.y = parentViewBounds.size.height - (toolbarHeight / 2.0f);
    
    centreTo.x = parentViewBounds.size.width / 2.0f;
    centreTo.y = parentViewBounds.size.height + (toolbarHeight / 2.0f) ;
    
    [self setHidden:YES];
    _toolbar.center = centreFrom;
    
    [UIView beginAnimations:@"HideTurnBar" context:NULL];
    [UIView setAnimationDuration:0.5f];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(hideTurnBarAnimationDidStop:finished:context:)];
    _toolbar.center = centreTo;
    // TODO: we could restore the original height of the parent view here...
    [UIView commitAnimations];
}


- (Player*) currentPlayer {
    return _currentPlayer;
}


- (void) setCurrentPlayer:(Player*)callersCurrentPlayer {
    
    [_currentPlayer release];
    _currentPlayer = [callersCurrentPlayer retain];
    
    [_turnText release];
    _turnText = [[NSString stringWithFormat:@"%@%Cs turn", [_currentPlayer name], 0x2019] retain];
    
    [_doneButton setEnabled:[_currentPlayer isLocalPlayer]];
    
    [self setNeedsDisplay];
}


- (void) showTurnBarAnimationDidStop:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {
    NSLog(@"showTurnBarAnimationDidStop:finished:context:");
    [self setHidden:NO];
}


- (void) hideTurnBarAnimationDidStop:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {
    NSLog(@"hideTurnBarAnimationDidStop:finished:context:");
	[_toolbar setHidden:YES];
}


- (void) doneButtonPressed:(id)sender {
    
    NSLog(@"doneButtonPressed:");
    
    if ([[self turnBarDelegate] respondsToSelector:@selector(turnBar:didEndTurnForPlayer:timedOut:)]) {
        [[self turnBarDelegate] turnBar:self didEndTurnForPlayer:[self currentPlayer] timedOut:NO];
    }
}


- (void) drawInContext:(CGContextRef)theContext {
    
    NSLog(@"drawInContext:");
    
    if (_turnText == nil) {
        return;
    }
    
	UIFont* font = [UIFont fontWithName:@"Helvetica" size:20.0f];
	CGSize textSize = [_turnText sizeWithFont:font];
    
	// The height returned by sizeWithFont never seems to be correct.
	// Using the following for the height calculation seems to work better.
	textSize.height = font.capHeight + -font.descender;
    
    CGRect frame = [self frame];
    CGFloat x = (frame.size.width - textSize.width) / 2;
    
    /*
     * CGContextShowTextAtPoint() seems to want the point to be at the
     * BOTTOM left corner of where the text is to be drawn (more or less).
     *
     * CGFloat y = ((frame.size.height - textSize.height) / 2) + font.capHeight;
     */

    /*
     * drawAtPoint:withFont: seems to want the point to be at the
     * TOP left corner of where the text is to be drawn (more or less).
     */
    CGFloat y = ((frame.size.height - textSize.height) / 2) - (textSize.height - font.capHeight);
    
    x = roundf(x);
    y = roundf(y);
    
    UIColor* colour = [UIColor whiteColor];
    
	CGContextBeginPath(theContext);
	CGContextSetFillColorWithColor(theContext, colour.CGColor);	
	CGContextSetTextDrawingMode(theContext, kCGTextFill);
	CGAffineTransform flip = CGAffineTransformMake(1, 0, 0, -1, 0, 0);
	CGContextSetTextMatrix(theContext, flip);
    
    /*
     * I am now using drawAtPoint:withFont: instead of CGContextShowTextAtPoint()
     * because of problems drawing device names containing apostrophes which seem
     * to use a posh Unicode character for the apostrophe instead of a humble
     * single quote. This Unicode character (\U2019) is not handled well by
     * CGContextShowTextAtPoint() - it draws a bunch of odd looking characters.
     *
	 * CGContextSelectFont(theContext, "Helvetica", 20.0f, kCGEncodingMacRoman);
	 * const char* lpszText = [_turnText UTF8String];
	 * CGContextShowTextAtPoint(theContext, x, y, lpszText, strlen(lpszText));
     */
    
    UIGraphicsPushContext(theContext);
    [_turnText drawAtPoint:CGPointMake(x, y) withFont:font];
    UIGraphicsPopContext();
    
	CGContextFillPath(theContext);
}


@end
