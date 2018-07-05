//
//  AppDelegate.m
//  Command
//
//  Created by Nicholas Eby on 2/13/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
{
    NSEvent *mouseEventMonitor;
    NSButton *statusBarItemButton;
}

@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) NSPopover *popover;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    
    
    self.popover = [[NSPopover alloc] init];
    //ppopover.contentViewController
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    self.popover.contentViewController = [storyBoard instantiateControllerWithIdentifier:@"NEMenuPanelViewController"];
    self.popover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    
    
    self.statusItem = [statusBar statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.button.image = [NSImage imageNamed:@"StatusBarButtonImage"];
    self.statusItem.button.action = @selector(togglePopover:);

    statusBarItemButton = self.statusItem.button;
    
    
    mouseEventMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:(NSLeftMouseDownMask | NSRightMouseDownMask | NSOtherMouseDownMask) handler:^(NSEvent *event)
                          {
                              [self closePopover:nil];
                          }];
    
    //Onboarding
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"kFirstLaunch"])
    {
        NSWindowController *wc = [storyBoard instantiateControllerWithIdentifier:@"NEOnboardingWindowController"];
        [wc showWindow:self];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kFirstLaunch"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    
    //Serial Manager Singleton
    self.serialManager = [NESerialManager sharedManager];
}


-(void)showPopover:(id)sender
{
    NSButton *button = (NSButton*)sender;
    
    [self.popover showRelativeToRect:button.bounds ofView:button preferredEdge:NSMinYEdge];
}

-(void)closePopover:(id)sender
{
    [self.popover performClose:sender];
}

-(void)togglePopover:(id)sender
{
    if(_popover.shown)
    {
        [self closePopover:sender];
    }
    else
    {
        [self showPopover:sender];
    }
}

-(void)showPopoverFromOnboarding
{
    [self showPopover:statusBarItemButton];

}








#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer
{
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self)
    {
        if (_persistentContainer == nil)
        {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"trains"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error)
            {
                if (error != nil)
                {
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
    return self.persistentContainer.viewContext.undoManager;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    
    if (![context commitEditing])
    {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (!context.hasChanges)
    {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![context save:&error])
    {
        
        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result)
        {
            return NSTerminateCancel;
        }
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertSecondButtonReturn)
        {
            return NSTerminateCancel;
        }
    }
    
    return NSTerminateNow;
}












- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    
}


@end
