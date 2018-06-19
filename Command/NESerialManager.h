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


@property (atomic, retain) NSString *filePath;
+(id)sharedManager;

@property (nonatomic, readwrite, copy) MyClassCallback callback;
@property(nonatomic, strong) ORSSerialPort *serialPort;

//Public Methods
-(void)openSerialWithPath:(NSString*)path;
-(void)closeSerial;
-(void)sendCommand:(NSData*)command withPacketResponseLength:(NSInteger)length andUserInfo:(NSString*)userInfo andCallback:(MyClassCallback)c;

@end
