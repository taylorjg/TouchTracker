//
//  Player.h
//  TouchTracker
//
//  Created by Jonathan Taylor on 02/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Player : NSObject

@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* peerID;
@property (nonatomic, assign) int turnNumber;
@property (nonatomic, assign) BOOL isLocalPlayer;

- (id) initWithName:(NSString*)name andPeerID:(NSString*)peerID andTurnNumber:(int)turnNumber;

@end
