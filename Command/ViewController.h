//
//  ViewController.h
//  Command
//
//  Created by Nicholas Eby on 2/13/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//
#import "NETrain.h"
#import "NEMenuViewController.h"

@class ORSSerialPort;

typedef NS_ENUM(NSUInteger, Locomotive_Control_Direction)
{
    kReverse128,
    kForward128
};


@interface ViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>
{
    
}

//Passed Serail Port for
@property(nonatomic, strong) NSString *serialPath;
@property(nonatomic, strong) ORSSerialPort *serialPort;
@property(nonatomic, strong) NEMenuViewController *mvc;


//UI
@property(nonatomic, weak) IBOutlet NSButton *horn_button;
@property(nonatomic, weak) IBOutlet NSButton *bell_button;
@property(nonatomic, weak) IBOutlet NSButton *headlight_buton;
@property(nonatomic, weak) IBOutlet NSButton *program_button;
@property(nonatomic, weak) IBOutlet NSTextField *console_label;
@property(nonatomic, weak) IBOutlet NSTextField *consoleLeftTop_label;
@property(nonatomic, weak) IBOutlet NSTextField *consoleLeftBottom_label;
@property(nonatomic, weak) IBOutlet NSImageView *console_headlight_imageView;
@property(nonatomic, weak) IBOutlet NSImageView *console_bell_imageView;
@property(nonatomic, weak) IBOutlet NSImageView *console_horn_imageView;
@property(nonatomic, weak) IBOutlet NSTextField *smph_label;
@property(nonatomic, weak) IBOutlet NSTableView *tableView;
@property(nonatomic, weak) IBOutlet NSSlider *speed_slider;
@property(nonatomic, weak) IBOutlet NSTextField *speed_slider_textField;
@property(nonatomic, weak) IBOutlet NSSegmentedControl *speed_segmentedControl;
@property(nonatomic, weak) IBOutlet NSTextField *speed_mid_label;
@property(nonatomic, weak) IBOutlet NSTextField *speed_max_label;


//User Control
-(IBAction)function:(id)sender;
-(IBAction)changeDirection:(id)sender;
-(IBAction)emergency:(id)sender;


-(void)updateStatus;
-(void)loadTrain:(NETrain*)loadedTrain;


@end

