//
//  NECommand.m
//  Command
//
//  Created by Nicholas Eby on 2/24/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import "NENCECommand.h"

@implementation NENCECommand


//---------------------------------- Locomotive Command Helpers ----------------------------------//

-(NSData*)locomotiveSpeedCommandWithAddr:(NSInteger)addr andSpeed:(NSInteger)speed andDirection:(NSInteger)direction
{
    int dcc_address_mode = 0;//for future / remove this, check if addr is 0,127 or > to determine long or short

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
    int dcc_address_mode = 0;//for future / remove this, check if addr is 0,127 or > to determine long or short

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




-(NSData*)locomotiveConsistCommandWithAddr:(NSInteger)addr consistNumber:(NSInteger)consistNumber andPosition:(NSInteger)position
{
    //Postion, 0 = F, 1 = R
    
    int dcc_address_mode = 0;//for future / remove this, check if addr is 0,127 or > to determine long or short
    
    NSString *cmd = @"AE";
    NSString *addr_h  = (dcc_address_mode == 0) ? @"00" : @"c0";
    NSString *addr_l = [NSString stringWithFormat:@"%02x", (unsigned int) addr];
    NSString *cv_h = @"00";
    NSString *cv_l = @"13";
    NSString *data_1 = (position == 0) ? [NSString stringWithFormat:@"%02x", (unsigned int) consistNumber] : [NSString stringWithFormat:@"%02x", (unsigned int) consistNumber + 128];
    
    //------------------------ Final Command
    NSString *command_string = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@", cmd, addr_h, addr_l, cv_h, cv_l, data_1];
    
    NSLog(@"Command: %@", command_string);
    
    return [self hexStringToNSData:command_string];
}

-(NSData*)locomotiveResetConsistCommandWithAddr:(NSInteger)addr
{
    //Postion, 0 = F, 1 = R
    
    int dcc_address_mode = 0;//for future / remove this, check if addr is 0,127 or > to determine long or short
    
    NSString *cmd = @"AE";
    NSString *addr_h  = (dcc_address_mode == 0) ? @"00" : @"c0";
    NSString *addr_l = [NSString stringWithFormat:@"%02x", (unsigned int) addr];
    NSString *cv_h = @"00";
    NSString *cv_l = @"13";
    NSString *data_1 = @"00";
    
    //------------------------ Final Command
    NSString *command_string = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@", cmd, addr_h, addr_l, cv_h, cv_l, data_1];
    
    NSLog(@"Command: %@", command_string);
    
    return [self hexStringToNSData:command_string];
}

-(NSData*)softResetCommandStation
{
    NSString *cmd = @"A8";

    NSString *command_string = [NSString stringWithFormat:@"%@", cmd];
    
    NSLog(@"Command: %@", command_string);
    
    return [self hexStringToNSData:command_string];
}



-(NSData*)locomotiveNCEConsistCommandWithAddr:(NSInteger)addr andPosition:(NSInteger)position
{
    int dcc_address_mode = 0;//for future / remove this, check if addr is 0,127 or > to determine long or short

    NSString *cmd = @"A2";
    NSString *addr_h  = (dcc_address_mode == 0) ? @"00" : @"c0";
    NSString *addr_l = [NSString stringWithFormat:@"%02x", (unsigned int) addr];
    NSString *op_1;
 
    switch (position)
    {
        case 0: op_1 = @"11"; break; //Kill
        case 1: op_1 = @"0a"; break; //lead reverse
        case 2: op_1 = @"0b"; break; //lead forward
        case 3: op_1 = @"0c"; break; //rear reverse
        case 4: op_1 = @"0d"; break; //rear forward
        case 5: op_1 = @"0e"; break; //other forward
        case 6: op_1 = @"0f"; break; //other reverse
        default: op_1 = @"11"; break;
    }
    
    NSString *data_1 = (position == 0) ? @"00" : [NSString stringWithFormat:@"%02x", (unsigned int) 127];
    
    //------------------------ Final Command
    NSString *command_string = [NSString stringWithFormat:@"%@ %@ %@ %@ %@", cmd, addr_h, addr_l, op_1, data_1];
    
    NSLog(@"Command: %@", command_string);
    
    return [self hexStringToNSData:command_string];
}

    
-(NSData*)locomotiveFunctionCommand:(NSInteger)addr andFunctionKey:(NSNumber*)functionNumber andFunctionState:(BOOL)state
{
    int dcc_address_mode = 0;//for future / remove this, check if addr is 0,127 or > to determine long or short
    
    NSString *cmd = @"A2";
    NSString *addr_h  = (dcc_address_mode == 0) ? @"00" : @"c0";
    NSString *addr_l = [NSString stringWithFormat:@"%02x", (unsigned int) addr];
    NSString *op_1;
    NSString *data_1;
    
    //Function Group 1
    if(functionNumber.integerValue == 1 || functionNumber.integerValue == 2 || functionNumber.integerValue == 3 || functionNumber.integerValue == 4 || functionNumber.integerValue == 0)
    {
        op_1 = @"07";
        
        switch(functionNumber.integerValue)
        {
            case 1: if(state) { self.function_group_1 |= Bit0; } else { self.function_group_1 &= ~Bit0; }; break;
            case 2: if(state) { self.function_group_1 |= Bit1; } else { self.function_group_1 &= ~Bit1; }; break;
            case 3: if(state) { self.function_group_1 |= Bit2; } else { self.function_group_1 &= ~Bit2; }; break;
            case 4: if(state) { self.function_group_1 |= Bit3; } else { self.function_group_1 &= ~Bit3; }; break;
            case 0: if(state) { self.function_group_1 |= Bit4; } else { self.function_group_1 &= ~Bit4; }; break;
            default: break;
        }
        
        data_1 = [NSString stringWithFormat:@"%02lx", (unsigned long)_function_group_1];
    }
    //Function Group 2
    else if(functionNumber.integerValue == 5 || functionNumber.integerValue == 6 || functionNumber.integerValue == 7 || functionNumber.integerValue == 8)
    {
        op_1 = @"08";
        
        switch(functionNumber.integerValue)
        {
            case 5: if(state) { self.function_group_2 |= Bit0; } else { self.function_group_2 &= ~Bit0; }; break;
            case 6: if(state) { self.function_group_2 |= Bit1; } else { self.function_group_2 &= ~Bit1; }; break;
            case 7: if(state) { self.function_group_2 |= Bit2; } else { self.function_group_2 &= ~Bit2; }; break;
            case 8: if(state) { self.function_group_2 |= Bit3; } else { self.function_group_2 &= ~Bit3; }; break;
            default: break;
        }
        
        data_1 = [NSString stringWithFormat:@"%02lx", (unsigned long)_function_group_2];
    }
    //Function Group 3
    else if(functionNumber.integerValue == 9 || functionNumber.integerValue == 10 || functionNumber.integerValue == 11 || functionNumber.integerValue == 12)
    {
        op_1 = @"09";
        
        switch(functionNumber.integerValue)
        {
            case 9: if(state) { self.function_group_3 |= Bit0; } else { self.function_group_3 &= ~Bit0; }; break;
            case 10: if(state) { self.function_group_3 |= Bit1; } else { self.function_group_3 &= ~Bit1; }; break;
            case 11: if(state) { self.function_group_3 |= Bit2; } else { self.function_group_3 &= ~Bit2; }; break;
            case 12: if(state) { self.function_group_3 |= Bit3; } else { self.function_group_3 &= ~Bit3; }; break;
            default: break;
        }
        
        data_1 = [NSString stringWithFormat:@"%02lx", (unsigned long)_function_group_3];
    }
    //Function Group 4 - not really a group in NCE terms, but functions 13-20
    else if(functionNumber.integerValue == 13 || functionNumber.integerValue == 14 || functionNumber.integerValue == 15 || functionNumber.integerValue == 16 || functionNumber.integerValue == 17 || functionNumber.integerValue == 18 || functionNumber.integerValue == 19 || functionNumber.integerValue == 20)
    {
        op_1 = @"15";
        
        switch(functionNumber.integerValue)
        {
            case 13: if(state) { self.function_group_4 |= Bit0; } else { self.function_group_4 &= ~Bit0; }; break;
            case 14: if(state) { self.function_group_4 |= Bit1; } else { self.function_group_4 &= ~Bit1; }; break;
            case 15: if(state) { self.function_group_4 |= Bit2; } else { self.function_group_4 &= ~Bit2; }; break;
            case 16: if(state) { self.function_group_4 |= Bit3; } else { self.function_group_4 &= ~Bit3; }; break;
            case 17: if(state) { self.function_group_4 |= Bit4; } else { self.function_group_4 &= ~Bit4; }; break;
            case 18: if(state) { self.function_group_4 |= Bit5; } else { self.function_group_4 &= ~Bit5; }; break;
            case 19: if(state) { self.function_group_4 |= Bit6; } else { self.function_group_4 &= ~Bit6; }; break;
            case 20: if(state) { self.function_group_4 |= Bit7; } else { self.function_group_4 &= ~Bit7; }; break;
            default: break;
        }
        
        data_1 = [NSString stringWithFormat:@"%02lx", (unsigned long)_function_group_4];
    }
    //Function Group 5 - not really a group in NCE terms, but functions 21-28
    else if(functionNumber.integerValue == 21 || functionNumber.integerValue == 22 || functionNumber.integerValue == 23 || functionNumber.integerValue == 24 || functionNumber.integerValue == 25 || functionNumber.integerValue == 26 || functionNumber.integerValue == 27 || functionNumber.integerValue == 28)
    {
        op_1 = @"16";
        
        switch(functionNumber.integerValue)
        {
            case 21: if(state) { self.function_group_5 |= Bit0; } else { self.function_group_5 &= ~Bit0; }; break;
            case 22: if(state) { self.function_group_5 |= Bit1; } else { self.function_group_5 &= ~Bit1; }; break;
            case 23: if(state) { self.function_group_5 |= Bit2; } else { self.function_group_5 &= ~Bit2; }; break;
            case 24: if(state) { self.function_group_5 |= Bit3; } else { self.function_group_5 &= ~Bit3; }; break;
            case 25: if(state) { self.function_group_5 |= Bit4; } else { self.function_group_5 &= ~Bit4; }; break;
            case 26: if(state) { self.function_group_5 |= Bit5; } else { self.function_group_5 &= ~Bit5; }; break;
            case 27: if(state) { self.function_group_5 |= Bit6; } else { self.function_group_5 &= ~Bit6; }; break;
            case 28: if(state) { self.function_group_5 |= Bit7; } else { self.function_group_5 &= ~Bit7; }; break;
            default: break;
        }
        
        data_1 = [NSString stringWithFormat:@"%02lx", (unsigned long)_function_group_5];
    }
    
    //------------------------ Final Command
    NSString *command_string = [NSString stringWithFormat:@"%@ %@ %@ %@ %@", cmd, addr_h, addr_l, op_1, data_1];
    
    //NSLog(@"Command: %@", command_string);
    
    return [self hexStringToNSData:command_string];
}




-(NSData*)softwareVersion
    {
        NSString *cmd = @"AA";

        //------------------------ Final Command
        NSString *command_string = [NSString stringWithFormat:@"%@", cmd];
        
        NSLog(@"Command: %@", command_string);
        
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
