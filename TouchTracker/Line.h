//
//  Line.h
//  TouchTracker
//
//  Created by Jonathan Taylor on 21/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Line : NSObject

@property (nonatomic) CGPoint from;
@property (nonatomic) CGPoint to;
@property (nonatomic, retain) UIColor* colour;

- (id) initFrom:(CGPoint)from to:(CGPoint)to colour:(UIColor*)colour;
- (BOOL) isReadyForRemoteUpdate;

@end
