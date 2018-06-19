//
//  NETrain.h
//  Command
//
//  Created by Nicholas Eby on 2/19/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import <Foundation/Foundation.h>
//Models
#import "NEFunction.h"

typedef NS_ENUM(NSUInteger, Train_Type)
{
    kSteam,
    kDiesel
};


@interface NETrain : NSObject

@property(nonatomic, strong) NSString *name;
@property(nonatomic) Train_Type type;
@property(nonatomic, strong) NSString *model;
@property(nonatomic, strong) NSString *manufacturer;
@property(nonatomic, strong) NSNumber *number;
@property(nonatomic) NSInteger dcc_short;
@property(nonatomic) NSInteger dcc_long;
@property(nonatomic, strong) NSNumber *horn_function_key;
@property(nonatomic, strong) NSNumber *bell_function_key;
@property(nonatomic, strong) NSNumber *headlights_function_key;
@property(nonatomic, strong) NSDictionary *functions;
@property(nonatomic, strong) NSArray *programs;


//Methods
-(void)loadFromDict:(NSDictionary*)dict;
-(NSString*)dcc_short_string;

@end
