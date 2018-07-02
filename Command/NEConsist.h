//
//  NEConsist.h
//  Command
//
//  Created by Nicholas Eby on 6/30/18.
//  Copyright © 2018 Nicholas Eby. All rights reserved.
//

#import <Foundation/Foundation.h>
//Core Data
#import "Train+CoreDataClass.h"
#import "Train+CoreDataProperties.h"
#import "trains+CoreDataModel.h"

@interface NEConsist : NSObject

@property (nonatomic) int16_t dcc_address;
@property (nullable, nonatomic, copy) NSString *name;

@property (nullable, nonatomic, strong) Train *lead_train;
@property (nullable, nonatomic, strong) Train *rear_train;
@property (nullable, nonatomic, strong) Train *other1_train;
@property (nullable, nonatomic, strong) Train *other2_train;
@property (nullable, nonatomic, strong) Train *other3_train;


@end
