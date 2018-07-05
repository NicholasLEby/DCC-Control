//
//  ViewController.m
//  Command
//
//  Created by Nicholas Eby on 2/13/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import "ConsistViewController.h"
#import "NEFunctionCell.h"
#import "NENCECommand.h"
#import "NESerialManager.h"
#import "ViewController.h"
//App Delegate
#import "AppDelegate.h"
//Core Data
#import "Train+CoreDataClass.h"
#import "Train+CoreDataProperties.h"
#import "trains+CoreDataModel.h"
//Third Party
#import "ORSSerialPortManager.h"
#import "ORSSerialPort.h"
#import "ORSSerialRequest.h"
//Consist
#import "NEConsist.h"

NSInteger const consist_min_speed = 0;
NSInteger const consist_max_speed = 128;
NSInteger const default_consist_headlight_tag = 0;
NSInteger const default_consist_bell_tag = 1;
NSInteger const default_consist_horn_tag = 2;

@interface ConsistViewController () <NSWindowDelegate>

//Data
@property(nonatomic, strong) NSMutableArray *active_functions;
//Helpers
@property(nonatomic, strong) NENCECommand *command;
//State
@property(nonatomic, strong) NEConsist *currentConsist;

@property(nonatomic) NSInteger speed;
@property(nonatomic) NSInteger direction;
@property(nonatomic) BOOL keyDown; //for tracking key state
@property(nonatomic) BOOL shouldClose;
//
@property(nonatomic, strong) AppDelegate *appDelegate;
@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong) NSArray *savedTrains;

@end

@implementation ConsistViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    //State Defaults
    self.currentConsist = nil;
    self.speed = 0;
    self.direction = kForward128;
    self.keyDown = NO;
    self.active_functions = [[NSMutableArray alloc] init];
    
    self.appDelegate = (AppDelegate *)[NSApp delegate];
    self.managedObjectContext = [self managedObjectContext];

    //Command Helper
    self.command = [[NENCECommand alloc] init];
    NSLog(@"%@", self.view.window);
    self.view.window.delegate = self;
    
    [self.view.window setTitle:[NSString stringWithFormat:@"Command (%@)", _appDelegate.serialManager.serialPort.path]];
    
    //Inits
    [self initDefaultData];
    [self initUI];
    
}

-(void)viewDidAppear
{
    [super viewDidAppear];

    NSLog(@"%@", self.view.window);
    self.view.window.delegate = self;

    [self initConsistBuilder];
}

-(BOOL)windowShouldClose:(NSWindow *)sender
{
    NSLog(@"windowShouldClose");
    
    if(_shouldClose)
    {
        return YES;
    }
    else
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Consist Builder"];
        [alert setInformativeText:@"Would you like to Reset your locomotives consist by setting CV19 back to 0? Some locomotives will sound their horns twice when this is complete."];
        [alert addButtonWithTitle:@"Reset and Close"];
        [alert addButtonWithTitle:@"Skip"];
        [alert setAccessoryView:_custom_exit_view];
        
        NSLog(@"%@", _custom_view);
        
        [alert beginSheetModalForWindow:self.view.window
                      completionHandler:^(NSInteger result)
         {
             if(result == NSAlertSecondButtonReturn)
             {
                 NSLog(@"Done 1");
                 self.shouldClose = YES;
                 [self.view.window close];
             }
             else if(result == NSAlertFirstButtonReturn)
             {
                 //Execute Command
                 NSData *command_to_send = [self.command locomotiveResetConsistCommandWithAddr:self.currentConsist.lead_train.dcc_address];
                 
                 //Update Console
                 [self showConsoleMessage:[NSString stringWithFormat:@"Sending %@", command_to_send] withReset:NO];
                 
                 //Block
                 [self.appDelegate.serialManager sendCommand:command_to_send withPacketResponseLength:1 andUserInfo:@"AE" andCallback:^(BOOL success, NSString *response)
                  {
                      if(success)
                      {
                          [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:YES];
                      }
                      else
                      {
                          [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:NO];
                      }
                      
                      //Refresh UI
                      [self refreshUI];
                  }];
                 
                 if(self.currentConsist.rear_train)
                 {
                     NSData *command_to_send = [self.command locomotiveResetConsistCommandWithAddr:self.currentConsist.rear_train.dcc_address];
                     
                     //Update Console
                     [self showConsoleMessage:[NSString stringWithFormat:@"Sending %@", command_to_send] withReset:NO];
                     
                     //Block
                     [self.appDelegate.serialManager sendCommand:command_to_send withPacketResponseLength:1 andUserInfo:@"AE" andCallback:^(BOOL success, NSString *response)
                      {
                          if(success)
                          {
                              [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:YES];
                          }
                          else
                          {
                              [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:NO];
                          }
                          
                          //Refresh UI
                          [self refreshUI];
                      }];
                 }
                 

                 self.shouldClose = YES;
                 [self.view.window close];
             }
         }];
        
        return NO;
    }
}




//---------------------------------- UI ----------------------------------//

-(void)initDefaultData
{
    self.currentConsist = [[NEConsist alloc] init];
    
    
    
    //Load Saved Trains
    [self.lead_train_popupButton removeAllItems];
    [self.rear_train_popupButton removeAllItems];
    [self.other1_train_popupButton removeAllItems];
    [self.other2_train_popupButton removeAllItems];
    [self.other3_train_popupButton removeAllItems];
    
    [self.lead_train_popupButton addItemWithTitle:@"Select Locomotive"];
    [self.rear_train_popupButton addItemWithTitle:@"Select Locomotive"];
    [self.other1_train_popupButton addItemWithTitle:@"Select Locomotive"];
    [self.other2_train_popupButton addItemWithTitle:@"Select Locomotive"];
    [self.other3_train_popupButton addItemWithTitle:@"Select Locomotive"];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Train" inManagedObjectContext:_managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    
    // Specify how the fetched objects should be sorted
    //NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    //[fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects != nil)
    {
        NSMutableArray *temp = [NSMutableArray arrayWithArray:_savedTrains];
        [temp addObjectsFromArray:fetchedObjects];
        self.savedTrains = [NSArray arrayWithArray:temp];
        
        //Add Saved to Drop Down
        for(Train *train in _savedTrains)
        {
            NSString *name = [NSString stringWithFormat:@"%@ (%.3d)", train.name, train.dcc_address];
            [self.lead_train_popupButton addItemWithTitle:name];
            [self.rear_train_popupButton addItemWithTitle:name];
            [self.other1_train_popupButton addItemWithTitle:name];
            [self.other2_train_popupButton addItemWithTitle:name];
            [self.other3_train_popupButton addItemWithTitle:name];
        }
    }
}

-(IBAction)addTrainToConsist:(id)sender
{
    
    if(self.consist_textField.stringValue == nil || [self.consist_textField.stringValue isEqualToString:@""])
    {
        [self showErrorMessage:@"No consist address!"];
        
        return;
    }
    
    
    NSInteger tag = ((NSButton*)sender).tag;

    
    //Lead
    if(tag == 0)
    {
        Train *selected_train = [_savedTrains objectAtIndex:_lead_train_popupButton.indexOfSelectedItem - 1];

        //Execute Command
        NSData *command_to_send = [_command locomotiveConsistCommandWithAddr:selected_train.dcc_address consistNumber:_consist_textField.integerValue andPosition:_lead_popupButton.indexOfSelectedItem];
        
        //Update Console
        [self showConsoleMessage:[NSString stringWithFormat:@"Sending %@", command_to_send] withReset:NO];
        
        //Block
        [_appDelegate.serialManager sendCommand:command_to_send withPacketResponseLength:1 andUserInfo:@"AE" andCallback:^(BOOL success, NSString *response)
         {
             if(success)
             {
                 [self.lead_button setTitle:@"Added!"];
                                  
                 self.currentConsist.lead_train = selected_train;
                 
                 [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:YES];
             }
             else
             {
                 [self.lead_button setTitle:@"Error"];
                 [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:NO];
             }
             
             //Refresh UI
             [self refreshUI];
         }];
    }
    //Rear
    else if(tag == 1)
    {
        Train *selected_train = [_savedTrains objectAtIndex:_rear_train_popupButton.indexOfSelectedItem-1];

        //Execute Command
        NSData *command_to_send = [_command locomotiveConsistCommandWithAddr:selected_train.dcc_address consistNumber:_consist_textField.integerValue andPosition:_rear_popupButton.indexOfSelectedItem];

        //Update Console
        [self showConsoleMessage:[NSString stringWithFormat:@"Sending %@", command_to_send] withReset:NO];
        
        //Block
        [_appDelegate.serialManager sendCommand:command_to_send withPacketResponseLength:1 andUserInfo:@"AE" andCallback:^(BOOL success, NSString *response)
         {
             if(success)
             {
                 [self.rear_button setTitle:@"Added!"];
                 
                 self.currentConsist.rear_train = selected_train;
                 
                 [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:YES];
             }
             else
             {
                 [self.rear_button setTitle:@"Error"];
                 [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:NO];
             }
             
             //Refresh UI
             [self refreshUI];
         }];
    }
    //Other 1
    else if(tag == 2)
    {
        Train *selected_train = [_savedTrains objectAtIndex:_other1_train_popupButton.indexOfSelectedItem-1];

        //Execute Command
        NSData *command_to_send = [_command locomotiveConsistCommandWithAddr:selected_train.dcc_address consistNumber:_consist_textField.integerValue andPosition:_other1_popupButton.indexOfSelectedItem];

        //Update Console
        [self showConsoleMessage:[NSString stringWithFormat:@"Sending %@", command_to_send] withReset:NO];
        
        //Block
        [_appDelegate.serialManager sendCommand:command_to_send withPacketResponseLength:1 andUserInfo:@"AE" andCallback:^(BOOL success, NSString *response)
         {
             if(success)
             {
                 [self.other1_button setTitle:@"Added!"];
                 
                 self.currentConsist.other1_train = selected_train;

                 [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:YES];
             }
             else
             {
                 [self.other1_button setTitle:@"Error"];
                 [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:NO];
             }
             
             //Refresh UI
             [self refreshUI];
         }];
    }
    //Other 2
    else if(tag == 3)
    {
        Train *selected_train = [_savedTrains objectAtIndex:_other2_train_popupButton.indexOfSelectedItem-1];

        //Execute Command
        NSData *command_to_send = [_command locomotiveConsistCommandWithAddr:selected_train.dcc_address consistNumber:_consist_textField.integerValue andPosition:_other2_popupButton.indexOfSelectedItem];

        //Update Console
        [self showConsoleMessage:[NSString stringWithFormat:@"Sending %@", command_to_send] withReset:NO];
        
        //Block
        [_appDelegate.serialManager sendCommand:command_to_send withPacketResponseLength:1 andUserInfo:@"AE" andCallback:^(BOOL success, NSString *response)
         {
             if(success)
             {
                 [self.other2_button setTitle:@"Added!"];
                 
                 self.currentConsist.other2_train = selected_train;

                 [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:YES];
             }
             else
             {
                 [self.other2_button setTitle:@"Error"];
                 [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:NO];
             }
             
             //Refresh UI
             [self refreshUI];
         }];
    }
    //Other 3
    else if(tag == 4)
    {
        Train *selected_train = [_savedTrains objectAtIndex:_other3_train_popupButton.indexOfSelectedItem-1];

        //Execute Command
        NSData *command_to_send = [_command locomotiveConsistCommandWithAddr:selected_train.dcc_address consistNumber:_consist_textField.integerValue andPosition:_other3_popupButton.indexOfSelectedItem];

        //Update Console
        [self showConsoleMessage:[NSString stringWithFormat:@"Sending %@", command_to_send] withReset:NO];
        
        //Block
        [_appDelegate.serialManager sendCommand:command_to_send withPacketResponseLength:1 andUserInfo:@"AE" andCallback:^(BOOL success, NSString *response)
         {
             if(success)
             {
                 [self.other3_button setTitle:@"Added!"];
                 
                 self.currentConsist.other3_train = selected_train;

                 [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:YES];
             }
             else
             {
                 [self.other3_button setTitle:@"Error"];
                 [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:NO];
             }
             
             //Refresh UI
             [self refreshUI];
         }];
    }
}






-(void)initUI
{
    //Set Default Hard Button Tags & Event Handelers
    self.headlight_buton.tag = default_consist_headlight_tag;
    self.headlight_buton.keyEquivalent = [NSString stringWithFormat:@"%ld",(long)default_consist_headlight_tag];
    self.headlight_buton.toolTip = [NSString stringWithFormat:@"toolip"];
    
    self.bell_button.tag = default_consist_bell_tag;
    self.bell_button.keyEquivalent = [NSString stringWithFormat:@"%ld",(long)default_consist_bell_tag];
    
    self.horn_button.tag = default_consist_horn_tag;
    self.horn_button.keyEquivalent = [NSString stringWithFormat:@"%ld",(long)default_consist_horn_tag];
    
    //Speed Slider
    self.speed_slider.altIncrementValue = 1;
    self.speed_slider.minValue = consist_min_speed;
    self.speed_slider.maxValue = consist_max_speed;
    self.speed_slider.integerValue = _speed;
    
    //Direction Segmented Control
    self.speed_segmentedControl.selectedSegment = 1;
    
    //Speed Labels
    self.speed_mid_label.stringValue = [NSString stringWithFormat:@"%ld", consist_max_speed / 2];
    self.speed_max_label.stringValue = [NSString stringWithFormat:@"%ld", consist_max_speed];
    
    //Make sure the horn button fires on mouse up and down (momentary)
    [_horn_button sendActionOn:(NSEventMaskLeftMouseDown|NSEventMaskLeftMouseUp)];
    
    //Update Status
    [self updateStatusWindow];
    [self showConsoleMessage:@"Connected" withReset:YES];
}

-(void)initConsistBuilder
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Consist Builder"];
    [alert setInformativeText:@"Use inputs below to add locomotives to your conist. Some locomotives will sound their horn twice when successfully editing CV19."];
    [alert addButtonWithTitle:@"Done"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAccessoryView:_custom_view];
    [alert beginSheetModalForWindow:self.view.window
                      completionHandler:^(NSInteger result)
     {
         if(result == NSAlertFirstButtonReturn)
         {
             NSLog(@"Done");
             self.currentConsist.dcc_address = self.consist_textField.integerValue;
             
             [self.tableView reloadData];
             
             //Update Status
             [self updateStatusWindow];
         }
         else if(result == NSAlertSecondButtonReturn)
         {
             NSLog(@"Cancel");
             [self.view.window close];
         }
     }];
}

-(void)updateStatusWindow
{
    NSString *locomotives = @"";
    
    NSString *forward_direction = (_direction == kForward128) ? @"L" : @"R";
    locomotives = [NSString stringWithFormat:@"%@%d", forward_direction, _currentConsist.lead_train.dcc_address];
    
    if(_currentConsist.rear_train)
    {
        NSString *rear_direction = (_direction == kForward128) ? @"R" : @"L";
        locomotives = [locomotives stringByAppendingString:[NSString stringWithFormat:@" - %@%d", rear_direction, _currentConsist.rear_train.dcc_address]];
    }
    
    NSString *name = [NSString stringWithFormat:@"%@ (%.3d)(%@)", @"Consist", _currentConsist.dcc_address, locomotives];
    
    NSString *speed_string = [NSString stringWithFormat:@"Speed: %@ %ld", (_direction == 0) ? @"Reverse" : @"Forward", _speed];
    
    self.consoleLeftTop_label.stringValue = name;
    self.consoleLeftBottom_label.stringValue = speed_string;
    self.speed_slider.integerValue = _speed;
    
    //Reset
    self.console_headlight_imageView.hidden = YES;
    self.console_bell_imageView.hidden = YES;
    self.console_horn_imageView.hidden = YES;
    
    for(NSNumber *function_number in _active_functions)
    {
        if(function_number.integerValue == 0)
        {
            self.console_headlight_imageView.hidden = NO;
        }
        else if(function_number.integerValue == 1)
        {
            self.console_bell_imageView.hidden = NO;
        }
        else if(function_number.integerValue == 2)
        {
            self.console_horn_imageView.hidden = NO;
        }
    }
}

-(void)refreshUI
{
    //Update Hard Buttons
    NSArray *hard_buttons = @[_horn_button, _bell_button, _headlight_buton];
    
    for(NSButton *button in hard_buttons)
    {
        //Reset button state
        button.state = NO;
        
        for(NSNumber *function_number in _active_functions)
        {
            if(function_number.integerValue == button.tag)
            {
                button.state = YES;
            }
        }
    }
    
    //Update Soft View
    [self.tableView reloadData];
    
    //Update Display
    [self updateStatusWindow];
}













//---------------------------------- User Actions ----------------------------------//

-(IBAction)function:(id)sender
{
    NSButton *button = (NSButton*)sender;
    
    NSNumber *function_number = [NSNumber numberWithInteger:button.tag];
    
    BOOL state;
    
    if([_active_functions containsObject:function_number])
    {
        state = NO;
        [_active_functions removeObject:function_number];
    }
    else
    {
        state = YES;
        [_active_functions addObject:function_number];
    }
    
        
    //Execute Command
    NSData *command_to_send = [_command locomotiveFunctionCommand:[self currentLeadLocomotive].dcc_address andFunctionKey:function_number andFunctionState:state];
   
    //Update Console
    [self showConsoleMessage:[NSString stringWithFormat:@"Sending %@", command_to_send] withReset:NO];

    //Block
    [_appDelegate.serialManager sendCommand:command_to_send withPacketResponseLength:1 andUserInfo:@"A2" andCallback:^(BOOL success, NSString *response)
     {
         if(success)
         {
             [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:YES];
         }
         else
         {
             if([self.active_functions containsObject:function_number])
             {
                 [self.active_functions removeObject:function_number];
             }
             else
             {
                 [self.active_functions addObject:function_number];
             }
             
             [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:NO];
         }
         
         //Update UI
         [self refreshUI];
     }];
}

-(IBAction)changeDirection:(id)sender
{
    NSSegmentedControl *segmented_control = (NSSegmentedControl*)sender;
    
    if(segmented_control.selectedSegment == _direction) return;
    
    NSInteger current_direction = _direction;
    
    //Play Sound
    [[NSSound soundNamed:@"Tink"] play];
    
    self.direction = segmented_control.selectedSegment;
    self.speed = 0; //stop the train first. JMRI does +56 -> -56, I prefer +56 -> -0

    NSLog(@"Control Panel: Change Direction from %ld to %ld", current_direction, _direction);
    
    //Execute Command
    NSData *command_to_send = [_command locomotiveSpeedCommandWithAddr:_currentConsist.dcc_address andSpeed:_speed andDirection:_direction];
    
    //Update Console
    [self showConsoleMessage:[NSString stringWithFormat:@"Sending %@", command_to_send] withReset:NO];

    //Block
    [_appDelegate.serialManager sendCommand:command_to_send withPacketResponseLength:1 andUserInfo:@"A2" andCallback:^(BOOL success, NSString *response)
     {
         if(success)
         {
             [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:YES];
         }
         else
         {
             [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:NO];
         }
         
         //Refresh UI
         [self refreshUI];
     }];
}

-(IBAction)emergency:(id)sender
{
    self.speed = 0;
    
    NSLog(@"Control Panel: Emergency Stop!");
    
    //Execute Command
    NSData *command_to_send = [_command locomotiveEmergencyStopCommandWithAddr:_currentConsist.dcc_address andDirection:_direction];
    
    //Update Console
    [self showConsoleMessage:[NSString stringWithFormat:@"Sending %@", command_to_send] withReset:NO];

    //Block
    [_appDelegate.serialManager sendCommand:command_to_send withPacketResponseLength:1 andUserInfo:@"A2" andCallback:^(BOOL success, NSString *response)
     {
         if(success)
         {
             [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:YES];
         }
         else
         {
             [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:NO];
         }

         //Refresh UI
         [self refreshUI];
     }];
}

- (IBAction)adjustSpeed:(id)sender
{
    NSSlider *slider = (NSSlider*)sender;

    NSEvent *event = [[NSApplication sharedApplication] currentEvent];
    
    BOOL startingDrag = event.type == NSLeftMouseDown;
    BOOL endingDrag = event.type == NSLeftMouseUp;
    BOOL dragging = event.type == NSLeftMouseDragged;
    
    NSAssert(startingDrag || endingDrag || dragging, @"unexpected event type caused slider change: %@", event);
    
    if (startingDrag)
    {
        NSLog(@"slider value started changing");
        // do whatever needs to be done when the slider starts changing
    }
    
    // do whatever needs to be done for "uncommitted" changes
    NSInteger new_speed = [slider integerValue];
    
    if(new_speed < consist_max_speed)
    {
        self.speed = new_speed;
        //Refresh UI
        [self updateStatusWindow];
        
        //Sound
        [[NSSound soundNamed:@"Pop"] play];
    }
    
    if (endingDrag)
    {
        NSLog(@"slider value stopped changing");
        
        NSInteger new_speed = [slider integerValue];
        
        if(new_speed < consist_max_speed)
        {
            self.speed = new_speed;
            
            //Execute Command
            NSData *command_to_send = [_command locomotiveSpeedCommandWithAddr:_currentConsist.dcc_address andSpeed:_speed andDirection:_direction];
            
            //Update Console
            [self showConsoleMessage:[NSString stringWithFormat:@"Sending %@", command_to_send] withReset:NO];

            //Block
            [_appDelegate.serialManager sendCommand:command_to_send withPacketResponseLength:1 andUserInfo:@"A2" andCallback:^(BOOL success, NSString *response)
             {
                 if(success)
                 {
                     [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:YES];
                 }
                 else
                 {
                     [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:NO];
                 }
                 
                 //Refresh UI
                 [self refreshUI];
             }];
        }
        else
        {
            [self showSpeedWarning];
        }

    }
}
    
    











//---------------------------------- Table View ----------------------------------//

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return 29;
}

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 31.0f;
}


-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableRowView* rowView = [tableView rowViewAtRow:row makeIfNecessary:NO];
    rowView.backgroundColor = [NSColor colorWithWhite:0.0f alpha:0.0f];
    tableView.backgroundColor = [NSColor colorWithWhite:0.0f alpha:0.0f];
    tableColumn.headerCell.backgroundColor = [NSColor colorWithWhite:0.0f alpha:0.0f];
    tableColumn.headerCell.selectable = NO;
    
    NEFunctionCell *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    if ([tableView.identifier isEqualToString:@"FunctionTable"])
    {
        tableColumn.headerCell.title = @"DCC Functions";
        
        if ([tableColumn.identifier isEqualToString:@"FunctionColumn"])
        {
            NSNumber *function_number = [NSNumber numberWithInteger:row];
            NSString *function_label = @"";
            
            if(row == 0) { function_label = [self currentLeadLocomotive].function0; }
            else if(row == 1) { function_label = [self currentLeadLocomotive].function1; }
            else if(row == 2) { function_label = [self currentLeadLocomotive].function2; }
            else if(row == 3) { function_label = [self currentLeadLocomotive].function3; }
            else if(row == 4) { function_label = [self currentLeadLocomotive].function4; }
            else if(row == 5) { function_label = [self currentLeadLocomotive].function5; }
            else if(row == 6) { function_label = [self currentLeadLocomotive].function6; }
            else if(row == 7) { function_label = [self currentLeadLocomotive].function7; }
            else if(row == 8) { function_label = [self currentLeadLocomotive].function8; }
            else if(row == 9) { function_label = [self currentLeadLocomotive].function9; }
            else if(row == 10) { function_label = [self currentLeadLocomotive].function10; }
            else if(row == 11) { function_label = [self currentLeadLocomotive].function11; }
            else if(row == 12) { function_label = [self currentLeadLocomotive].function12; }
            else if(row == 13) { function_label = [self currentLeadLocomotive].function13; }
            else if(row == 14) { function_label = [self currentLeadLocomotive].function14; }
            else if(row == 15) { function_label = [self currentLeadLocomotive].function15; }
            else if(row == 16) { function_label = [self currentLeadLocomotive].function16; }
            else if(row == 17) { function_label = [self currentLeadLocomotive].function17; }
            else if(row == 18) { function_label = [self currentLeadLocomotive].function18; }
            else if(row == 19) { function_label = [self currentLeadLocomotive].function19; }
            else if(row == 20) { function_label = [self currentLeadLocomotive].function20; }
            else if(row == 21) { function_label = [self currentLeadLocomotive].function21; }
            else if(row == 22) { function_label = [self currentLeadLocomotive].function22; }
            else if(row == 23) { function_label = [self currentLeadLocomotive].function23; }
            else if(row == 24) { function_label = [self currentLeadLocomotive].function24; }
            else if(row == 25) { function_label = [self currentLeadLocomotive].function25; }
            else if(row == 26) { function_label = [self currentLeadLocomotive].function26; }
            else if(row == 27) { function_label = [self currentLeadLocomotive].function27; }
            else if(row == 28) { function_label = [self currentLeadLocomotive].function28; }

            
            NSString *title = [NSString stringWithFormat:@"F%@: %@", function_number, function_label];
            [cellView.label setStringValue:title];
        
            
            //Button
            if(function_number.integerValue == [self currentLeadLocomotive].horn_function) //key 2 is usually the horn, which needs a momentary button
            {
                [cellView.button sendActionOn:(NSEventMaskLeftMouseDown|NSEventMaskLeftMouseUp)];
            }
            else
            {
                [cellView.button sendActionOn:(NSEventMaskLeftMouseUp)];
            }
            
            
            BOOL state = [_active_functions containsObject:function_number];
            
            [cellView.button setButtonType:NSButtonTypePushOnPushOff];
            [cellView.button setTitle:[NSString stringWithFormat:@"F%@", function_number]];
            [cellView.button setTag:function_number.integerValue];
            [cellView.button setState:state];
            [cellView.button setTarget:self];
            [cellView.button setAction:@selector(function:)];
        }
    }

    return cellView;
    
}












//---------------------------------- Utilz ----------------------------------//


- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
}

-(void)resetUI
{
    //Defaults
    self.speed = 0;
    self.direction = kForward128;
    self.headlight_buton.tag = default_consist_headlight_tag;
    self.bell_button.tag = default_consist_bell_tag;
    self.horn_button.tag = default_consist_horn_tag;
    
    //Clear
    self.currentConsist = nil;
    
    [self initDefaultData]; //reset data
    [self refreshUI];
    [self updateStatusWindow];
}

-(void)showSpeedWarning
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Speed warning!"];
    [alert setInformativeText:[NSString stringWithFormat:@"You are currently at the max speed of: %ld", consist_max_speed]];
    [alert addButtonWithTitle:@"Dismiss"];
    [alert runModal];
}

-(void)showErrorMessage:(NSString*)message
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Error"];
    [alert setInformativeText:message];
    [alert addButtonWithTitle:@"Dismiss"];
    [alert runModal];
}

-(void)showConsoleMessage:(NSString*)message withReset:(BOOL)reset
{
    if(_appDelegate.serialManager.serialPort.path)
    {
        [self.console_label setStringValue:[NSString stringWithFormat:@"Console: %@", message]];
    
        if(reset)
        {
            [self performSelector:@selector(resetConsoleMessage) withObject:nil afterDelay:5.0f];
        }
    }
    else
    {
        [self.console_label setStringValue:@"Console Connecting…"];
        [self performSelector:@selector(resetConsoleMessage) withObject:nil afterDelay:5.0f];
    }
}

-(void)resetConsoleMessage
{
    [self.console_label setStringValue:@"Console: Ready"];
}

/*
 
 //example [A2 00 03 07 04]
 //[cmd, dcc header, dcc address, option, data]
 
 Function 0 = [A2 00 03 07 10] : [A2 00 03 07 00]
 Function 1 = [A2 00 03 07 01] : [A2 00 03 07 00]
 Function 2 = [A2 00 03 07 02] : [A2 00 03 07 00]
 Function 3 = [A2 00 03 07 04] : [A2 00 03 07 00]
 Function 4 = [A2 00 03 07 08] : [A2 00 03 07 00]
 31
 
 Function 5 = [A2 00 03 08 01] : [A2 00 03 08 00]
 Function 6 = [A2 00 03 08 02] : [A2 00 03 08 00]
 Function 7 = [A2 00 03 08 04] : [A2 00 03 08 00]
 Function 8 = [A2 00 03 08 08] : [A2 00 03 08 00]
 15
 
 Function 9 = [A2 00 03 09 01] : [A2 00 03 09 00]
 Function 10 = [A2 00 03 09 02] : [A2 00 03 09 00]
 Function 11 = [A2 00 03 09 04] : [A2 00 03 09 00]
 Function 12 = [A2 00 03 09 08] : [A2 00 03 09 00]
 15
 
 Function 13 = [A2 00 03 15 01] : [A2 00 03 15 00] 1
 Function 14 = [A2 00 03 15 02] : [A2 00 03 15 00] 2
 Function 15 = [A2 00 03 15 04] : [A2 00 03 15 00] 4
 Function 16 = [A2 00 03 15 08] : [A2 00 03 15 00] 8
 Function 17 = [A2 00 03 15 10] : [A2 00 03 15 00] 16
 Function 18 = [A2 00 03 15 20] : [A2 00 03 15 00] 32
 Function 19 = [A2 00 03 15 40] : [A2 00 03 15 00] 64
 Function 20 = [A2 00 03 15 80] : [A2 00 03 15 00] 128
 255
 
 Function 21 = [A2 00 03 16 01] : [A2 00 03 16 00]
 Function 22 = [A2 00 03 16 02] : [A2 00 03 16 00]
 Function 23 = [A2 00 03 16 04] : [A2 00 03 16 00]
 Function 24 = [A2 00 03 16 08] : [A2 00 03 16 00]
 Function 25 = [A2 00 03 16 10] : [A2 00 03 16 00]
 Function 26 = [A2 00 03 16 20] : [A2 00 03 16 00]
 Function 27 = [A2 00 03 16 40] : [A2 00 03 16 00]
 Function 28 = [A2 00 03 16 80] : [A2 00 03 16 00]
 255

*/
- (NSManagedObjectContext *)managedObjectContext
{
    AppDelegate *delegate = (AppDelegate*)[NSApplication sharedApplication].delegate;
    return delegate.persistentContainer.viewContext;
}

-(Train*)currentLeadLocomotive
{
    if(_direction == kForward128)
    {
        return _currentConsist.lead_train;
    }
    else
    {
        return (_currentConsist.rear_train) ? _currentConsist.rear_train : _currentConsist.lead_train;
    }
}




@end











