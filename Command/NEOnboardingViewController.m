//
//  NEOnboardingViewController.m
//  Command
//
//  Created by Nicholas Eby on 11/28/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import "NEOnboardingViewController.h"
//App Delegate
#import "AppDelegate.h"

@interface NEOnboardingViewController ()

@end

@implementation NEOnboardingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
}


-(IBAction)showMenu:(id)sender
{
    //Show Popover
    AppDelegate *delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    [delegate showPopoverFromOnboarding];
    
    //Save Launch Status
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kFirstLaunch"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //Close this Window
    [[[self view] window] close];
}


@end
