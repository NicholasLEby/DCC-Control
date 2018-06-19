//
//  ViewController.m
//  Command
//
//  Created by Nicholas Eby on 2/13/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import "ViewController.h"
#import "NETrain.h"
#import "NEFunction.h"
#import "NEFunctionCell.h"
#import "NECommand.h"
#import "NEProgram.h"
#import "NESerialManager.h"

NSInteger const min_speed = 0;
NSInteger const max_speed = 128;
NSInteger const default_headlight_tag = 0;
NSInteger const default_bell_tag = 1;
NSInteger const default_horn_tag = 2;

@interface ViewController ()
{
    //Data
    NSArray *functions;
    
    //Helpers
    NECommand *command;
    
    //State
    NETrain *currentTrain;
    NSInteger speed;
    NSInteger direction;
    BOOL keyDown; //for tracking key state
}

@property(nonatomic, strong)  NESerialManager *serialManager;

@end

@implementation ViewController
@synthesize serialPath = _serialPath, serialPort = _serialPort;

- (void)viewDidLoad
{
    [super viewDidLoad];

    //State Defaults
    currentTrain = nil;
    speed = 0;
    direction = kForward128;
    keyDown = NO;
    
    //Command Helper
    command = [[NECommand alloc] init];
    
    _serialManager = [[NESerialManager alloc] init];
    [self.view.window setTitle:[NSString stringWithFormat:@"Command (%@)", _serialPath]];
    
    //Inits
    [self initDefaultData];
    [self initUI];
}

-(void)viewDidAppear
{
    [super viewDidAppear];
    
    _serialManager.serialPort = _serialPort;
}







//---------------------------------- UI ----------------------------------//

-(void)initDefaultData
{
    //Create Default Function Set
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
    
    functions = [NSArray arrayWithArray:temp];
    [self.tableView reloadData];
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
    self.speed_slider_textField.stringValue = [NSString stringWithFormat:@"%ld", speed];
    self.speed_slider.altIncrementValue = 1;
    self.speed_slider.minValue = min_speed;
    self.speed_slider.maxValue = max_speed;
    self.speed_slider.integerValue = speed;
    
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
    NSString *name = [NSString stringWithFormat:@"%@ (%@)", (currentTrain) ? currentTrain.name : @"Default", (currentTrain) ? [currentTrain dcc_short_string] : @"003"];
    
    NSString *speed_string = [NSString stringWithFormat:@"Speed: %@ %ld", (direction == 0) ? @"Reverse" : @"Forward", speed];
    
    self.consoleLeftTop_label.stringValue = name;
    self.consoleLeftBottom_label.stringValue = speed_string;
    self.speed_slider.integerValue = speed;
    
    for(NEFunction *function in functions)
    {
        if(function.key == 0)
        {
            self.console_headlight_imageView.hidden = !function.on;
        }
        else if(function.key == 1)
        {
            self.console_bell_imageView.hidden = !function.on;
        }
        else if(function.key == 2)
        {
            self.console_horn_imageView.hidden = !function.on;
        }
    }
}


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
             //here add yuor own code to open the file
             
         }
         
     }];
}

-(void)loadTrain:(NETrain*)loadedTrain
{
    currentTrain = loadedTrain;
    
    [self.tableView reloadData];
    
    if(currentTrain.programs)
    {
        self.program_button.hidden = NO;
    }
    
    //Update Status
    [self updateStatusWindow];
}

-(void)refreshUI
{
    //Update Hard Buttons
    
    NSArray *hard_buttons = @[_horn_button, _bell_button, _headlight_buton];
    
    for(NSButton *button in hard_buttons)
    {
        for(NEFunction *function in functions)
        {
            if(function.key == button.tag)
            {
                button.state = function.on;
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
    
    NEFunction *function = [functions objectAtIndex:button.tag];
    function.on = !function.on;

    NSLog(@"%ld - %d", (long)function.key, function.on);
    
    //Execute Command
    NSInteger address = (currentTrain) ? currentTrain.dcc_short : 03;
    NSData *command_to_send = [command locomotiveFunctionCommand:address andFunctionKey:function];
   
    //Update Console
    [self showConsoleMessage:[NSString stringWithFormat:@"Sending %@", command_to_send] withReset:NO];

    //Block
    [_serialManager sendCommand:command_to_send withPacketResponseLength:1 andUserInfo:@"A2" andCallback:^(BOOL success, NSString *response)
     {
         if(success)
         {
             [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:YES];
         }
         else
         {
             function.on = !function.on; //revert to last state
             [self showConsoleMessage:[NSString stringWithFormat:@"%@ %@", response, command_to_send] withReset:NO];
         }
         
         //Update UI
         [self refreshUI];
     }];
}

-(IBAction)changeDirection:(id)sender
{
    NSSegmentedControl *segmented_control = (NSSegmentedControl*)sender;
    
    if(segmented_control.selectedSegment == direction) return;
    
    NSInteger current_direction = direction;
    
    //Play Sound
    [[NSSound soundNamed:@"Tink"] play];
    
    direction = segmented_control.selectedSegment;
    speed = 0; //stop the train first. JMRI does +56 -> -56, I prefer +56 -> -0

    NSLog(@"Control Panel: Change Direction from %ld to %ld", current_direction, direction);
    
    //Execute Command
    NSInteger address = (currentTrain) ? currentTrain.dcc_short : 03;
    NSData *command_to_send = [command locomotiveSpeedCommandWithAddr:address andSpeed:speed andDirection:direction];
    
    //Update Console
    [self showConsoleMessage:[NSString stringWithFormat:@"Sending %@", command_to_send] withReset:NO];

    //Block
    [_serialManager sendCommand:command_to_send withPacketResponseLength:1 andUserInfo:@"A2" andCallback:^(BOOL success, NSString *response)
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
    speed = 0;
    
    NSLog(@"Control Panel: Emergency Stop!");
    
    //Execute Command
    NSInteger address = (currentTrain) ? currentTrain.dcc_short : 03;
    NSData *command_to_send = [command locomotiveEmergencyStopCommandWithAddr:address andDirection:direction];
    
    //Update Console
    [self showConsoleMessage:[NSString stringWithFormat:@"Sending %@", command_to_send] withReset:NO];

    //Block
    [_serialManager sendCommand:command_to_send withPacketResponseLength:1 andUserInfo:@"A2" andCallback:^(BOOL success, NSString *response)
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
        speed = new_speed;
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
            speed = new_speed;
            
            //Execute Command
            NSInteger address = (currentTrain) ? currentTrain.dcc_short : 03;
            NSData *command_to_send = [command locomotiveSpeedCommandWithAddr:address andSpeed:speed andDirection:direction];
            
            //Update Console
            [self showConsoleMessage:[NSString stringWithFormat:@"Sending %@", command_to_send] withReset:NO];

            //Block
            [_serialManager sendCommand:command_to_send withPacketResponseLength:1 andUserInfo:@"A2" andCallback:^(BOOL success, NSString *response)
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
    
    
-(IBAction)consistCommand:(id)sender
{
    NSInteger tag = ((NSButton*)sender).tag;
    
    //Execute Command
    NSInteger address = (currentTrain) ? currentTrain.dcc_short : 03;
    
    NSData *command_to_send = [command locomotiveConsistCommandWithAddr:address andPosition:tag];
    
    //Update Console
    [self showConsoleMessage:[NSString stringWithFormat:@"Sending %@", command_to_send] withReset:NO];
    
    //Block
    [_serialManager sendCommand:command_to_send withPacketResponseLength:1 andUserInfo:@"A2" andCallback:^(BOOL success, NSString *response)
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
    return functions.count;
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
        NEFunction *function = [functions objectAtIndex:row];
        
        tableColumn.headerCell.title = @"DCC Functions";
        
        if ([tableColumn.identifier isEqualToString:@"FunctionColumn"])
        {
            //Label
            [cellView.label setStringValue:[NSString stringWithFormat:@"Function %ld", function.key]];
            
            //If current train meta, use function label
            if(currentTrain)
            {
                NSString *key = [NSString stringWithFormat:@"%ld", function.key];
                
                if([currentTrain.functions objectForKey:key])
                {
                    NSString *title = [NSString stringWithFormat:@"F%ld: %@", function.key, [currentTrain.functions objectForKey:key]];
                    [cellView.label setStringValue:title];
                }
            }
            
            //Button
            if(function.momentary) //key 2 is usually the horn, which needs a momentary button
            {
                [cellView.button sendActionOn:(NSEventMaskLeftMouseDown|NSEventMaskLeftMouseUp)];
            }
            else
            {
                [cellView.button sendActionOn:(NSEventMaskLeftMouseUp)];
            }
            
            [cellView.button setButtonType:NSButtonTypePushOnPushOff];
            [cellView.button setTitle:[NSString stringWithFormat:@"F%ld", (long)function.key]];
            [cellView.button setTag:function.key];
            [cellView.button setState:function.on];
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
    
    // Update the view, if already loaded.
}

-(void)resetUI
{
    //Defaults
    speed = 0;
    direction = kForward128;
    self.headlight_buton.tag = default_headlight_tag;
    self.bell_button.tag = default_bell_tag;
    self.horn_button.tag = default_horn_tag;
    
    //Clear
    currentTrain = nil;
    
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
    if(_serialPath)
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


@end











