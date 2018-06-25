//
//  NEMenuViewController.h
//  Command
//
//  Created by Nicholas Eby on 2/23/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NEFunction.h"

@interface NEMenuViewController : NSViewController

//UI
@property(nonatomic, strong) IBOutlet NSLayoutConstraint *hardware_heightConstraint;
@property(nonatomic, weak) IBOutlet NSView *hardware_view;
@property(nonatomic, weak) IBOutlet NSTextField *hardware_label;
@property(nonatomic, weak) IBOutlet NSPopUpButton *dcc_menu;
@property(nonatomic, weak) IBOutlet NSPopUpButton *serial_connections_menu;
@property(nonatomic, weak) IBOutlet NSPopUpButton *baud_menu;
@property(nonatomic, weak) IBOutlet NSButton *connect_button;
@property(nonatomic, weak) IBOutlet NSButton *disconnect_button;
@property(nonatomic, weak) IBOutlet NSButton *control_button;
@property(nonatomic, weak) IBOutlet NSButton *quit_button;

@end
