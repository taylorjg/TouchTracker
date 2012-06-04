//
//  TouchDrawView.h
//  TouchTracker
//
//  Created by Jonathan Taylor on 21/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TouchDrawViewDelegate
- (void) didAddLineFrom:(CGPoint)from to:(CGPoint)to;
- (void) didAddLineInProgressWithKey:(NSString*)key from:(CGPoint)from to:(CGPoint)to;
- (void) didUpdateLineInProgressWithKey:(NSString*)key from:(CGPoint)from to:(CGPoint)to;
- (void) didRemoveLineInProgressWithKey:(NSString*)key;
- (void) didClearScreen;
@end

@interface TouchDrawView : UIView
{
}

@property (nonatomic, retain) UIColor* lineColour;
@property (nonatomic, retain) UIColor* remoteLineColour;
@property (nonatomic, assign) BOOL ignoreTouches;
@property (nonatomic, assign) id <TouchDrawViewDelegate> delegate;

- (void) addLineFrom:(CGPoint)from to:(CGPoint)to isRemote:(BOOL)isRemote;
- (void) addLineInProgressWithKey:(id)key from:(CGPoint)from to:(CGPoint)to isRemote:(BOOL)isRemote;
- (void) updateLineInProgressWithKey:(NSString*)key from:(CGPoint)from to:(CGPoint)to;
- (void) removeLineInProgressWithKey:(NSString*)key;
- (void) clearScreen;

@end
