//
//  TurnBar.h
//  TouchTracker
//
//  Created by Jonathan Taylor on 01/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class TurnBar;
@class Player;

@protocol TurnBarDelegate <NSObject>
@optional
- (void) turnBar:(TurnBar*)turnBar didEndTurnForPlayer:(Player*)player timedOut:(BOOL)timedOut;
@end

@interface TurnBar : CALayer

@property (nonatomic, assign) id <TurnBarDelegate> turnBarDelegate;
@property (nonatomic, retain) Player* currentPlayer;

- (id) initInParentView:(UIView*)parentView;
- (void) show;
- (void) hide;

@end
