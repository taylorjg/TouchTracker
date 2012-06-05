//
//  TouchViewController.m
//  TouchTracker
//
//  Created by Jonathan Taylor on 21/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TouchViewController.h"
#import "stdlib.h"
#import "TurnBar.h"
#import "Players.h"
#import "Player.h"

/*
 * BUG FIXES TO MAKE:
 *
 * Sometimes, after establishing a connection, the turnbar doesn't appear.
 * - need to capture logs from both devices to investigate further
 *
 * TODO:
 * 
 * Add a nice table view to pick the colour
 * - add nice styling to the table
 * - e.g. set the background colour of the cell to the corresponding colour, rounded borders, etc.
 * - get ideas form the "Pro iOS Table Views" book
 * http://www.apress.com/9781430233480
 * - also, use this table to set the turn timeout ?
 *
 * Use peer picker or do our own automatic session connection establishment based on a #define
 *
 * Move the networking code into a separate module
 *
 */

@interface TouchViewController() <GKSessionDelegate>
{
    UIBarButtonItem* _paletteBarButtonItem;
    UIBarButtonItem* _networkBarButtonItem;
    UIBarButtonItem* _disconnectBarButtonItem;
    GKSession* _gkSession;
    NSMutableArray* _connectingToPeerIDs;
    NSMutableArray* _randomHostNumbers;
    int _ourRandomHostNumber;
    BOOL _haveDecidedHost;
    BOOL _weAreHost;
    BOOL _networkGameInProgress;
    TurnBar* _turnBar;
    Players* _players;
}
@end


@implementation TouchViewController


#pragma mark -
#pragma mark NSObject overrides


- (id) init {
    
    self = [super init];
    
    if (self != nil) {
        _paletteBarButtonItem = nil;
        _networkBarButtonItem = nil;
        _disconnectBarButtonItem = nil;
        _gkSession = nil;
        _connectingToPeerIDs = [[NSMutableArray alloc] init];
        _randomHostNumbers = [[NSMutableArray alloc] init];
        _ourRandomHostNumber = -1;
        _haveDecidedHost = NO;
        _weAreHost = NO;
        _networkGameInProgress = NO;
        _turnBar = nil;
        _players = [[Players alloc] init];
    }
    
    return self;
}


- (void) dealloc {
    
    NSLog(@"TouchViewController dealloc");
    
    [self disconnectSendingGoodbyePacket:NO];

    [_paletteBarButtonItem release];
    [_networkBarButtonItem release];
    [_disconnectBarButtonItem release];
    
    [_gkSession release];
    [_connectingToPeerIDs release];
    [_randomHostNumbers release];
    
    [_turnBar release];
    [_players release];
    
    [super dealloc];
}


#pragma mark -
#pragma mark UIViewController overrides


- (void) loadView {
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;

    CGRect viewBounds = CGRectZero;
    viewBounds.origin.x = 0.0f;
    viewBounds.origin.y = 20.0f;
    viewBounds.size.width = screenBounds.size.width;
    viewBounds.size.height = screenBounds.size.height - 20.0f;
    
    self.view = [[[TouchDrawView alloc] initWithFrame:viewBounds] autorelease];

    CGRect toolbarFrame = CGRectZero;
    toolbarFrame.size.width = screenBounds.size.width;
    toolbarFrame.size.height = 44.0f;
    
    _paletteBarButtonItem = [[UIBarButtonItem alloc] init];
	_paletteBarButtonItem.title = @"Colours";
	_paletteBarButtonItem.image = [UIImage imageNamed:@"98-palette.png"];
    _paletteBarButtonItem.enabled = YES;
	_paletteBarButtonItem.target = self;
	_paletteBarButtonItem.action = @selector(paletteBarButtonItemPressed:);
    
    _networkBarButtonItem = [[UIBarButtonItem alloc] init];
	_networkBarButtonItem.title = @"Network";
	_networkBarButtonItem.image = [UIImage imageNamed:@"58-wifi.png"];
    _networkBarButtonItem.enabled = YES;
	_networkBarButtonItem.target = self;
	_networkBarButtonItem.action = @selector(networkBarButtonItemPressed:);
    
    _disconnectBarButtonItem = [[UIBarButtonItem alloc] init];
	_disconnectBarButtonItem.title = @"Disconnect";
	_disconnectBarButtonItem.image = [UIImage imageNamed:@"37-circle-x.png"];
    _disconnectBarButtonItem.enabled = NO;
	_disconnectBarButtonItem.target = self;
	_disconnectBarButtonItem.action = @selector(disconnectBarButtonItemPressed:);
    
	NSArray* toolbarItems = [NSArray arrayWithObjects:
                             _paletteBarButtonItem,
							 _networkBarButtonItem,
                             _disconnectBarButtonItem,
                             nil];
    
    UIToolbar* toolbar = [[[UIToolbar alloc] initWithFrame:toolbarFrame] autorelease];
	[toolbar setBarStyle:UIBarStyleBlack];
	[toolbar setTranslucent:NO];
	[toolbar setItems:toolbarItems];
    
    [[self view] addSubview:toolbar];
    [(TouchDrawView*)[self view] setDelegate:self];
    
    _turnBar = [[TurnBar alloc] initInParentView:[self view]];
    [_turnBar setTurnBarDelegate:self];
}


#pragma mark -
#pragma mark Toolbar actions


- (IBAction) paletteBarButtonItemPressed:(id)sender {
    
    NSLog(@"paletteBarButtonItemPressed:");
    NSLog(@"sender: %@", sender);
    
    UIActionSheet* actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"Choose a colour"
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:@"Red", @"Green", @"Blue", @"Yellow", nil];
    
    BOOL runningOnPad = NO;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		runningOnPad = YES;
	}
#endif
    
    if (runningOnPad) {
        [actionSheet showFromBarButtonItem:sender animated:YES];
    }
    else {
        [actionSheet showInView:self.view];
    }
    
    [actionSheet release];
}


- (IBAction) networkBarButtonItemPressed:(id)sender {
    
    NSLog(@"networkBarButtonItemPressed:");
    NSLog(@"sender: %@", sender);

    _networkBarButtonItem.enabled = NO;
    
    GKPeerPickerController* picker = [[GKPeerPickerController alloc] init];
    [picker setConnectionTypesMask:GKPeerPickerConnectionTypeNearby];
    [picker setDelegate:self];
    [picker show];
    
    /*
     * _gkSession = [[GKSession alloc] initWithSessionID:@"com.jt.continuo" displayName:nil sessionMode:GKSessionModePeer];
     * [_gkSession setDelegate:self];
     * [_gkSession setDataReceiveHandler:self withContext:NULL];
     * [_gkSession setAvailable:YES];
     */
}


- (IBAction) disconnectBarButtonItemPressed:(id)sender {
    
    NSLog(@"disconnectBarButtonItemPressed:");
    NSLog(@"sender: %@", sender);
    
    [self disconnectSendingGoodbyePacket:YES];
}


#pragma mark -
#pragma mark UIActionSheetDelegate


- (void) actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {

    NSLog(@"actionSheet:didDismissWithButtonIndex:");
    NSLog(@"buttonIndex: %d", buttonIndex);
    
    UIColor* chosenColour = nil;
    
    switch (buttonIndex) {
            
        case 0:
            chosenColour = [UIColor redColor];
            break;
            
        case 1:
            chosenColour = [UIColor greenColor];
            break;
            
        case 2:
            chosenColour = [UIColor blueColor];
            break;
            
        case 3:
            chosenColour = [UIColor yellowColor];
            break;
    }
    
    if (chosenColour != nil) {
        
        [(TouchDrawView*)self.view setLineColour:chosenColour];
        
        if (_networkGameInProgress) {
            [self sendLineColourPacket:chosenColour];
        }
    }
}


#pragma mark -
#pragma mark Private methods


- (void) didConnect {
    
    NSLog(@"didConnect");
    
    [_disconnectBarButtonItem setEnabled:YES];
    
    _networkGameInProgress = YES;
    _haveDecidedHost = NO;
    _weAreHost = NO;
    [(TouchDrawView*)[self view] setIgnoreTouches:YES];
    
    [self sendDecideHostPacket];
    
    UIColor* lineColour = [(TouchDrawView*)[self view] lineColour];
    [self sendLineColourPacket:lineColour];
}


- (void) didDisconnect {
    
    NSLog(@"didDisconnect");
    
    [_randomHostNumbers removeAllObjects];
    [_networkBarButtonItem setEnabled:YES];
    [_disconnectBarButtonItem setEnabled:NO];
    
    _networkGameInProgress = NO;
    _haveDecidedHost = NO;
    _weAreHost = NO;
    [(TouchDrawView*)[self view] setIgnoreTouches:NO];
    
    [_turnBar hide];
    [_players clear];
}


- (void) didDecideHost:(BOOL)weAreHost {
    
    NSLog(@"didDecideHost:");
    
    _haveDecidedHost = YES;
    _weAreHost = weAreHost;
    [(TouchDrawView*)[self view] setIgnoreTouches:NO];
    
    [_turnBar show];
    
    if (_weAreHost) {
        
        [_players clear];
        
        NSString* localName = [_gkSession displayName];
        NSString* localPeerID = [_gkSession peerID];
        Player* localPlayer = [[[Player alloc] initWithName:localName andPeerID:localPeerID andTurnNumber:0] autorelease];
        [localPlayer setIsLocalPlayer:YES];
        [_players addPlayer:localPlayer];
        
        NSArray* connectedPeers = [_gkSession peersWithConnectionState:GKPeerStateConnected];
        for (NSString* peerID in connectedPeers) {
            NSString* name = [_gkSession displayNameForPeer:peerID];
            Player* player = [[[Player alloc] initWithName:name andPeerID:peerID andTurnNumber:0] autorelease];
            [_players addPlayer:player];
        }

        [_players shuffle];
        [self sendPlayersPacket:_players];

        [self changeTurn];
    }
}


- (void) changeTurn {
    
    NSLog(@"changeTurn");
    
    Player* nextPlayer = [_players getNextPlayer];
    
    [self didChangeTurnToPlayer:nextPlayer];
    
    // Let all the other clients know whose turn it is next.
    [self sendChangeTurnPacket:[nextPlayer turnNumber]];
}


- (void) respondToRemoteTurnChange:(int)newTurnNumber {
    
    NSLog(@"respondToRemoteTurnChange:");
    NSLog(@"newTurnNumber: %d", newTurnNumber);
    
    Player* nextPlayer = [_players getNextPlayer];
    NSAssert([nextPlayer turnNumber] == newTurnNumber, @"Turn number is out of sync!");

    [self didChangeTurnToPlayer:nextPlayer];
}


- (void) didChangeTurnToPlayer:(Player*)currentPlayer
{
    NSLog(@"didChangeTurnToPlayer:");
    
    // Update our turnbar.
    [_turnBar setCurrentPlayer:currentPlayer];
    
    // Ignore touches in the main drawing view unless it is our turn.
    [(TouchDrawView*)[self view] setIgnoreTouches:[currentPlayer isLocalPlayer] == NO];
}


- (void) disconnectSendingGoodbyePacket:(BOOL)sendGoodbyePacket {

    NSLog(@"disconnectWithGoodbyePacket:");
    
    if (_networkGameInProgress) {
        
        if (sendGoodbyePacket) {
            [self sendGoodbyePacket];
        }

        // We set this flag to NO before disconnecting.
        // This flag is checked by receiveData:fromPeer:inSession:context:
        // and if set to NO then any received data will be ignored.
        _networkGameInProgress = NO;
        
        [_gkSession setDelegate:nil];
        [_gkSession setDataReceiveHandler:nil withContext:NULL];
        [_gkSession disconnectFromAllPeers];
        [_gkSession release];
        _gkSession = nil;

        [self didDisconnect];
    }
}


- (void) displayError:(NSError*)error withTitle:(NSString*)title {

    UIAlertView* alertView = [[UIAlertView alloc]
                              initWithTitle:title
                              message:[error localizedDescription]
                              delegate:nil
                              cancelButtonTitle:@"Dismiss"
                              otherButtonTitles:nil];
    
    [alertView show];
    [alertView release];
}


#pragma mark -
#pragma mark TouchDrawViewDelegate


- (void) didAddLineFrom:(CGPoint)from to:(CGPoint)to {
    
    NSLog(@"didAddLineFrom:to:");
    
    if (_networkGameInProgress) {
        [self sendAddLinePacketFrom:from to:to];
    }
}


- (void) didAddLineInProgressWithKey:(NSString*)key from:(CGPoint)from to:(CGPoint)to {
    
    NSLog(@"didAddLineInProgressWithKey:from:to:");
    
    if (_networkGameInProgress) {
        [self sendAddLineInProgressPacketWithKey:key from:from to:to];
    }
}


- (void) didUpdateLineInProgressWithKey:(NSString*)key from:(CGPoint)from to:(CGPoint)to {
    
    NSLog(@"didUpdateLineInProgressWithKey:from:to:");
    
    if (_networkGameInProgress) {
        [self sendUpdateLineInProgressPacketWithKey:key from:from to:to];
    }
}


- (void) didRemoveLineInProgressWithKey:(NSString*)key {
    
    NSLog(@"didRemoveLineInProgressWithKey:");
    
    if (_networkGameInProgress) {
        [self sendRemoveLineInProgressPacketWithKey:key];
    }
}


- (void) didClearScreen {
    
    NSLog(@"didClearScreen");
    
    if (_networkGameInProgress) {
        [self sendClearScreenPacket];
    }
}


#pragma mark -
#pragma mark TurnBarDelegate


- (void) turnBar:(TurnBar*)turnBar didEndTurnForPlayer:(Player*)player timedOut:(BOOL)timedOut {
    
    NSLog(@"turnBar:didEndTurnForPlayer:timedOut:");
    NSLog(@"timedOut: %@", timedOut ? @"YES" : @"NO");

    [self changeTurn];
}


#pragma mark -
#pragma mark Network packet definitions


// Enum of network packet types
typedef enum {
    JTPacketTypeGoodbye,
    JTPacketTypeDecideHost,
    JTPacketTypeAddLine,
    JTPacketTypeAddLineInProgress,
    JTPacketTypeUpdateLineInProgress,
    JTPacketTypeRemoveLineInProgress,
    JTPacketTypeClearScreen,
    JTPacketTypeLineColour,
    JTPacketTypePlayers,
    JTPacketTypeChangeTurn
} JTPacketType;


// Common field names
static NSString* const JTFieldNamePacketType = @"PacketType";

// Additional field names in the DecideHost packet
static NSString* const JTFieldNameRandomHostNumber = @"RandomHostNumber";

// Additional field names in the AddLine, AddLineInProgress and UpdateLineInProgress packets
static NSString* const JTFieldNameFromX = @"FromX";
static NSString* const JTFieldNameFromY = @"FromY";
static NSString* const JTFieldNameToX = @"ToX";
static NSString* const JTFieldNameToY = @"ToY";

// Additional field names in the AddLineInProgress, UpdateLineInProgress and RemoveLineInProgress packets
static NSString* const JTFieldNameInProgressLineKey = @"InProgressLineKey";

// Additional field names in the LineColour packet
static NSString* const JTFieldNameRed = @"Red";
static NSString* const JTFieldNameGreen = @"Green";
static NSString* const JTFieldNameBlue = @"Blue";

// Additional field names in the Players packet
static NSString* const JTFieldNameNumPlayers = @"NumPlayers";
static NSString* const JTFieldNamePlayerXName = @"Player%dName";
static NSString* const JTFieldNamePlayerXPeerID = @"Player%dPeerID";

// Additional field names in the ChangeTurn packet
static NSString* const JTFieldNameTurnNumber = @"TurnNumber";

#pragma mark -
#pragma mark Network packet senders


- (void) sendGoodbyePacket {
    
    NSLog(@"sendGoodbyePacket");
    
    NSMutableDictionary* dictionary = [[[NSMutableDictionary alloc] init] autorelease];
    [dictionary setValue:[NSNumber numberWithInt:JTPacketTypeGoodbye] forKey:JTFieldNamePacketType];
    
    [self sendDictionaryToAllPeers:dictionary withDataMode:GKSendDataReliable];
}


- (void) sendDecideHostPacket {
    
    NSLog(@"sendDecideHostPacket");
    
    _ourRandomHostNumber = arc4random() % 100;
    [_randomHostNumbers removeAllObjects];
    _weAreHost = NO;
        
    NSMutableDictionary* dictionary = [[[NSMutableDictionary alloc] init] autorelease];
    [dictionary setValue:[NSNumber numberWithInt:JTPacketTypeDecideHost] forKey:JTFieldNamePacketType];
    [dictionary setValue:[NSNumber numberWithInt:_ourRandomHostNumber] forKey:JTFieldNameRandomHostNumber];
    
    [self sendDictionaryToAllPeers:dictionary withDataMode:GKSendDataReliable];
}


- (void) sendAddLinePacketFrom:(CGPoint)from to:(CGPoint)to {
    
    NSLog(@"sendAddLinePacketFrom:to:");
    
    NSMutableDictionary* dictionary = [[[NSMutableDictionary alloc] init] autorelease];
    [dictionary setValue:[NSNumber numberWithInt:JTPacketTypeAddLine] forKey:JTFieldNamePacketType];
    [dictionary setValue:[NSNumber numberWithFloat:from.x] forKey:JTFieldNameFromX];
    [dictionary setValue:[NSNumber numberWithFloat:from.y] forKey:JTFieldNameFromY];
    [dictionary setValue:[NSNumber numberWithFloat:to.x] forKey:JTFieldNameToX];
    [dictionary setValue:[NSNumber numberWithFloat:to.y] forKey:JTFieldNameToY];
    
    [self sendDictionaryToAllPeers:dictionary withDataMode:GKSendDataReliable];
}


- (void) sendAddLineInProgressPacketWithKey:(NSString*)key from:(CGPoint)from to:(CGPoint)to {
    
    NSLog(@"sendAddLineInProgressPacketWithKey:from:to:");
    
    NSMutableDictionary* dictionary = [[[NSMutableDictionary alloc] init] autorelease];
    [dictionary setValue:[NSNumber numberWithInt:JTPacketTypeAddLineInProgress] forKey:JTFieldNamePacketType];
    [dictionary setValue:key forKey:JTFieldNameInProgressLineKey];
    [dictionary setValue:[NSNumber numberWithFloat:from.x] forKey:JTFieldNameFromX];
    [dictionary setValue:[NSNumber numberWithFloat:from.y] forKey:JTFieldNameFromY];
    [dictionary setValue:[NSNumber numberWithFloat:to.x] forKey:JTFieldNameToX];
    [dictionary setValue:[NSNumber numberWithFloat:to.y] forKey:JTFieldNameToY];
    
    [self sendDictionaryToAllPeers:dictionary withDataMode:GKSendDataReliable];
}


- (void) sendUpdateLineInProgressPacketWithKey:(NSString*)key from:(CGPoint)from to:(CGPoint)to {
    
    NSLog(@"sendUpdateLineInProgressPacketWithKey:from:to:");
    
    NSMutableDictionary* dictionary = [[[NSMutableDictionary alloc] init] autorelease];
    [dictionary setValue:[NSNumber numberWithInt:JTPacketTypeUpdateLineInProgress] forKey:JTFieldNamePacketType];
    [dictionary setValue:key forKey:JTFieldNameInProgressLineKey];
    [dictionary setValue:[NSNumber numberWithFloat:from.x] forKey:JTFieldNameFromX];
    [dictionary setValue:[NSNumber numberWithFloat:from.y] forKey:JTFieldNameFromY];
    [dictionary setValue:[NSNumber numberWithFloat:to.x] forKey:JTFieldNameToX];
    [dictionary setValue:[NSNumber numberWithFloat:to.y] forKey:JTFieldNameToY];
    
    [self sendDictionaryToAllPeers:dictionary withDataMode:GKSendDataUnreliable];
}


- (void) sendRemoveLineInProgressPacketWithKey:(NSString*)key {
    
    NSLog(@"sendRemoveLineInProgressPacketWithKey:");
    
    NSMutableDictionary* dictionary = [[[NSMutableDictionary alloc] init] autorelease];
    [dictionary setValue:[NSNumber numberWithInt:JTPacketTypeRemoveLineInProgress] forKey:JTFieldNamePacketType];
    [dictionary setValue:key forKey:JTFieldNameInProgressLineKey];
    
    [self sendDictionaryToAllPeers:dictionary withDataMode:GKSendDataReliable];
}


- (void) sendClearScreenPacket {
    
    NSLog(@"sendClearScreenPacket");
    
    NSMutableDictionary* dictionary = [[[NSMutableDictionary alloc] init] autorelease];
    [dictionary setValue:[NSNumber numberWithInt:JTPacketTypeClearScreen] forKey:JTFieldNamePacketType];
    
    [self sendDictionaryToAllPeers:dictionary withDataMode:GKSendDataReliable];
}


- (void) sendLineColourPacket:(UIColor*)lineColour {
    
    NSLog(@"sendLineColourPacket:");
    
    CGFloat red = 0.0f;
    CGFloat green = 0.0f;
    CGFloat blue = 0.0f;
    // CGFloat alpha = 0.0f;
    
    // getRed:green:blue:alpha requires iOS 5.0 or later.
    // [lineColour getRed:&red green:&green blue:&blue alpha:&alpha];

    CGColorRef cgLineColour = lineColour.CGColor;
    size_t numberOfComponents = CGColorGetNumberOfComponents(cgLineColour);
    NSAssert(numberOfComponents == 4, @"numberOfComponents == 4");
    const CGFloat* colourComponents = CGColorGetComponents(cgLineColour);
    red = colourComponents[0];
    green = colourComponents[1];
    blue = colourComponents[2];
    
    NSMutableDictionary* dictionary = [[[NSMutableDictionary alloc] init] autorelease];
    [dictionary setValue:[NSNumber numberWithInt:JTPacketTypeLineColour] forKey:JTFieldNamePacketType];
    [dictionary setValue:[NSNumber numberWithFloat:red] forKey:JTFieldNameRed];
    [dictionary setValue:[NSNumber numberWithFloat:green] forKey:JTFieldNameGreen];
    [dictionary setValue:[NSNumber numberWithFloat:blue] forKey:JTFieldNameBlue];
    
    [self sendDictionaryToAllPeers:dictionary withDataMode:GKSendDataReliable];
}


- (void) sendPlayersPacket:(Players*)players {
    
    NSLog(@"sendPlayersPacket:");
    
    NSMutableDictionary* dictionary = [[[NSMutableDictionary alloc] init] autorelease];
    [dictionary setValue:[NSNumber numberWithInt:JTPacketTypePlayers] forKey:JTFieldNamePacketType];
    [dictionary setValue:[NSNumber numberWithInt:[players numberOfPlayers]] forKey:JTFieldNameNumPlayers];
    
    for (int turnNumber = 1; turnNumber <= [players numberOfPlayers]; turnNumber++) {
        Player* player = [players getPlayerWithTurnNumber:turnNumber];
        NSString* fieldNameForName = [NSString stringWithFormat:JTFieldNamePlayerXName, turnNumber];
        NSString* fieldNameForPeerID = [NSString stringWithFormat:JTFieldNamePlayerXPeerID, turnNumber];
        [dictionary setValue:[player name] forKey:fieldNameForName];
        [dictionary setValue:[player peerID] forKey:fieldNameForPeerID];
    }
    
    [self sendDictionaryToAllPeers:dictionary withDataMode:GKSendDataReliable];
}


- (void) sendChangeTurnPacket:(int)turnNumber {
    
    NSLog(@"sendChangeTurnPacket:");
    
    NSMutableDictionary* dictionary = [[[NSMutableDictionary alloc] init] autorelease];
    [dictionary setValue:[NSNumber numberWithInt:JTPacketTypeChangeTurn] forKey:JTFieldNamePacketType];
    [dictionary setValue:[NSNumber numberWithInt:turnNumber] forKey:JTFieldNameTurnNumber];
    
    [self sendDictionaryToAllPeers:dictionary withDataMode:GKSendDataReliable];
}


#pragma mark -
#pragma mark Network packet handlers


- (void) handleGoodbyePacket:(NSDictionary*)dictionary {
    
    NSLog(@"handleGoodbyePacket:");
    
    [self disconnectSendingGoodbyePacket:NO];
}


- (void) handleDecideHostPacket:(NSDictionary*)dictionary {
    
    NSLog(@"handleDecideHostPacket:");
    
    [_randomHostNumbers addObject:[dictionary valueForKey:JTFieldNameRandomHostNumber]];
    
    // Have we received a random host number from all connected peers yet?
    if (_randomHostNumbers.count == [_gkSession peersWithConnectionState:GKPeerStateConnected].count) {
        // Do we have the highest random host number?
        // Have multiple hosts generated the same host number?
        BOOL oursIsHighest = YES;
        BOOL foundDuplicate = NO;
        for (NSNumber* value in _randomHostNumbers) {
            int randomHostNumber = [value intValue];
            if (randomHostNumber == _ourRandomHostNumber) {
                foundDuplicate = YES;
                break;
            }
            if (randomHostNumber > _ourRandomHostNumber) {
                oursIsHighest = NO;
                break;
            }
        }
        
        if (foundDuplicate) {
            // We'll have to do it all again.
            [self sendDecideHostPacket];
        }
        else {
            [self didDecideHost:oursIsHighest];
        }
    }
}


- (void) handleAddLinePacket:(NSDictionary*)dictionary {
    
    NSLog(@"handleAddLinePacket:");
    
    float fromX = [[dictionary valueForKey:JTFieldNameFromX] floatValue];
    float fromY = [[dictionary valueForKey:JTFieldNameFromY] floatValue];
    
    float toX = [[dictionary valueForKey:JTFieldNameToX] floatValue];
    float toY = [[dictionary valueForKey:JTFieldNameToY] floatValue];
    
    CGPoint from = CGPointMake(fromX, fromY);
    CGPoint to = CGPointMake(toX, toY);

    [(TouchDrawView*)self.view addLineFrom:from to:to isRemote:YES];
}


- (void) handleAddLineInProgressPacket:(NSDictionary*)dictionary {
    
    NSLog(@"handleAddLineInProgressPacket:");
    
    NSString* key = [dictionary valueForKey:JTFieldNameInProgressLineKey];
    
    float fromX = [[dictionary valueForKey:JTFieldNameFromX] floatValue];
    float fromY = [[dictionary valueForKey:JTFieldNameFromY] floatValue];
    
    float toX = [[dictionary valueForKey:JTFieldNameToX] floatValue];
    float toY = [[dictionary valueForKey:JTFieldNameToY] floatValue];
    
    CGPoint from = CGPointMake(fromX, fromY);
    CGPoint to = CGPointMake(toX, toY);
    
    [(TouchDrawView*)self.view addLineInProgressWithKey:key from:from to:to isRemote:YES];
}


- (void) handleUpdateLineInProgressPacket:(NSDictionary*)dictionary {
    
    NSLog(@"handleUpdateLineInProgressPacket:");
    
    NSString* key = [dictionary valueForKey:JTFieldNameInProgressLineKey];
    
    float fromX = [[dictionary valueForKey:JTFieldNameFromX] floatValue];
    float fromY = [[dictionary valueForKey:JTFieldNameFromY] floatValue];
    
    float toX = [[dictionary valueForKey:JTFieldNameToX] floatValue];
    float toY = [[dictionary valueForKey:JTFieldNameToY] floatValue];
    
    CGPoint from = CGPointMake(fromX, fromY);
    CGPoint to = CGPointMake(toX, toY);
    
    [(TouchDrawView*)self.view updateLineInProgressWithKey:key from:from to:to];
}


- (void) handleRemoveLineInProgressPacket:(NSDictionary*)dictionary {
    
    NSLog(@"handleRemoveLineInProgressPacket:");
    
    NSString* key = [dictionary valueForKey:JTFieldNameInProgressLineKey];
    
    [(TouchDrawView*)self.view removeLineInProgressWithKey:key];
}


- (void) handleClearScreenPacket:(NSDictionary*)dictionary {
    
    NSLog(@"handleClearScreenPacket:");
    
    [(TouchDrawView*)self.view clearScreen];
}


- (void) handleLineColourPacket:(NSDictionary*)dictionary {
    
    NSLog(@"handleLineColourPacket:");

    CGFloat red = [[dictionary valueForKey:JTFieldNameRed] floatValue];
    CGFloat green = [[dictionary valueForKey:JTFieldNameGreen] floatValue];
    CGFloat blue = [[dictionary valueForKey:JTFieldNameBlue] floatValue];
    
    UIColor* remoteLineColour = [[[UIColor alloc] initWithRed:red green:green blue:blue alpha:1.0] autorelease];
    [(TouchDrawView*)[self view] setRemoteLineColour:remoteLineColour];
}


- (void) handlePlayersPacket:(NSDictionary*)dictionary {
    
    NSLog(@"handlePlayersPacket:");
    
    int numPlayers = [[dictionary objectForKey:JTFieldNameNumPlayers] intValue];
    
    NSMutableArray* players = [[[NSMutableArray alloc] initWithCapacity:numPlayers] autorelease];
    
    for (int turnNumber = 1; turnNumber <= numPlayers; turnNumber++) {
        NSString* fieldNameForName = [NSString stringWithFormat:JTFieldNamePlayerXName, turnNumber];
        NSString* fieldNameForPeerID = [NSString stringWithFormat:JTFieldNamePlayerXPeerID, turnNumber];
        NSString* name = [dictionary valueForKey:fieldNameForName];
        NSString* peerID = [dictionary valueForKey:fieldNameForPeerID];
        Player* player = [[[Player alloc] initWithName:name andPeerID:peerID andTurnNumber:turnNumber] autorelease];
        BOOL isLocalPlayer = ([peerID isEqualToString:[_gkSession peerID]]);
        [player setIsLocalPlayer:isLocalPlayer];
        [players addObject:player];
    }

    [_players release];
    _players = [[Players alloc] initWithPlayers:players];
}


- (void) handleChangeTurnPacket:(NSDictionary*)dictionary {
    
    NSLog(@"handleChangeTurnPacket:");
    
    int turnNumber = [[dictionary objectForKey:JTFieldNameTurnNumber] intValue];
    [self respondToRemoteTurnChange:turnNumber];
}


#pragma mark -
#pragma mark Network helpers


- (void) sendDictionaryToAllPeers:(NSDictionary*)dictionary withDataMode:(GKSendDataMode)mode {
    
    NSLog(@"sendDictionaryToAllPeers:withDataMode:");
    NSLog(@"dictionary: %@", dictionary);
    
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
    NSLog(@"data: %@", data);
    
    NSError* error = nil;
    [_gkSession sendDataToAllPeers:data withDataMode:mode error:&error];
    
    if (error != nil) {
        [self displayError:error withTitle:@"sendDictionaryToAllPeers:withDataMode:error:"];
    }
}


#pragma mark -
#pragma mark GKPeerPickerControllerDelegate


- (void) peerPickerController:(GKPeerPickerController*)picker didSelectConnectionType:(GKPeerPickerConnectionType)type {
    
    NSLog(@"peerPickerController:didSelectConnectionType:");
    NSAssert(type == GKPeerPickerConnectionTypeNearby, @"type == GKPeerPickerConnectionTypeNearby");
}


- (void) peerPickerController:(GKPeerPickerController*)picker didConnectPeer:(NSString*)peerID toSession:(GKSession*)session {
    
    NSLog(@"peerPickerController:didConnectPeer:toSession:");
    NSLog(@"peerID: %@", peerID);
    NSLog(@"displayNameForPeer: %@", [session displayNameForPeer:peerID]);
    NSLog(@"session.sessionID: %@", session.sessionID);
    NSLog(@"session.displayName: %@", session.displayName);

    [picker setDelegate:nil];
    [picker dismiss];
    [picker autorelease];
    
    _gkSession = [session retain];
    [_gkSession setAvailable:NO];
    [_gkSession setDelegate:self];
    [_gkSession setDataReceiveHandler:self withContext:NULL];
    
    [self didConnect];
}


- (void) peerPickerControllerDidCancel:(GKPeerPickerController*)picker {
    
    NSLog(@"peerPickerControllerDidCancel:");
    
    [picker setDelegate:nil];
    [picker autorelease];
    
    _networkBarButtonItem.enabled = YES;
}


#pragma mark -
#pragma mark GKSession receive handler


- (void) receiveData:(NSData*)data fromPeer:(NSString*)peer inSession:(GKSession*)session context:(void*)context {
    
    NSLog(@"receiveData:fromPeer:inSession:context:");
    
    if (!_networkGameInProgress) {
        NSLog(@"No network game currently in progress!");
        return;
    }
    
    NSLog(@"data: %@", data);
    NSLog(@"peer: %@ (%@)", peer, [session displayNameForPeer:peer]);
    NSLog(@"session: %@", session);
    NSLog(@"context: %p", context);
    
    NSDictionary* dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSLog(@"dictionary: %@", dictionary);

    int packetType = [[dictionary objectForKey:JTFieldNamePacketType] intValue];
    
    switch (packetType) {
            
        case JTPacketTypeGoodbye:
            [self handleGoodbyePacket:dictionary];
            break;
            
        case JTPacketTypeDecideHost:
            [self handleDecideHostPacket:dictionary];
            break;
            
        case JTPacketTypeAddLine:
            [self handleAddLinePacket:dictionary];
            break;
            
        case JTPacketTypeAddLineInProgress:
            [self handleAddLineInProgressPacket:dictionary];
            break;
            
        case JTPacketTypeUpdateLineInProgress:
            [self handleUpdateLineInProgressPacket:dictionary];
            break;
            
        case JTPacketTypeRemoveLineInProgress:
            [self handleRemoveLineInProgressPacket:dictionary];
            break;
            
        case JTPacketTypeClearScreen:
            [self handleClearScreenPacket:dictionary];
            break;
            
        case JTPacketTypeLineColour:
            [self handleLineColourPacket:dictionary];
            break;
            
        case JTPacketTypePlayers:
            [self handlePlayersPacket:dictionary];
            break;
            
        case JTPacketTypeChangeTurn:
            [self handleChangeTurnPacket:dictionary];
            break;
            
        default:
            NSAssert(NO, @"unknown packet type in received packet!");
            break;
    }
}


#pragma mark -
#pragma mark GKSessionDelegate


- (void) session:(GKSession*)session peer:(NSString*)peerID didChangeState:(GKPeerConnectionState)state {
    
    NSLog(@"session:peer:didChangeState:");
    NSLog(@"session: %@", session);
    NSLog(@"session.sessionID: %@", session.sessionID);
    NSLog(@"session.displayName: %@", session.displayName);
    NSLog(@"peerID: %@; state: %d", peerID, state);
    NSLog(@"displayNameForPeer: %@", [session displayNameForPeer:peerID]);
    
	switch (state) {
		case GKPeerStateAvailable:
			NSLog(@"state: GKPeerStateAvailable");
			break;
		case GKPeerStateUnavailable:
			NSLog(@"state: GKPeerStateUnavailable");
			break;
		case GKPeerStateConnected:
			NSLog(@"state: GKPeerStateConnected");
			break;
		case GKPeerStateDisconnected:
			NSLog(@"state: GKPeerStateDisconnected");
			break;
		case GKPeerStateConnecting:
			NSLog(@"state: GKPeerStateConnecting");
			break;
	}

/*
    NSLog(@"peerID: \"%@\"; session.PeerID: \"%@\"", peerID, session.peerID);
    NSLog(@"_connectingToPeerIDs: %@", _connectingToPeerIDs);
    if (state == GKPeerStateAvailable && session.available && ![peerID isEqualToString:session.peerID]) {
        if ([_connectingToPeerIDs containsObject:peerID]) {
            NSLog(@"We ARE already in the process of connecting to this guy");
        }
        else {
            NSLog(@"We ARE NOT already in the process of connecting to this guy");
            [_connectingToPeerIDs addObject:peerID];
            [NSThread sleepForTimeInterval:0.5f];
            [session connectToPeer:peerID withTimeout:30.0f];
        }
    }
    
    if (state == GKPeerStateConnected) {
        [_connectingToPeerIDs removeObjectIdenticalTo:peerID];
        _disconnectBarButtonItem.enabled = YES;
        _networkGameInProgress = YES;
        _gkSession.available = NO;
        // [self sendDecideHostPacket];
    }
*/
    
    if (state == GKPeerStateDisconnected) {
        [self disconnectSendingGoodbyePacket:NO];
    }
}


- (void) session:(GKSession*)session didReceiveConnectionRequestFromPeer:(NSString*)peerID {
    
    NSLog(@"session:didReceiveConnectionRequestFromPeer:");
    NSLog(@"session: %@", session);
    NSLog(@"session.sessionID: %@", session.sessionID);
    NSLog(@"session.displayName: %@", session.displayName);
    NSLog(@"peerID: %@", peerID);
    NSLog(@"displayNameForPeer: %@", [session displayNameForPeer:peerID]);

    /*
     * NSError* error = nil;
     * [session acceptConnectionFromPeer:peerID error:&error];
     *
     * if (error != nil) {
     *    self displayError:error withTitle:@"acceptConnectionFromPeer:error:"];
     * }
     */
}


- (void) session:(GKSession*)session connectionWithPeerFailed:(NSString*)peerID withError:(NSError*)error {
    
    NSLog(@"session:connectionWithPeerFailed:withError:");
    NSLog(@"session: %@", session);
    NSLog(@"session.sessionID: %@", session.sessionID);
    NSLog(@"session.displayName: %@", session.displayName);
    NSLog(@"peerID: %@; error: %@", peerID, error);
    NSLog(@"displayNameForPeer: %@", [session displayNameForPeer:peerID]);
    
    /*
     * if ([error code] != GKSessionInProgressError) {
     *    [self displayError:error withTitle:@"session:connectionWithPeerFailed:withError:"];
     * }
     */
}


- (void) session:(GKSession*)session didFailWithError:(NSError*)error {
    
    NSLog(@"session:didFailWithError:");
    NSLog(@"session: %@", session);
    NSLog(@"session.sessionID: %@", session.sessionID);
    NSLog(@"session.displayName: %@", session.displayName);
    NSLog(@"error: %@", error);
    
    [self displayError:error withTitle:@"session:didFailWithError:"];
    [self disconnectSendingGoodbyePacket:NO];
}


@end
