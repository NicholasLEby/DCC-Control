//
//  NEFunction.h
//  Command
//
//  Created by Nicholas Eby on 2/19/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NEFunction : NSObject

@property(nonatomic) NSInteger key;

//State
@property(nonatomic) BOOL on;
@property(nonatomic) BOOL momentary;

//Method - custom init
-(instancetype)initWithKey:(int)key;

@end
