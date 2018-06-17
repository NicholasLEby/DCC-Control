//
//  NEProgram.m
//  Command
//
//  Created by Nicholas Eby on 2/27/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import "NEProgram.h"

@implementation NEProgram
@synthesize name = _name, functions = _functions;

-(void)loadFromDict:(NSDictionary*)dict
{
    if([dict objectForKey:@"name"])
    {
        _name = [dict objectForKey:@"name"];
    }
    
    if([dict objectForKey:@"functions"])
    {
        _functions = [dict objectForKey:@"functions"];
    }
}

@end
