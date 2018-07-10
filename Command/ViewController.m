//
//  ViewController.m
//  Command
//
//  Created by Nicholas Eby on 2/13/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import "ViewController.h"
#import "NEFunctionCell.h"
#import "NENCECommand.h"
#import "NESerialManager.h"
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

NSInteger const min_speed = 0;
NSInteger const max_speed = 128;
NSInteger const default_headlight_tag = 0;
NSInteger const default_bell_tag = 1;
NSInteger const default_horn_tag = 2;

@interface ViewController ()

//Data
@property(nonatomic, strong) NSArray *functions;
@property(nonatomic, strong) NSMutableArray *active_functions;
//Helpers
@property(nonatomic, strong) NENCECommand *command;
//State
@property(nonatomic, strong) Train *currentTrain;
@property(nonatomic) NSInteger speed;
@property(nonatomic) NSInteger direction;
@property(nonatomic) BOOL keyDown; //for tracking key state
//
@property(nonatomic, strong) AppDelegate *appDelegate;
@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong) NSArray *savedTrains;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    //State Defaults
    self.currentTrain = nil;
    self.speed = 0;
    self.direction = kForward128;
    self.keyDown = NO;
    [self.saved_popUpButton removeAllItems];
    self.active_functions = [[NSMutableArray alloc] init];
    
    self.appDelegate = (AppDelegate *)[NSApp delegate];
    self.managedObjectContext = [self managedObjectContext];

    //Command Helper
    self.command = [[NENCECommand alloc] init];
    
    [self.view.window setTitle:[NSString stringWithFormat:@"Command (%@)", _appDelegate.serialManager.serialPort.path]];
    
    //Inits
    [self initDefaultData];
    [self initUI];
}

-(void)viewDidAppear
{
    [super viewDidAppear];

}







//---------------------------------- UI ----------------------------------//

-(void)initDefaultData
{
    //Create Default Function Set (this will create a managed object but not insert into moc)
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Train" inManagedObjectContext:_managedObjectContext];
    Train *default_train = [[Train alloc] initWithEntity:entity insertIntoManagedObjectContext:nil];
    default_train.name = @"Default";
    default_train.dcc_address = 3;
    default_train.headlight_function = 0;
    default_train.bell_function = 1;
    default_train.horn_function = 2;
    
    self.savedTrains = [NSArray arrayWithObject:default_train];
    
    self.currentTrain = [_savedTrains firstObject];
    
    /*
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    
    for(int i = 0; i < 29; i++)
    {
        NEFunction *function = [[NEFunction alloc] initWithKey:i];
        
        if(i == default_horn_tag)
        {
            function.momentary = YES;
        }
        
        [temp addObject:function];
    }
    
    self.functions = [NSArray arrayWithArray:temp];
    [self.tableView reloadData];
    */
    
    
    
    //Load Saved Trains
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
            [self.saved_popUpButton addItemWithTitle:name];
        }
    }
    else
    {
        [self.saved_popUpButton addItemWithTitle:@"Default (003)"];
    }
}

-(void)initUI
{
    //Set Default Hard Button Tags & Event Handelers
    self.headlight_buton.tag = default_headlight_tag;
    self.headlight_buton.keyEquivalent = [NSString stringWithFormat:@"%ld",(long)default_headlight_tag];
    self.headlight_buton.toolTip = [NSString stringWithFormat:@"toolip"];
    
    self.bell_button.tag = default_bell_tag;
    self.bell_button.keyEquivalent = [NSString stringWithFormat:@"%ld",(long)default_bell_tag];
    
    self.horn_button.tag = default_horn_tag;
    self.horn_button.keyEquivalent = [NSString stringWithFormat:@"%ld",(long)default_horn_tag];
    
    //Speed Slider
    self.speed_slider.altIncrementValue = 1;
    self.speed_slider.minValue = min_speed;
    self.speed_slider.maxValue = max_speed;
    self.speed_slider.integerValue = _speed;
    
    //Direction Segmented Control
    self.speed_segmentedControl.selectedSegment = 1;
    
    //Speed Labels
    self.speed_mid_label.stringValue = [NSString stringWithFormat:@"%ld", max_speed / 2];
    self.speed_max_label.stringValue = [NSString stringWithFormat:@"%ld", max_speed];
    
    //Make sure the horn button fires on mouse up and down (momentary)
    [_horn_button sendActionOn:(NSEventMaskLeftMouseDown|NSEventMaskLeftMouseUp)];
    
    //Update Status
    [self updateStatusWindow];
    [self showConsoleMessage:@"Connected" withReset:YES];
}

-(void)updateStatusWindow
{
    NSString *name = [NSString stringWithFormat:@"%@ (%.3d)", _currentTrain.name, _currentTrain.dcc_address];
    
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

-(IBAction)savedTrainSelected:(id)sender
{
    NSInteger selectedIndex = self.saved_popUpButton.indexOfSelectedItem;
    
    Train *selected_train = [_savedTrains objectAtIndex:selectedIndex];
    
    [self loadTrain:selected_train];
}


/*
-(IBAction)showPanel:(id)sender
{

    //this gives you a copy of an open file dialogue
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    openPanel.title = @"Choose a Train Metadata file";
    openPanel.showsResizeIndicator = YES;
    openPanel.showsHiddenFiles = NO;
    openPanel.canChooseDirectories = NO;
    openPanel.canCreateDirectories = NO;
    openPanel.allowsMultipleSelection = NO;
    openPanel.allowedFileTypes = @[@"plist"];
    openPanel.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
    openPanel.titlebarAppearsTransparent = YES;
    openPanel.styleMask = openPanel.styleMask | NSFullSizeContentViewWindowMask;
    
    [openPanel beginSheetModalForWindow:self.view.window
                      completionHandler:^(NSInteger result)
     {
         
         //if the result is NSOKButton
         //the user selected a file
         if (result == NSModalResponseOK)
         {
             //get the selected file URLs
             NSURL *selection = openPanel.URLs[0];
             
             //finally store the selected file path as a string
             NSString *path = [[selection path] stringByResolvingSymlinksInPath];
             
             NSDictionary *theDict = [NSDictionary dictionaryWithContentsOfFile:path];
             
             NETrain *train = [[NETrain alloc] init];
             [train loadFromDict:theDict];
             
             
             NSLog(@"%@", theDict);
             [self loadTrain:train];
         }
         
     }];
}
*/

-(void)loadTrain:(Train*)loadedTrain
{
    self.currentTrain = loadedTrain;
    
    [self.tableView reloadData];
        
    //Update Status
    [self updateStatusWindow];
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
    NSData *command_to_send = [_command locomotiveFunctionCommand:_currentTrain.dcc_address andFunctionKey:function_number andFunctionState:state];
   
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
    NSData *command_to_send = [_command locomotiveSpeedCommandWithAddr:_currentTrain.dcc_address andSpeed:_speed andDirection:_direction];
    
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
    NSData *command_to_send = [_command locomotiveEmergencyStopCommandWithAddr:_currentTrain.dcc_address andDirection:_direction];
    
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
    
    if(new_speed < max_speed)
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
        
        if(new_speed < max_speed)
        {
            self.speed = new_speed;
            
            //Execute Command
            NSData *command_to_send = [_command locomotiveSpeedCommandWithAddr:_currentTrain.dcc_address andSpeed:_speed andDirection:_direction];
            
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
    
//---------------------------------- Keyboard Events ----------------------------------//

/*
- (void)keyDown:(NSEvent *)event
{
    NSLog(@"Control Panel: Key Down (%@)", event);
    
    if(!keyDown)
    {
        if(event.keyCode == 19)
        {
            NSButton *dummy_button = [[NSButton alloc] init];
            dummy_button.tag = 2;
            [self function:dummy_button];
        }
    }
    
    keyDown = YES;
}

-(void)keyUp:(NSEvent *)event
{
    NSLog(@"Control Panel: Key Up (%@)", event);
    
    if(keyDown)
    {
        if(event.keyCode == 19)
        {
            NSButton *dummy_button = [[NSButton alloc] init];
            dummy_button.tag = 2;
            [self function:dummy_button];
        }
    }
    
    keyDown = NO;
}
 */
































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
            
            if(row == 0) { function_label = _currentTrain.function0; }
            else if(row == 1) { function_label = _currentTrain.function1; }
            else if(row == 2) { function_label = _currentTrain.function2; }
            else if(row == 3) { function_label = _currentTrain.function3; }
            else if(row == 4) { function_label = _currentTrain.function4; }
            else if(row == 5) { function_label = _currentTrain.function5; }
            else if(row == 6) { function_label = _currentTrain.function6; }
            else if(row == 7) { function_label = _currentTrain.function7; }
            else if(row == 8) { function_label = _currentTrain.function8; }
            else if(row == 9) { function_label = _currentTrain.function9; }
            else if(row == 10) { function_label = _currentTrain.function10; }
            else if(row == 11) { function_label = _currentTrain.function11; }
            else if(row == 12) { function_label = _currentTrain.function12; }
            else if(row == 13) { function_label = _currentTrain.function13; }
            else if(row == 14) { function_label = _currentTrain.function14; }
            else if(row == 15) { function_label = _currentTrain.function15; }
            else if(row == 16) { function_label = _currentTrain.function16; }
            else if(row == 17) { function_label = _currentTrain.function17; }
            else if(row == 18) { function_label = _currentTrain.function18; }
            else if(row == 19) { function_label = _currentTrain.function19; }
            else if(row == 20) { function_label = _currentTrain.function20; }
            else if(row == 21) { function_label = _currentTrain.function21; }
            else if(row == 22) { function_label = _currentTrain.function22; }
            else if(row == 23) { function_label = _currentTrain.function23; }
            else if(row == 24) { function_label = _currentTrain.function24; }
            else if(row == 25) { function_label = _currentTrain.function25; }
            else if(row == 26) { function_label = _currentTrain.function26; }
            else if(row == 27) { function_label = _currentTrain.function27; }
            else if(row == 28) { function_label = _currentTrain.function28; }

            
            NSString *title = [NSString stringWithFormat:@"F%@: %@", function_number, function_label];
            [cellView.label setStringValue:title];
        
            
            //Button
            if(function_number.integerValue == _currentTrain.horn_function) //key 2 is usually the horn, which needs a momentary button
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
    self.headlight_buton.tag = default_headlight_tag;
    self.bell_button.tag = default_bell_tag;
    self.horn_button.tag = default_horn_tag;
    
    //Clear
    self.currentTrain = nil;
    
    [self initDefaultData]; //reset data
    [self refreshUI];
    [self updateStatusWindow];
}

-(void)showSpeedWarning
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Speed warning!"];
    [alert setInformativeText:[NSString stringWithFormat:@"You are currently at the max speed of: %ld", max_speed]];
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

@end











