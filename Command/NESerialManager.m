//
//  NESerialManager.m
//  Command
//
//  Created by Nicholas Eby on 8/7/17.
//  Copyright © 2017 Nicholas Eby. All rights reserved.
//

#import "NESerialManager.h"
//Third Party
#import "ORSSerialPortManager.h"
#import "ORSSerialPort.h"
#import "ORSSerialRequest.h"

static const NSTimeInterval kTimeoutDuration = 0.5;


@interface NESerialManager () <ORSSerialPortDelegate>
{
    
}

@end

@implementation NESerialManager
@synthesize serialPort = _serialPort, callback;






-(void)sendCommand:(NSData*)command withPacketLegnth:(NSInteger)length andCallback:(MyClassCallback)c
{
    NSString *dataAsString = [[NSString alloc] initWithData:command encoding:NSASCIIStringEncoding];

    NSLog(@"---------- Command Start ----------");
    NSLog(@"1. Send Command [%@]", command);

    //Set Callback
    self.callback = c;

    //Make sure response that comes back is expected
    ORSSerialPacketDescriptor *responseDescriptor = [[ORSSerialPacketDescriptor alloc] initWithMaximumPacketLength:command.length userInfo:nil responseEvaluator:^BOOL(NSData *data)
     {
         return [self errorsFromResponsePacket:data] != nil;
     }];


    ORSSerialRequest *request = [ORSSerialRequest requestWithDataToSend:command userInfo:nil timeoutInterval:kTimeoutDuration responseDescriptor:responseDescriptor];
    
    _serialPort.delegate = self;
    [_serialPort sendRequest:request];
}











//------------------------------------- Delegate -------------------------------------//

-(void)serialPort:(ORSSerialPort *)serialPort didEncounterError:(NSError *)error
{
    if (self.callback != nil)
    {
        self.callback(NO, [NSString stringWithFormat:@"Error: %@", error.localizedDescription]);
    }
}

-(void)serialPort:(ORSSerialPort *)serialPort requestDidTimeout:(ORSSerialRequest *)request
{
    if (self.callback != nil)
    {
        self.callback(NO, @"Error: Request Timed Out");
    }
}

-(void)serialPort:(ORSSerialPort *)serialPort didReceiveResponse:(NSData *)responseData toRequest:(ORSSerialRequest *)request
{
    NSString *dataAsString = [[NSString alloc] initWithData:responseData encoding:NSASCIIStringEncoding];
   
    NSLog(@"3. Received Response: [%@]", dataAsString);
    
    if (self.callback != nil)
    {
        if([dataAsString isEqualToString:@"!"])
        {
            NSLog(@"4. Success: Command Sent!");
            self.callback(YES, @"Success: Command Sent!");
        }
        else if([dataAsString isEqualToString:@"0"])
        {
            NSLog(@"4. Error: Command not supported!");
            self.callback(NO, @"Error: Command not supported!");
        }
        else if([dataAsString isEqualToString:@"1"])
        {
            NSLog(@"4. Error: Loco/accy/signal address out of range!");
            self.callback(NO, @"Error: Loco/accy/signal address out of range!");
        }
        else if([dataAsString isEqualToString:@"2"])
        {
            NSLog(@"4. Error: Cab address or op code out of range!");
            self.callback(NO, @"Error: Cab address or op code out of range!");
        }
        else if([dataAsString isEqualToString:@"3"])
        {
            NSLog(@"4. Error: CV address or data out of range!");
            self.callback(NO, @"Error: CV address or data out of range!");
        }
        else if([dataAsString isEqualToString:@"4"])
        {
            NSLog(@"4. Error: Byte count out of range!");
            self.callback(NO, @"Error: Byte count out of range!");
        }
        else
        {
            NSLog(@"4. Error: Unknown Response (%@)", dataAsString);
            self.callback(NO, [NSString stringWithFormat:@"Error: Unknown Response (%@)", dataAsString]);
        }        
    }
    
    NSLog(@"---------- Command End ----------");
}

- (void)serialPortWasRemovedFromSystem:(nonnull ORSSerialPort *)serialPort
{
    //
}




//------------------------------------- Utilz -------------------------------------//

- (NSString *)errorsFromResponsePacket:(NSData*)data
{
    if (![data length]) return nil;
    
    NSString *dataAsString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    
    NSLog(@"2. Return Data Packet Check: [%@]", dataAsString);
    
    if(![dataAsString isEqualToString:@"!"] && ![dataAsString isEqualToString:@"0"] && ![dataAsString isEqualToString:@"1"] && ![dataAsString isEqualToString:@"2"] && ![dataAsString isEqualToString:@"3"] && ![dataAsString isEqualToString:@"4"])
    {
        return nil;
    }
    
    return dataAsString;;
}





@end
