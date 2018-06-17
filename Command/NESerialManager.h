//
//  NESerialManager.h
//  Command
//
//  Created by Nicholas Eby on 8/7/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ORSSerialPort;

typedef void(^MyClassCallback)(BOOL success, NSString *response);


@interface NESerialManager : NSObject
{
    
}

@property (nonatomic, readwrite, copy) MyClassCallback callback;
@property(nonatomic, strong) ORSSerialPort *serialPort;

//Public Methods
-(void)sendCommand:(NSData*)command withPacketLegnth:(NSInteger)length andCallback:(MyClassCallback)callback;

@end
