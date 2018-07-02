//
//  NEStopButton.m
//  Command
//
//  Created by Nicholas Eby on 6/29/18.
//  Copyright © 2018 Nicholas Eby. All rights reserved.
//

#import "NEStopButton.h"

@implementation NEStopButton

-(void)awakeFromNib
{
    NSColor *color = [NSColor whiteColor];
    NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedTitle]];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
    [self setAttributedTitle:colorTitle];
    
    //self.bezelStyle = NSBezelStyleInline;
    self.bordered = NO;
    self.layer.cornerRadius = 6.0f;
    self.wantsLayer = YES;
    self.layer.backgroundColor = NSColor.redColor.CGColor;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    //self.bezelStyle = NSBezelStyleInline;
    self.bordered = NO;
    self.layer.cornerRadius = 6.0f;
    self.wantsLayer = YES;
    self.layer.backgroundColor = NSColor.redColor.CGColor;
}



@end
