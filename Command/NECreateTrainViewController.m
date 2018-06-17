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

@interface NECreateTrainViewController () <NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate>
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
    
    [self initTableView];
}

-(void)viewDidAppear
{
    [super viewDidAppear];
    
    [self getTrains];
}










//----------------------------------- CoreData -----------------------------------//


-(void)getTrains
{
    NSLog(@"Trains");
    
    NSManagedObjectContext * context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Train" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error = nil;
    trains = [context executeFetchRequest:fetchRequest error:&error];
    
    NSLog(@"%@", trains);
    
    if (trains == nil)
    {
        NSLog(@"Fetch Error");
    }
    
    [self.trains_tableView reloadData];
    [self.function_tableView reloadData];
    
    [self updateUI];
}

-(void)updateUI
{
    self.name_textField.stringValue = currentTrain.name;
    self.dcc_textField.stringValue = [NSString stringWithFormat:@"%d", currentTrain.dcc_address];
    
    //Short Address (1 - 127)
    if(currentTrain.dcc_address <= 127)
    {
        self.dcc_short_radio.state = NSControlStateValueOn;
        self.dcc_long_radio.state = NSControlStateValueOff;
    }
    //Long Address (128 - 9999)
    else if(currentTrain.dcc_address > 127 && currentTrain.dcc_address <= 9999)
    {
        self.dcc_short_radio.state = NSControlStateValueOff;
        self.dcc_long_radio.state = NSControlStateValueOn;
    }
    
    self.horn_textField.stringValue = [NSString stringWithFormat:@"%d", currentTrain.horn_function];
    self.headlight_textField.stringValue = [NSString stringWithFormat:@"%d", currentTrain.headlight_function];
    self.bell_textField.stringValue = [NSString stringWithFormat:@"%d", currentTrain.bell_function];
    
    self.delete_button.hidden = NO;
    
    self.container_view.hidden = NO;
    self.placeholder_view.hidden = YES;
    
    [self.function_tableView reloadData];
}

-(IBAction)new:(id)sender
{
    currentTrain = [NSEntityDescription insertNewObjectForEntityForName:@"Train" inManagedObjectContext:[self managedObjectContext]];
    
    currentTrain.name = @"untitled";
    
    [self updateUI];

    //
    self.delete_button.hidden = YES;
    
    [self.trains_tableView reloadData];
    [self.function_tableView reloadData];
    
    [_name_textField becomeFirstResponder];
    
    self.container_view.hidden = NO;
    self.placeholder_view.hidden = YES;
    
    //[self getTrains];
}


-(IBAction)save:(id)sender
{
    NSLog(@"Save Train");

    
    if([self validate])
    {
        
        NSError *error = nil;
        
        if ([[self managedObjectContext] save:&error] == NO)
        {
            NSAssert(NO, @"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
        }
        else
        {
            NSLog(@"Saved!");
        }
        
        //Clear
        currentTrain = nil;
        
        [self new:nil];
        
        [self getTrains];
    }
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

-(IBAction)delete:(id)sender
{
    if(currentTrain)
    {
        [[self managedObjectContext] deleteObject:currentTrain];

        NSError *error = nil;
        if (![[self managedObjectContext] save:&error])
        {
            NSLog(@"Error deleting train, %@", [error userInfo]);
        }
        else
        {
            currentTrain = nil;

            [self getTrains];
        }
        
    }
}





//----------------------------------- Table Views -----------------------------------//


-(void)initTableView
{
    
}


-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if(tableView.tag == 0)
    {
        return trains.count;
    }
    else
    {
        return 29;
    }
}


-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView.tag == 0)
    {
        if([[trains objectAtIndex:row] isKindOfClass:[Train class]])
        {
            Train *train = [trains objectAtIndex:row];
            
            //Set Coloumn Header
            [tableColumn.headerCell setStringValue:@"Trains"];
            
            NSTableCellView *cell = [tableView makeViewWithIdentifier:@"main_cell" owner:self];
            
            cell.textField.stringValue = (train.name) ? train.name : @"default";
            
            return cell;
        }
    }
    else
    {
        if([[tableColumn identifier] isEqualToString:@"main_column"])
        {
            //Set Coloumn Header
            [tableColumn.headerCell setStringValue:@"Function"];

            //Cell
            NSTableCellView *cell = [tableView makeViewWithIdentifier:@"main_cell" owner:self];
            
            cell.textField.stringValue = [NSString stringWithFormat:@"F%ld", (long)row];
            
            return cell;
        }
        else if([[tableColumn identifier] isEqualToString:@"second_column"])
        {
            //Set Coloumn Header
            [tableColumn.headerCell setStringValue:@"Description"];
            
            //Cell
            NSTableCellView *cell = [tableView makeViewWithIdentifier:@"main_cell" owner:self];
            cell.textField.editable = YES;
            cell.textField.delegate = self;
            cell.textField.tag = row;
            cell.textField.placeholderString = @"Default description here";
            
            if(currentTrain)
            {
                if(row == 0)
                {
                    cell.textField.stringValue = (currentTrain.function_0) ? currentTrain.function_0 : @"";
                }
                else if(row == 1)
                {
                    cell.textField.stringValue = (currentTrain.function_1) ? currentTrain.function_1 : @"";
                }
                else if(row == 2)
                {
                    cell.textField.stringValue = (currentTrain.function_2) ? currentTrain.function_2 : @"";
                }
                else if(row == 3)
                {
                    cell.textField.stringValue = (currentTrain.function_3) ? currentTrain.function_3 : @"";
                }
                else if(row == 4)
                {
                    cell.textField.stringValue = (currentTrain.function_4) ? currentTrain.function_4 : @"";
                }
                else
                {
                    cell.textField.stringValue = @"";
                }
            }
            
            return cell;
        }
    }
    
    
    NSTableCellView *cell = [tableView makeViewWithIdentifier:@"main_cell" owner:self];
    cell.textField.stringValue = @"fallback";
    return cell;
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *tableView = (NSTableView*)notification.object;
    
    if(tableView.tag == 0)
    {
        if(tableView.selectedRow < trains.count)
        {
            currentTrain = [trains objectAtIndex:tableView.selectedRow];
            
            [self updateUI];
        }
    }
    else
    {
        if(tableView.selectedCell)
        {
            NSTableCellView *cell = (NSTableCellView*)tableView.selectedCell;
            [cell.textField becomeFirstResponder];
        }
    }
}





//----------------------------------- TextField Delegate -----------------------------------//

/*
- (void)controlTextDidChange:(NSNotification *)notification
{
    NSTextField *textField = [notification object];

    NSLog(@"1");
}
 */

- (void)controlTextDidEndEditing:(NSNotification *)notification
{
    NSTextField *textField = [notification object];

    if ([textField resignFirstResponder])
    {
        if(textField.tag == 9991)
        {
            currentTrain.name = textField.stringValue;
        }
        else if(textField.tag == 9992)
        {
            currentTrain.dcc_address = textField.integerValue;
        }
        else if(textField.tag == 9993)
        {
            currentTrain.horn_function = textField.integerValue;
        }
        else if(textField.tag == 9994)
        {
            currentTrain.headlight_function = textField.integerValue;
        }
        else if(textField.tag == 9995)
        {
            currentTrain.bell_function = textField.integerValue;
        }
        else if(textField.tag == 0)
        {
            currentTrain.function_0 = textField.stringValue;
        }
        else if(textField.tag == 1)
        {
            currentTrain.function_1 = textField.stringValue;
        }
        else if(textField.tag == 2)
        {
            currentTrain.function_2 = textField.stringValue;
        }
        else if(textField.tag == 3)
        {
            currentTrain.function_3 = textField.stringValue;
        }
        else if(textField.tag == 4)
        {
            currentTrain.function_4 = textField.stringValue;
        }
        else if(textField.tag == 5)
        {
            currentTrain.function_5 = textField.stringValue;
        }
    }
}




//----------------------------------- Utilz -----------------------------------//

-(BOOL)validate
{
    if([currentTrain.name isEqualToString:@""])
    {
        [self alert:@"Name is required."];
        
        return NO;
    }
    else if(currentTrain.dcc_address == -1)
    {
        [self alert:@"DCC Address is required."];

        return NO;
    }
    else if(currentTrain.horn_function == -1)
    {
        [self alert:@"Horn Function is required."];

        return NO;
    }
    else if(currentTrain.headlight_function == -1)
    {
        [self alert:@"Headlight Function is required."];

        return NO;
    }
    else if(currentTrain.bell_function == -1)
    {
        [self alert:@"Bell Function is required."];

        return NO;
    }
    
    return YES;
}

-(void)alert:(NSString*)message
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Continue"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Required field missing"];
    [alert setInformativeText:message];
     [alert setAlertStyle:NSAlertStyleInformational];
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode)
    {
        //
    }];
}

- (NSManagedObjectContext *)managedObjectContext
{
    AppDelegate *delegate = (AppDelegate*)[NSApplication sharedApplication].delegate;
    return delegate.persistentContainer.viewContext;
}




@end
