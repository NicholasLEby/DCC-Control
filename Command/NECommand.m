//
//  NECommand.m
//  Command
//
//  Created by Nicholas Eby on 2/24/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import "NECommand.h"

@implementation NECommand


//---------------------------------- Locomotive Command Helpers ----------------------------------//

-(NSData*)locomotiveSpeedCommandWithAddr:(NSInteger)addr andSpeed:(NSInteger)speed andDirection:(NSInteger)direction
{
    int dcc_address_mode = 0;//for future
    
    NSString *cmd = @"A2";
    NSString *addr_h  = (dcc_address_mode == 0) ? @"00" : @"c0";
    NSString *addr_l = [NSString stringWithFormat:@"%02x", (unsigned int) addr];
    NSString *op_1 = (direction == 0) ? @"03" : @"04";
    NSString *data_1 = [NSString stringWithFormat:@"%02x", (unsigned int) speed];
    
    
    //------------------------ Final Command
    NSString *command_string = [NSString stringWithFormat:@"%@ %@ %@ %@ %@", cmd, addr_h, addr_l, op_1, data_1];

    NSLog(@"Command: %@", command_string);

    return [self hexStringToNSData:command_string];
}

-(NSData*)locomotiveEmergencyStopCommandWithAddr:(NSInteger)addr andDirection:(NSInteger)direction
{
    int dcc_address_mode = 0;//for future
    
    NSString *cmd = @"A2";
    NSString *addr_h  = (dcc_address_mode == 0) ? @"00" : @"c0";
    NSString *addr_l = [NSString stringWithFormat:@"%02x", (unsigned int) addr];
    NSString *op_1 = (direction == 0) ? @"05" : @"06";
    NSString *data_1 = @"00";
    
 
    
    //------------------------ Final Command
    NSString *command_string = [NSString stringWithFormat:@"%@ %@ %@ %@ %@", cmd, addr_h, addr_l, op_1, data_1];
   
    NSLog(@"Command: %@", command_string);

    return [self hexStringToNSData:command_string];
}

-(NSData*)locomotiveFunctionCommand:(NSInteger)addr andFunctionKey:(NEFunction*)function
{
    int dcc_address_mode = 0;//for future
    
    NSString *cmd = @"A2";
    NSString *addr_h  = (dcc_address_mode == 0) ? @"00" : @"c0";
    NSString *addr_l = [NSString stringWithFormat:@"%02x", (unsigned int) addr];
    NSString *op_1;
    NSString *data_1;
    
    //Function Group 1
    if(function.key == 1 || function.key == 2 || function.key == 3 || function.key == 4 || function.key == 0)
    {
        op_1 = @"07";
        
        switch(function.key)
        {
            case 1: if(function.on) { function_group_1 |= Bit0; } else { function_group_1 &= ~Bit0; }; break;
            case 2: if(function.on) { function_group_1 |= Bit1; } else { function_group_1 &= ~Bit1; }; break;
            case 3: if(function.on) { function_group_1 |= Bit2; } else { function_group_1 &= ~Bit2; }; break;
            case 4: if(function.on) { function_group_1 |= Bit3; } else { function_group_1 &= ~Bit3; }; break;
            case 0: if(function.on) { function_group_1 |= Bit4; } else { function_group_1 &= ~Bit4; }; break;
            default: break;
        }
        
        data_1 = [NSString stringWithFormat:@"%02lx", (unsigned long)function_group_1];
    }
    //Function Group 2
    else if(function.key == 5 || function.key == 6 || function.key == 7 || function.key == 8)
    {
        op_1 = @"08";
        
        switch(function.key)
        {
            case 5: if(function.on) { function_group_2 |= Bit0; } else { function_group_2 &= ~Bit0; }; break;
            case 6: if(function.on) { function_group_2 |= Bit1; } else { function_group_2 &= ~Bit1; }; break;
            case 7: if(function.on) { function_group_2 |= Bit2; } else { function_group_2 &= ~Bit2; }; break;
            case 8: if(function.on) { function_group_2 |= Bit3; } else { function_group_2 &= ~Bit3; }; break;
            default: break;
        }
        
        data_1 = [NSString stringWithFormat:@"%02lx", (unsigned long)function_group_2];
    }
    //Function Group 3
    else if(function.key == 9 || function.key == 10 || function.key == 11 || function.key == 12)
    {
        op_1 = @"09";
        
        switch(function.key)
        {
            case 9: if(function.on) { function_group_3 |= Bit0; } else { function_group_3 &= ~Bit0; }; break;
            case 10: if(function.on) { function_group_3 |= Bit1; } else { function_group_3 &= ~Bit1; }; break;
            case 11: if(function.on) { function_group_3 |= Bit2; } else { function_group_3 &= ~Bit2; }; break;
            case 12: if(function.on) { function_group_3 |= Bit3; } else { function_group_3 &= ~Bit3; }; break;
            default: break;
        }
        
        data_1 = [NSString stringWithFormat:@"%02lx", (unsigned long)function_group_3];
    }
    //Function Group 4 - not really a group in NCE terms, but functions 13-20
    else if(function.key == 13 || function.key == 14 || function.key == 15 || function.key == 16 || function.key == 17 || function.key == 18 || function.key == 19 || function.key == 20)
    {
        op_1 = @"15";
        
        switch(function.key)
        {
            case 13: if(function.on) { function_group_4 |= Bit0; } else { function_group_4 &= ~Bit0; }; break;
            case 14: if(function.on) { function_group_4 |= Bit1; } else { function_group_4 &= ~Bit1; }; break;
            case 15: if(function.on) { function_group_4 |= Bit2; } else { function_group_4 &= ~Bit2; }; break;
            case 16: if(function.on) { function_group_4 |= Bit3; } else { function_group_4 &= ~Bit3; }; break;
            case 17: if(function.on) { function_group_4 |= Bit4; } else { function_group_4 &= ~Bit4; }; break;
            case 18: if(function.on) { function_group_4 |= Bit5; } else { function_group_4 &= ~Bit5; }; break;
            case 19: if(function.on) { function_group_4 |= Bit6; } else { function_group_4 &= ~Bit6; }; break;
            case 20: if(function.on) { function_group_4 |= Bit7; } else { function_group_4 &= ~Bit7; }; break;
            default: break;
        }
        
        data_1 = [NSString stringWithFormat:@"%02lx", (unsigned long)function_group_4];
    }
    //Function Group 5 - not really a group in NCE terms, but functions 21-28
    else if(function.key == 21 || function.key == 22 || function.key == 23 || function.key == 24 || function.key == 25 || function.key == 26 || function.key == 27 || function.key == 28)
    {
        op_1 = @"16";
        
        switch(function.key)
        {
            case 21: if(function.on) { function_group_5 |= Bit0; } else { function_group_5 &= ~Bit0; }; break;
            case 22: if(function.on) { function_group_5 |= Bit1; } else { function_group_5 &= ~Bit1; }; break;
            case 23: if(function.on) { function_group_5 |= Bit2; } else { function_group_5 &= ~Bit2; }; break;
            case 24: if(function.on) { function_group_5 |= Bit3; } else { function_group_5 &= ~Bit3; }; break;
            case 25: if(function.on) { function_group_5 |= Bit4; } else { function_group_5 &= ~Bit4; }; break;
            case 26: if(function.on) { function_group_5 |= Bit5; } else { function_group_5 &= ~Bit5; }; break;
            case 27: if(function.on) { function_group_5 |= Bit6; } else { function_group_5 &= ~Bit6; }; break;
            case 28: if(function.on) { function_group_5 |= Bit7; } else { function_group_5 &= ~Bit7; }; break;
            default: break;
        }
        
        data_1 = [NSString stringWithFormat:@"%02lx", (unsigned long)function_group_5];
    }
    
    //------------------------ Final Command
    NSString *command_string = [NSString stringWithFormat:@"%@ %@ %@ %@ %@", cmd, addr_h, addr_l, op_1, data_1];
    
    //NSLog(@"Command: %@", command_string);
    
    return [self hexStringToNSData:command_string];
}












-(NSData*)hexStringToNSData:(NSString*)hex
{
    hex = [hex stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    char buf[3];
    buf[2] = '\0';
    NSAssert(0 == [hex length] % 2, @"Hex strings should have an even number of digits (%@)", hex);
    unsigned char *bytes = malloc([hex length]/2);
    unsigned char *bp = bytes;
    for (CFIndex i = 0; i < [hex length]; i += 2) {
        buf[0] = [hex characterAtIndex:i];
        buf[1] = [hex characterAtIndex:i+1];
        char *b2 = NULL;
        *bp++ = strtol(buf, &b2, 16);
        NSAssert(b2 == buf + 2, @"String should be all hex digits: %@ (bad digit around %ld)", hex, i);
    }
    
    return [NSData dataWithBytesNoCopy:bytes length:[hex length]/2 freeWhenDone:YES];
}


@end
