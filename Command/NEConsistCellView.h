//
//  NEConsistCellView.h
//  Tester
//
//  Created by Eby, Nicholas on 7/5/18.
//  Copyright © 2018 Ulta Beauty. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NEConsistCellView : NSTableCellView

@property(nonatomic, weak) IBOutlet NSPopUpButton *position_popupButton;
@property(nonatomic, weak) IBOutlet NSPopUpButton *locomotives_popupButton;
@property(nonatomic, weak) IBOutlet NSPopUpButton *direction_popupButton;
@property(nonatomic, weak) IBOutlet NSButton *add_button;

@end
