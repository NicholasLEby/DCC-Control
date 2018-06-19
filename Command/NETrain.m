//
//  NETrain.m
//  Command
//
//  Created by Nicholas Eby on 2/19/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import "NETrain.h"

@implementation NETrain
@synthesize name = _name, type = _type, model = _model, manufacturer = _manufacturer, number = _number, dcc_short = _dcc_short, dcc_long = _dcc_long, functions = _functions, horn_function_key = _horn_function_key, bell_function_key = _bell_function_key, headlights_function_key = _headlights_function_key, programs = _programs;



-(void)loadFromDict:(NSDictionary*)dict
{
    //Name
    if([dict objectForKey:@"name"])
    {
        self.name = [dict objectForKey:@"name"];
    }
    
    //Type
    if([dict objectForKey:@"type"])
    {
        self.type = [[dict objectForKey:@"type"] integerValue];
    }
    
    //Model
    if([dict objectForKey:@"model"])
    {
        self.model = [dict objectForKey:@"model"];
    }
    
    //Manufacturer
    if([dict objectForKey:@"manufacturer"])
    {
        self.manufacturer = [dict objectForKey:@"manufacturer"];
    }
    
    //Number
    if([dict objectForKey:@"number"])
    {
        self.number = [dict objectForKey:@"number"];
    }
    
    //DCC Short Address
    if([dict objectForKey:@"dcc_short"])
    {
        self.dcc_short = [[dict objectForKey:@"dcc_short"] integerValue];
    }
    
    //DCC Long Address
    if([dict objectForKey:@"dcc_long"])
    {
        self.dcc_long = [[dict objectForKey:@"dcc_long"] integerValue];
    }
    
    //Horn Function Number
    if([dict objectForKey:@"horn_function"])
    {
        self.horn_function_key = [dict objectForKey:@"horn_function"];
    }
    
    //Bell Function Number
    if([dict objectForKey:@"bell_function"])
    {
        self.bell_function_key = [dict objectForKey:@"bell_function"];
    }
    
    //Headlights Function Number
    if([dict objectForKey:@"headlight_function"])
    {
        self.headlights_function_key = [dict objectForKey:@"headlight_function"];
    }
    
    //Functions
    if([dict objectForKey:@"functions"])
    {
        self.functions = [dict objectForKey:@"functions"];
    }
}

-(NSString*)dcc_short_string
{
    NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setPaddingPosition:NSNumberFormatterPadBeforePrefix];
    [numberFormatter setPaddingCharacter:@"0"];
    [numberFormatter setMinimumIntegerDigits:3];
    
    
    return [numberFormatter stringFromNumber:[NSNumber numberWithInteger:_dcc_short]];
}




@end
