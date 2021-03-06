//
//  AppDelegate.h
//  Command
//
//  Created by Nicholas Eby on 2/13/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>
#import "NESerialManager.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
{

}

@property(nonatomic, strong) NESerialManager *serialManager;
@property (readonly, strong) NSPersistentContainer *persistentContainer;

//Public Methods
-(void)togglePopover:(id)sender;
-(void)showPopoverFromOnboarding;

@end

