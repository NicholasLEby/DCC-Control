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
//View
#import "NEConsistCellView.h"
//Third Party
#import "ORSSerialPortManager.h"
#import "ORSSerialPort.h"
#import "ORSSerialRequest.h"

NSInteger const consist_min_speed = 0;
NSInteger const consist_max_speed = 128;
NSInteger const default_consist_headlight_tag = 0;
NSInteger const default_consist_bell_tag = 1;
NSInteger const default_consist_horn_tag = 2;

@interface ConsistViewController () <NSWindowDelegate, NSTextFieldDelegate>

//Data
@property(nonatomic, strong) NSMutableArray *active_functions;
@property(nonatomic, strong) NSMutableArray *added_locomotives;
//Helpers
@property(nonatomic, strong) NENCECommand *command;
//State
@property(nonatomic) NSInteger consist_dcc_address;
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
    self.speed = 0;
    self.direction = kForward128;
    self.keyDown = NO;
    self.active_functions = [[NSMutableArray alloc] init];
    self.added_locomotives = [[NSMutableArray alloc] init];

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
                 [self resetConsistTrains];
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
    //Load Saved Trains
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Train" inManagedObjectContext:_managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects != nil)
    {
        NSMutableArray *temp = [NSMutableArray arrayWithArray:_savedTrains];
        [temp addObjectsFromArray:fetchedObjects];
        self.savedTrains = [NSArray arrayWithArray:temp];
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
    [alert setMessageText:@"Advanced Consist Builder"];
    [alert setInformativeText:@"Ensure your locomotive supports Advanced Consisting (CV19) before proceeding. Some locomotives will sound their horn twice when successfully writing to CV19."];
    [alert addButtonWithTitle:@"Done"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAccessoryView:_custom_view];
    [alert beginSheetModalForWindow:self.view.window
                      completionHandler:^(NSInteger result)
     {
         if(result == NSAlertFirstButtonReturn)
         {
             NSLog(@"Done");
             
             //Reloas function table
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
    self.consoleLeftTop_label.stringValue = [NSString stringWithFormat:@"Consist: %.3ld", (long)_consist_dcc_address];
    self.consoleSecond_label.stringValue = [self consistString];
    self.consoleLeftBottom_label.stringValue = [NSString stringWithFormat:@"Speed: %@ %ld", (_direction == 0) ? @"Reverse" : @"Forward", _speed];
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
    NSData *command_to_send = [_command locomotiveSpeedCommandWithAddr:_consist_dcc_address andSpeed:_speed andDirection:_direction];
    
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
    NSData *command_to_send = [_command locomotiveEmergencyStopCommandWithAddr:_consist_dcc_address andDirection:_direction];
    
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
            NSData *command_to_send = [_command locomotiveSpeedCommandWithAddr:_consist_dcc_address andSpeed:_speed andDirection:_direction];
            
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
    if(tableView.tag == 0)
    {
        return 29;
    }
    else
    {
        return _added_locomotives.count;
    }
}

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    if(tableView.tag == 0)
    {
        return 31.0f;
    }
    else
    {
        return 31.0f;
    }
}


-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView.tag == 0)
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
    else
    {
        Train *consist_train = [_added_locomotives objectAtIndex:row];
        
        NEConsistCellView *cell = [tableView makeViewWithIdentifier:@"NEConsistCellView" owner:self];
        
        //Add Button
        cell.add_button.tag = row;
        
        //Position Menu
        cell.position_popupButton.tag = row;
        
        [cell.position_popupButton removeAllItems];
        [cell.position_popupButton addItemsWithTitles:@[@"Lead", @"Other", @"Rear"]];
        cell.position_popupButton.autoenablesItems = NO;

        if(row == 0)
        {
            [[cell.position_popupButton itemAtIndex:0] setEnabled:YES];
            [[cell.position_popupButton itemAtIndex:1] setEnabled:NO];
            [[cell.position_popupButton itemAtIndex:2] setEnabled:NO];
        }
        else
        {
            [[cell.position_popupButton itemAtIndex:0] setEnabled:NO];
            [[cell.position_popupButton itemAtIndex:1] setEnabled:YES];
            [[cell.position_popupButton itemAtIndex:2] setEnabled:YES];
        }
        
        [cell.position_popupButton selectItemAtIndex:consist_train.consist_position];
        
        
        //Train Dropdown
        cell.locomotives_popupButton.tag = row;
        [cell.locomotives_popupButton removeAllItems];
        [cell.locomotives_popupButton addItemWithTitle:@"Select Locomotive"];

        for(Train *train in _savedTrains)
        {
            [cell.locomotives_popupButton addItemWithTitle:[NSString stringWithFormat:@"%@ (%ld)",train.name, (long)train.dcc_address]];
        }
        [[cell.locomotives_popupButton itemAtIndex:0] setEnabled:NO];

        
        if(consist_train.name && ![consist_train.name isEqualToString:@"Untitled"])
        {
            [cell.locomotives_popupButton selectItemWithTitle:[NSString stringWithFormat:@"%@ (%ld)",consist_train.name, (long)consist_train.dcc_address]];
        }
        
        //Direction Dropdown
        cell.direction_popupButton.tag = row;
        
        [cell.direction_popupButton selectItemAtIndex:consist_train.consist_direction];
        
        
        return cell;
    }
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return NO;
}





- (void)controlTextDidChange:(NSNotification *)notification
{
    NSTextField *textField = [notification object];

    for(Train *train in _savedTrains)
    {
        if(train.dcc_address == _consist_textField.integerValue)
        {
            self.consistWarning_textField.hidden = NO;
            return;
        }
    }
    
    self.consist_dcc_address = textField.integerValue;
    self.consistWarning_textField.hidden = YES;
}

-(IBAction)positionChanged:(id)sender
{
    NSPopUpButton *button = (NSPopUpButton*)sender;
    Train *consist_train = [_added_locomotives objectAtIndex:button.tag];
    consist_train.consist_position = button.indexOfSelectedItem;
}

-(IBAction)locomotiveChanged:(id)sender
{
    NSPopUpButton *button = (NSPopUpButton*)sender;
    
    if(button.indexOfSelectedItem == 0)
    {
        return;
    }
    
    Train *consist_train = [_added_locomotives objectAtIndex:button.tag];
    Train *train = [_savedTrains objectAtIndex:(button.indexOfSelectedItem)-1];
    
    consist_train.name = train.name;
    consist_train.dcc_address = train.dcc_address;
}

-(IBAction)directionChanged:(id)sender
{
    NSPopUpButton *button = (NSPopUpButton*)sender;
    Train *consist_train = [_added_locomotives objectAtIndex:button.tag];
    consist_train.consist_direction = button.indexOfSelectedItem;
}



-(IBAction)addLocomotive:(id)sender
{
    [[_consist_textField window] makeFirstResponder:nil];

    if(_consist_textField.stringValue == nil || [_consist_textField.stringValue isEqualToString:@""])
    {
        [self showErrorMessage:@"Consist address can't be empty!"];
        return;
    }
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Train" inManagedObjectContext:_managedObjectContext];
    Train *consist_train = [[Train alloc] initWithEntity:entity insertIntoManagedObjectContext:nil];
    consist_train.consist_position = 0;
    consist_train.consist_direction = 0;

    [_added_locomotives addObject:consist_train];
    [_consist_tableView reloadData];
    [_consist_tableView scrollToEndOfDocument:nil];
}

-(IBAction)programLocomotive:(id)sender
{
    NSButton *button = (NSButton*)sender;
    Train *consist_train = [_added_locomotives objectAtIndex:button.tag];

    if(consist_train.name == nil)
    {
        [self showErrorMessage:@"You must select a locomotive!"];
        return;
    }
    
    NSLog(@"add Position: %ld  Name: %@  Address: %ld  Direction: %ld  Consist: %ld",(long)consist_train.consist_position, consist_train.name,(long) (long)consist_train.dcc_address,(long) (long)consist_train.consist_direction, (long)_consist_dcc_address);
    
    
    //Execute Command
    NSData *command_to_send = [_command locomotiveConsistCommandWithAddr:consist_train.dcc_address consistNumber:_consist_dcc_address andDirection:consist_train.consist_direction];
    
    //Update Console
    [self showConsoleMessage:[NSString stringWithFormat:@"Sending %@", command_to_send] withReset:NO];
    
    //Block
    [_appDelegate.serialManager sendCommand:command_to_send withPacketResponseLength:1 andUserInfo:@"AE" andCallback:^(BOOL success, NSString *response)
     {
         if(success)
         {
             [button setTitle:@"Added!"];
             
             //self.currentConsist.lead_train = consist_train;
             
             [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:YES];
         }
         else
         {
             [button setTitle:@"Error"];
             [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:NO];
         }
         
         //Refresh UI
         [self refreshUI];
     }];
}











//---------------------------------- Utilz ----------------------------------//


- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
}

-(void)resetUI
{
    //Defaults
    self.consist_dcc_address = NSNotFound;
    self.speed = 0;
    self.direction = kForward128;
    self.headlight_buton.tag = default_consist_headlight_tag;
    self.bell_button.tag = default_consist_bell_tag;
    self.horn_button.tag = default_consist_horn_tag;
    
    
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

-(void)resetConsistTrains
{
    for(Train *consist_train in _added_locomotives)
    {
        //Execute Command
        NSData *command_to_send = [self.command locomotiveResetConsistCommandWithAddr:consist_train.dcc_address];
        
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
        
    #warning intentional delay
        [NSThread sleepForTimeInterval:1.0];
    }
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
        return [_added_locomotives firstObject];
    }
    else
    {
        Train *train = [_added_locomotives lastObject];
        
        if(train.consist_position == 2)
        {
            return train;
        }
        else
        {
            return [_added_locomotives firstObject];
        }
    }
}

-(NSString*)consistString
{
    NSString *string = @"";
    
    NSMutableArray *temp = [NSMutableArray arrayWithArray:_added_locomotives];
    
    if(_direction == kForward128)
    {
        string = @"< ";
    }
    
    for(int i = 0; i < temp.count; i++)
    {
        Train *train = [temp objectAtIndex:i];
        
        string = [string stringByAppendingString:[NSString stringWithFormat:@"%@", train.name]];
        
        if(i < (temp.count-1))
        {
            string = [string stringByAppendingString:@"  "];
        }
    }
                  
    if(_direction == kReverse128)
    {
        string = [string stringByAppendingString:@" >"];
    }
    
    return string;
}

@end











