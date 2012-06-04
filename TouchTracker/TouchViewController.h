//
//  TouchViewController.h
//  TouchTracker
//
//  Created by Jonathan Taylor on 21/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameKit/GameKit.h"
#import "TouchDrawView.h"
#import "TurnBar.h"

@interface TouchViewController : UIViewController
<
    GKPeerPickerControllerDelegate,
    GKSessionDelegate,
    UIActionSheetDelegate,
    TouchDrawViewDelegate,
    TurnBarDelegate
>

@end
