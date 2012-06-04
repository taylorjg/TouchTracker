//
//  Players.m
//  TouchTracker
//
//  Created by Jonathan Taylor on 02/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Players.h"
#import "Player.h"

@interface Players()
{
    @private
    NSMutableArray* _players;
    int _nextTurnNumber;
}

@end


@implementation Players


#pragma mark -
#pragma mark NSObject overrides


- (id) init {
    
    self = [super init];
    
    if (self != nil) {
        _players = [[NSMutableArray alloc] init];
        _nextTurnNumber = 0;
    }
    
    return self;
}


- (void) dealloc {
    [_players release];
    [super dealloc];
}


#pragma mark -
#pragma mark Public instance methods


- (id) initWithPlayers:(NSArray*)players {
    
    self = [super init];
    
    if (self != nil) {
        _players = [[NSMutableArray alloc] initWithArray:players];
        _nextTurnNumber = 1;
    }
    
    return self;
}


- (void) addPlayer:(Player*)player {
    [_players addObject:player];
}


- (Player*) getNextPlayer {
    Player* nextPlayer = [self getPlayerWithTurnNumber:_nextTurnNumber];
    [self bumpNextPlayer];
    return nextPlayer;
}


- (void) shuffle {
    
    for (Player* player in _players) {
        [player setTurnNumber:0];
    }
    
    NSMutableArray* turnNumbersAlreadyUsed = [[[NSMutableArray alloc] init] autorelease];
    
    for (Player* player in _players) {
        
        int randomTurnNumber;
        
        for (;;) {
            
            randomTurnNumber = [self getRandomTurnNumber];
            
            /*
             * indexOfObjectPassingTest: requires iOS 4.0 or later.
             * NSUInteger index = [turnNumbersAlreadyUsed indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL* stop) {
             *     NSNumber* number = (NSNumber*)obj;
             *     return ([number intValue] == randomTurnNumber);
             * }];
             */
            
            NSUInteger index = NSNotFound;
            int i = 0;
            for (NSNumber* number in turnNumbersAlreadyUsed) {
                if ([number intValue] == randomTurnNumber) {
                    index = i;
                    break;
                }
                i++;
            }
            
            if (index == NSNotFound) {
                [turnNumbersAlreadyUsed addObject:[NSNumber numberWithInt:randomTurnNumber]];
                break;
            }
        }
        
        NSAssert([self getPlayerWithTurnNumber:randomTurnNumber] == nil, @"A player already has this turn number!");
        
        [player setTurnNumber:randomTurnNumber];
    }
    
	[self resetNextPlayer];
}


- (void) resetNextPlayer {
	_nextTurnNumber = 1;
}


- (int) numberOfPlayers {
    return [_players count];
}


- (Player*) getPlayerWithTurnNumber:(int)turnNumber {
    
    Player* result = nil;
    
    for (Player* player in _players) {
        if ([player turnNumber] == turnNumber) {
            result = player;
            break;
        }
    }
    
    return result;
}


- (void) clear {
    [_players removeAllObjects];
    _nextTurnNumber = 0;
}


#pragma mark -
#pragma mark Private instance methods


- (int) getRandomTurnNumber {
    int numberOfPlayers = [self numberOfPlayers];
    int randomTurnNumber = (arc4random() % numberOfPlayers) + 1;
    return randomTurnNumber;
}


- (void) bumpNextPlayer {
    
    _nextTurnNumber++;
    
    if (_nextTurnNumber > [self numberOfPlayers]) {
        _nextTurnNumber = 1;
    }
}


@end
