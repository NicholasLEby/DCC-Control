//
//  NEMenuViewController.m
//  Command
//
//  Created by Nicholas Eby on 2/23/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import "NEMenuViewController.h"
//Controller
#import "ViewController.h"
#import "ConsistViewController.h"
//App Delegate
#import "AppDelegate.h"
//
#import "NENCECommand.h"
//Third Party
#import "ORSSerialPortManager.h"
#import "ORSSerialPort.h"
#import "ORSSerialRequest.h"


@interface NEMenuViewController () <NSWindowDelegate>

//UI
@property(nonatomic, strong) AppDelegate *appDelegate;
@property(nonatomic, strong) NSMutableArray *addedWindowControllers;
@property(nonatomic, strong) NSWindowController *currentWindowController;

@end

@implementation NEMenuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.appDelegate = (AppDelegate *)[NSApp delegate];
    
    //Init Array
    self.addedWindowControllers = [[NSMutableArray alloc] init];
    
    //Default UI
    self.control_button.enabled = NO;
    self.hardware_heightConstraint.constant = 24.0f;
    self.hardware_view.hidden = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serialPortWasOpened) name:@"kSerialPortWasOpened" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serialPortWasClosed) name:@"kSerialPortWasClosed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serialPortWasRemovedFromSystem) name:@"kSerialPortWasRemoved" object:nil];

    ushort number = 19;
    uint8_t upper = (uint8_t) (number >> 8);
    uint8_t lower = (uint8_t) (number & 0xff);
    
    NSLog(@"%d %d", upper, lower);
}


//------------------------------------------------------- Lifecycle -------------------------------------------------------//

-(void)viewDidAppear
{
    [super viewDidAppear];
    
    [self initSerial];
}

-(void)viewDidDisappear
{
    [super viewDidDisappear];
}





//------------------------------------------------------- UI -------------------------------------------------------//

-(IBAction)menuChanged:(id)sender
{
    //NSPopUpButton *button = (NSPopUpButton*)sender;
    
    if(_dcc_menu.indexOfSelectedItem != 0 && _serial_connections_menu.indexOfSelectedItem != 0 && _baud_menu.indexOfSelectedItem != 0)
    {
        self.connect_button.enabled = YES;
    }
    else
    {
        self.connect_button.enabled = NO;
    }
}

-(IBAction)newControlPanel:(id)sender
{
    NSLog(@"UI: Create new Control Panel");
    
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    
    NSWindowController *controllerWindow = [storyBoard instantiateControllerWithIdentifier:@"NEWindowController"];
    controllerWindow.window.delegate = self;
    controllerWindow.shouldCascadeWindows = YES;
    controllerWindow.window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    controllerWindow.window.titlebarAppearsTransparent = YES;
    controllerWindow.window.styleMask = controllerWindow.window.styleMask | NSFullSizeContentViewWindowMask;
    
    if([controllerWindow.contentViewController isKindOfClass:[ViewController class]])
    {
        //ViewController *vc = (ViewController*)controllerWindow.contentViewController;
    }
    
    //Add to Array to Retain
    [_addedWindowControllers addObject:controllerWindow];
    
    //Show Window
    [controllerWindow.window cascadeTopLeftFromPoint:NSMakePoint(20,20)];
    [controllerWindow showWindow:self];
    
    //Close Popover
    [_appDelegate togglePopover:nil];
}

-(IBAction)newConsistControlPanel:(id)sender
{
    NSLog(@"UI: Create new Consist Control Panel");
    
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    
    NSWindowController *controllerWindow = [storyBoard instantiateControllerWithIdentifier:@"NEConsistWindowController"];
    controllerWindow.window.delegate = self;
    controllerWindow.shouldCascadeWindows = YES;
    controllerWindow.window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    controllerWindow.window.titlebarAppearsTransparent = YES;
    controllerWindow.window.styleMask = controllerWindow.window.styleMask | NSFullSizeContentViewWindowMask;
    
    if([controllerWindow.contentViewController isKindOfClass:[ViewController class]])
    {
        //ViewController *vc = (ViewController*)controllerWindow.contentViewController;
    }
    
    //Add to Array to Retain
    [_addedWindowControllers addObject:controllerWindow];
    
    //Show Window
    [controllerWindow.window cascadeTopLeftFromPoint:NSMakePoint(20,20)];
    [controllerWindow showWindow:self];
    
    //Close Popover
    [_appDelegate togglePopover:nil];
}

-(IBAction)showManage:(id)sender
{
    [self performSegueWithIdentifier:@"Manage_Segue" sender:self];
}

-(IBAction)help:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"http://www.stackoverflow.com/"];
    
    if(![[NSWorkspace sharedWorkspace] openURL:url] )
    {
        NSLog(@"Failed to open url: %@",[url description]);
    }
    
    //Close Popover
    [_appDelegate togglePopover:nil];
}

-(IBAction)quit:(id)sender
{
    //Close Serial
    [self.appDelegate.serialManager closeSerial];
    
    #warning debug only
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"kFirstLaunch"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}


-(void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"Manage_Segue"])
    {
        [self.appDelegate togglePopover:nil];
    }
}


/*
-(void)windowDidBecomeMain:(NSNotification *)notification
{
    NSLog(@"UI: Window did become main");
    
    NSWindow *window = (NSWindow*)notification.object;
    NSWindowController *windowController = window.windowController;
    
    self.currentWindowController = windowController;
}

-(void)windowWillClose:(NSNotification *)notification
{
    NSLog(@"UI: Window will close");
    
    NSWindow *window = (NSWindow*)notification.object;
    NSWindowController *windowController = window.windowController;
    
    self.currentWindowController = nil;

    //Remove from Added Array
    if([_addedWindowControllers containsObject:windowController])
    {
        [_addedWindowControllers removeObject:windowController];
    }
}
*/






//------------------------------------------------------- Serial -------------------------------------------------------//

-(void)initSerial
{
    NSLog(@"Serial: init");
    
    //Get all Availble Ports
    NSArray *ports = [[ORSSerialPortManager sharedSerialPortManager] availablePorts];
    
    //Add all Availabe Ports to Popup Menu UI
    //Make sure to remove default items
    NSString *selected_title = _serial_connections_menu.selectedItem.title;
    
    for(ORSSerialPort *port in ports)
    {
        [_serial_connections_menu addItemWithTitle:port.path];
    }
    
    
    NSMenuItem *selected = [_serial_connections_menu itemWithTitle:selected_title];
    
    if(selected)
    {
        [_serial_connections_menu selectItem:selected];
    }
}



-(IBAction)openSerial:(id)sender
{
    if(_serial_connections_menu.indexOfSelectedItem == 0)
    {
        return;
    }
    
    NSArray *ports = [[ORSSerialPortManager sharedSerialPortManager] availablePorts];
    ORSSerialPort *port = [ports objectAtIndex:_serial_connections_menu.indexOfSelectedItem-1];
    
    NSLog(@"Serial: open port (%@)", port.path);
    [_appDelegate.serialManager openSerialWithPath:port.path];
}

-(IBAction)closeSerial:(id)sender
{
    NSLog(@"Serial: close port");

    [_appDelegate.serialManager closeSerial];
}

-(void)serialPortWasOpened
{
    self.connect_button.image = [NSImage imageNamed:@"NSStatusAvailable"];
    self.connect_button.imagePosition = NSImageRight;
    self.connect_button.enabled = NO;
    self.connect_button.title = _appDelegate.serialManager.serialPort.name;
    
    self.quit_button.title = @"Close Port & Quit";
    self.control_button.enabled = YES;
    
    self.disconnect_button.enabled = YES;
    
    _serial_connections_menu.image = [NSImage imageNamed:@"NSStatusAvailable"];
    _serial_connections_menu.imagePosition = NSImageRight;

    self.dcc_menu.enabled = NO;
    self.serial_connections_menu.enabled = NO;
    self.baud_menu.enabled = NO;
    
    //Send a test command, if successful show alert
    
    //Command Helper
    NENCECommand *command = [[NENCECommand alloc] init];

    NSData *command_to_send = [command softwareVersion];

    //Block
    [_appDelegate.serialManager sendCommand:command_to_send withPacketResponseLength:3 andUserInfo:@"AA" andCallback:^(BOOL success, NSString *response)
     {
         
         self.hardware_heightConstraint.constant = 104.0f;
         self.hardware_view.hidden = NO;
         
         if(success)
         {
             [self.hardware_label setStringValue:[NSString stringWithFormat:@"Version: %@", response]];
         }
         else
         {
             [self.hardware_label setStringValue:[NSString stringWithFormat:@"Version: %@", response]];
         }
     }];
}

-(void)serialPortWasRemovedFromSystem
{
    [self serialRemoved];
}

-(void)serialPortWasClosed
{
    [self serialRemoved];
}

-(void)serialRemoved
{
    //Resets
    self.hardware_heightConstraint.constant = 24.0f;
    self.hardware_view.hidden = YES;
    
    self.connect_button.image = nil;
    self.connect_button.enabled = YES;
    self.connect_button.title = @"Connect";
    self.quit_button.title = @"Quit";
    self.control_button.enabled = NO;
    
    self.dcc_menu.enabled = YES;
    self.serial_connections_menu.enabled = YES;
    self.baud_menu.enabled = YES;
    
    self.disconnect_button.enabled = NO;
    
    NSArray *added = [NSArray arrayWithArray:_addedWindowControllers];
    
    for(NSWindowController *controller in added)
    {
        NSLog(@"%@", controller);
        [controller.window close];
    }
}




-(IBAction)softReset:(id)sender
{
    //Command Helper
    NENCECommand *command = [[NENCECommand alloc] init];
    
    NSData *command_to_send = [command softResetCommandStation];
    
    //Block
    [_appDelegate.serialManager sendCommand:command_to_send withPacketResponseLength:0 andUserInfo:@"A8" andCallback:^(BOOL success, NSString *response)
     {
         if(success)
         {
             NSLog(@"Success");
         }
         else
         {
             NSLog(@"Fail");
         }
     }];
}





@end
