//
//  Player.m
//  TouchTracker
//
//  Created by Jonathan Taylor on 02/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Player.h"

@implementation Player

@synthesize name;
@synthesize peerID;
@synthesize turnNumber;
@synthesize isLocalPlayer;


- (id) initWithName:(NSString*)callersName andPeerID:(NSString*)callersPeerID andTurnNumber:(int)callersTurnNumber {
    
    self = [super init];
    
    if (self != nil) {
        [self setName:callersName];
        [self setPeerID:callersPeerID];
        [self setTurnNumber:callersTurnNumber];
        [self setIsLocalPlayer:NO];
    }
    
    return self;
}


- (void) dealloc {
    [name release];
    [peerID release];
    [super dealloc];
}


@end
