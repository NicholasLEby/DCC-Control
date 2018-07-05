//
//  NEConsoleView.m
//  Command
//
//  Created by Nicholas Eby on 2/19/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import "NEConsoleView.h"

@implementation NEConsoleView


- (void)drawRect:(NSRect)dirtyRect
{
    
    NSRect frameRect = [self bounds];
    
    NSInteger count = 35;
    NSInteger width = self.bounds.size.width / count;
    
    for(int i = 0; i < count; i++)
    {
        NSRect newRect = NSMakeRect(i * (width + 2),0, width, frameRect.size.height);
        
        NSBezierPath *textViewSurround = [NSBezierPath bezierPathWithRoundedRect:newRect xRadius:0 yRadius:0];
        [[NSColor colorWithWhite:0.0f alpha:0.05f]  set];
        [textViewSurround fill];
    }
    
    
    

   
    
    [super drawRect:dirtyRect];

}

@end
