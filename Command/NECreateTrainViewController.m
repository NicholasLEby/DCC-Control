//
//  NECreateTrainViewController.m
//  Command
//
//  Created by Nicholas Eby on 11/28/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import "NECreateTrainViewController.h"
#import "Train+CoreDataClass.h"
#import "AppDelegate.h"

@interface NECreateTrainViewController () <NSTextFieldDelegate>
{
    NSArray *trains;
    Train *currentTrain;
}

@end

@implementation NECreateTrainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Defaults
    self.container_view.hidden = YES;
    self.placeholder_view.hidden = NO;
    
    self.managedObjectContext = [self managedObjectContext];
    
    NSLog(@"%@",_trains_tableView);
    NSLog(@"%d",_trains_tableView.numberOfSelectedRows);
    NSLog(@"%d",_trains_tableView.selectedRow);
    NSLog(@"%@",_trains_tableView.highlightedTableColumn);
}

-(void)viewDidAppear
{
    [super viewDidAppear];
    
    NSLog(@"%@",_trains_tableView);
    NSLog(@"%d",_trains_tableView.numberOfSelectedRows);
    NSLog(@"%d",_trains_tableView.selectedRow);
    NSLog(@"%@",_trains_tableView.highlightedTableColumn);

}

-(void)viewWillDisappear
{
    [super viewWillDisappear];
    
    //[self.managedObjectContext save:nil];
}




-(IBAction)new:(id)sender
{
    [self.arrayController add:nil];
    [self.name_textField becomeFirstResponder];
    self.container_view.hidden = NO;
    self.placeholder_view.hidden = YES;
}

-(IBAction)onSelection:(id)sender
{
    self.container_view.hidden = NO;
    self.placeholder_view.hidden = YES;
}














//----------------------------------- UI -----------------------------------//

-(IBAction)dccRadioChanged:(id)sender
{
    if(sender == _dcc_short_radio)
    {
        self.dcc_textField.placeholderString = @"3";
    }
    else
    {
        self.dcc_textField.placeholderString = @"3333";
    }
}











- (NSManagedObjectContext *)managedObjectContext
{
    AppDelegate *delegate = (AppDelegate*)[NSApplication sharedApplication].delegate;
    return delegate.persistentContainer.viewContext;
}




@end
