//
//  NECommand.h
//  Command
//
//  Created by Nicholas Eby on 2/24/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NEFunction.h"

typedef NS_OPTIONS(NSUInteger, FunctionGroup)
{
    Bit0    = (1 << 0), // => 00000001
    Bit1    = (1 << 1), // => 00000010
    Bit2    = (1 << 2), // => 00000100
    Bit3    = (1 << 3), // => 00001000
    Bit4    = (1 << 4), // => 00010000
    Bit5    = (1 << 5), // => 00100000
    Bit6    = (1 << 6), // => 01000000
    Bit7    = (1 << 7)  // => 10000000
};

@interface NECommand : NSObject
{
    FunctionGroup function_group_1;
    FunctionGroup function_group_2;
    FunctionGroup function_group_3;
    FunctionGroup function_group_4;
    FunctionGroup function_group_5;
}


-(NSData*)locomotiveSpeedCommandWithAddr:(NSInteger)addr andSpeed:(NSInteger)speed andDirection:(NSInteger)direction
;
-(NSData*)locomotiveEmergencyStopCommandWithAddr:(NSInteger)addr andDirection:(NSInteger)direction;
-(NSData*)locomotiveFunctionCommand:(NSInteger)addr andFunctionKey:(NEFunction*)function;


@end
