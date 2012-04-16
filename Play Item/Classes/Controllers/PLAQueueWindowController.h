//
//  PLAQueueWindowController.h
//  Play Item
//
//  Created by Danny Greg on 11/04/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PLAShadowTextField;
@class PLATrack;

@interface PLAQueueWindowController : NSWindowController <NSTableViewDelegate>

@property (nonatomic, retain) IBOutlet NSButton *playButton; 

- (id)init;

- (IBAction)togglePlay:(id)sender;

- (void)downloadTrack:(PLATrack *)track;

@end
