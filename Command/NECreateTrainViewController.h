//
//  NECreateTrainViewController.h
//  Command
//
//  Created by Nicholas Eby on 11/28/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NECreateTrainViewController : NSViewController
{
    
}

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, weak) IBOutlet NSArrayController *arrayController;


@property(nonatomic, weak) IBOutlet NSView *container_view;
    @property(nonatomic, weak) IBOutlet NSTextField *name_textField;
    @property(nonatomic, weak) IBOutlet NSTextField *dcc_textField;
    @property(nonatomic, weak) IBOutlet NSButton *dcc_short_radio;
    @property(nonatomic, weak) IBOutlet NSButton *dcc_long_radio;
    @property(nonatomic, weak) IBOutlet NSButton *delete_button;
    @property(nonatomic, weak) IBOutlet NSTextField *horn_textField;
    @property(nonatomic, weak) IBOutlet NSTextField *headlight_textField;
    @property(nonatomic, weak) IBOutlet NSTextField *bell_textField;
@property(nonatomic, weak) IBOutlet NSView *placeholder_view;
@property(nonatomic, weak) IBOutlet NSTextField *placeholder_textField;
@property(nonatomic, weak) IBOutlet NSTableView *trains_tableView;

@end
