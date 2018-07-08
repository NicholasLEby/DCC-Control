//
//  NEConsistTrain.h
//  Tester
//
//  Created by Eby, Nicholas on 7/5/18.
//  Copyright © 2018 Ulta Beauty. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NEConsistTrain : NSObject

@property(nonatomic, strong) NSString *name;
@property(nonatomic) NSInteger dcc_address;
@property(nonatomic) NSInteger direction;
@property(nonatomic) NSInteger position;
@property(nonatomic) NSInteger consist_address;

@end
