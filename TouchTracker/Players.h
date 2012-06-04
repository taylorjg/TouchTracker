//
//  Players.h
//  TouchTracker
//
//  Created by Jonathan Taylor on 02/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Player;

@interface Players : NSObject

- (id) initWithPlayers:(NSArray*)players;
- (void) addPlayer:(Player*)player;
- (Player*) getNextPlayer;
- (void) shuffle;
- (void) resetNextPlayer;
- (int) numberOfPlayers;
- (Player*) getPlayerWithTurnNumber:(int)turnNumber;
- (void) clear;

@end
