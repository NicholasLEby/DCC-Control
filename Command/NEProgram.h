//
//  NEProgram.h
//  Command
//
//  Created by Nicholas Eby on 2/27/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NEProgram : NSObject
{
    NSString *name;
    NSArray *functions;
}

@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSArray *functions;

-(void)loadFromDict:(NSDictionary*)dict;

@end
