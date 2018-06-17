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
//App Delegate
#import "AppDelegate.h"
//
#import "NETrain.h"
//Third Party
#import "ORSSerialPortManager.h"
#import "ORSSerialPort.h"
#import "ORSSerialRequest.h"

@interface NEMenuViewController () <ORSSerialPortDelegate, NSWindowDelegate>
{

}

//UI
@property(nonatomic, strong) NSMutableArray *addedWindowControllers;
@property(nonatomic, strong) NSWindowController *currentWindowController;
//Serial
@property(nonatomic, strong)  ORSSerialPort *serialPort;



@end

@implementation NEMenuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    //Init Array
    self.addedWindowControllers = [[NSMutableArray alloc] init];
    
    //Default UI
    self.control_button.enabled = NO;
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
    NSPopUpButton *button = (NSPopUpButton*)sender;
    
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
    controllerWindow.window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
    controllerWindow.window.titlebarAppearsTransparent = YES;
    controllerWindow.window.styleMask = controllerWindow.window.styleMask | NSFullSizeContentViewWindowMask;
    
    if([controllerWindow.contentViewController isKindOfClass:[ViewController class]])
    {
        ViewController *vc = (ViewController*)controllerWindow.contentViewController;
        vc.mvc = self;
        vc.serialPath = _serialPort.path;
        vc.serialPort = _serialPort;
    }
    
    //Add to Array to Retain
    [_addedWindowControllers addObject:controllerWindow];
    
    //Show Window
    [controllerWindow.window cascadeTopLeftFromPoint:NSMakePoint(20,20)];
    [controllerWindow showWindow:self];
    
    //Close
    AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
    [appDelegate togglePopover:nil];
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
}

-(IBAction)quit:(id)sender
{
    //Maybe show alert here about closing serial first, or just auto close it
    if(_serialPort.isOpen)
    {
        [_serialPort close];
    }
    
    #warning debug only
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"kFirstLaunch"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}


-(void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"Manage_Segue"])
    {
        //Close
        AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
        [appDelegate togglePopover:nil];
    }
}



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







//------------------------------------------------------- Serial -------------------------------------------------------//

-(void)initSerial
{
    NSLog(@"Serial: init");
    
    //Get all Availble Ports
    NSArray *ports = [[ORSSerialPortManager sharedSerialPortManager] availablePorts];
    
    //Add all Availabe Ports to Popup Menu UI
    //Make sure to remove default items
    for(ORSSerialPort *port in ports)
    {
        [_serial_connections_menu addItemWithTitle:port.path];
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
    
    self.serialPort = [ORSSerialPort serialPortWithPath:port.path];
    self.serialPort.baudRate = @19200;
    self.serialPort.delegate = self;
    //self.serialPort.parity = ORSSerialPortParityNone;
    //self.serialPort.numberOfStopBits = 1;
    //port.usesRTSCTSFlowControl = YES;
    
    [_serialPort open];
}

-(IBAction)closeSerial:(id)sender
{
    NSLog(@"Serial: close port");

    [_serialPort close];
}

-(void)serialPortWasOpened:(ORSSerialPort *)serialPort
{
    NSLog(@"Serial: port opened (%@)", serialPort.path);

    self.connect_button.image = [NSImage imageNamed:@"NSStatusAvailable"];
    self.connect_button.imagePosition = NSImageRight;
    self.connect_button.enabled = NO;
    self.connect_button.title = serialPort.name;
    self.quit_button.title = @"Close Port & Quit";
    self.control_button.enabled = YES;
    
    self.disconnect_button.enabled = YES;
    
    _serial_connections_menu.image = [NSImage imageNamed:@"NSStatusAvailable"];
    _serial_connections_menu.imagePosition = NSImageRight;

}

-(void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort
{
    NSLog(@"Serial: port was removed from system (%@)", serialPort.path);

    self.connect_button.image = nil;
    self.connect_button.enabled = YES;
    self.connect_button.title = @"Connect";
    self.quit_button.title = @"Quit";
    self.control_button.enabled = NO;

    self.disconnect_button.enabled = NO;
}

-(void)serialPortWasClosed:(ORSSerialPort *)serialPort
{
    NSLog(@"Serial: port was closed (%@)", serialPort.path);

    self.connect_button.image = nil;
    self.connect_button.enabled = YES;
    self.connect_button.title = @"Connect";
    self.quit_button.title = @"Quit";
    self.control_button.enabled = NO;

    self.disconnect_button.enabled = NO;
}






@end
