//
//  NEFunction.m
//  Command
//
//  Created by Nicholas Eby on 2/19/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import "NEFunction.h"

@implementation NEFunction

-(instancetype)initWithKey:(int)key
{
    if(self = [super init])
    {
        _key = key;
    }
    
    return self;
}


@end
