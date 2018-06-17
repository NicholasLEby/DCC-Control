//
//  NETrackPadView.m
//  Command
//
//  Created by Nicholas Eby on 3/3/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import "NETrackPadView.h"

@implementation NETrackPadView

- (void)drawRect:(NSRect)dirtyRect
{
    
    NSRect frameRect = [self bounds];
    
    
    if(dirtyRect.size.height < frameRect.size.height)
        return;
    NSRect newRect = NSMakeRect(dirtyRect.origin.x+2, dirtyRect.origin.y+2, dirtyRect.size.width-3, dirtyRect.size.height-3);
    
    NSBezierPath *textViewSurround = [NSBezierPath bezierPathWithRoundedRect:newRect xRadius:5 yRadius:5];
    [textViewSurround setLineWidth:1.0f];
    [[NSColor colorWithWhite:0.7f alpha:1.0f]  set];
    [textViewSurround stroke];
    
    [[[NSColor controlBackgroundColor] colorWithAlphaComponent:0.40f] set];
    [textViewSurround fill];
    
    //[[NSColor colorWithRed:0.62 green:0.78 blue:0.71 alpha:1.0] set];
    //NSRectFill(NSInsetRect(newRect, 6, 6));
    
    //[[NSColor colorWithPatternImage:[NSImage imageNamed:@"repeat"]] set];
    //NSRectFill(NSInsetRect(newRect, 6, 6));
    
    
    [super drawRect:dirtyRect];
    
}

@end

