/*
 Copyright (c) 2018 United States Government
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

#import "BLEPeripheralController.h"

@interface BLEPeripheralController ()

@end

@implementation BLEPeripheralController

@synthesize delegate;
@synthesize peripheralManager;
@synthesize rxCharacteristic;
@synthesize txCharacteristic;
@synthesize payload;
@synthesize payloadIndex;
@synthesize eomSent;
@synthesize dataSent;


#define NOTIFY_MTU      20

#pragma mark - Setup Methods
//===================================================================================================================
- (id)init;
{
    DBLogMethod(@"%s");
    
    if (self = [super init]) {
    }
    return self;
}

#pragma mark - Utility Methods
//===================================================================================
- (void)startManager;
{
    DBLogMethod(@"%s");
    
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

//===================================================================================
- (void)stopManager;
{
    DBLogMethod(@"%s");
    
    [self.peripheralManager stopAdvertising];
}

#pragma mark - Bluetooth Methods
//===================================================================================================================
- (void)setupAdvertisingService;
{
    DBLogMethod(@"%s");
    
    // Create the service UUID
    CBUUID *serviceUUID = [CBUUID UUIDWithString:serviceAdvertising];
    CBMutableService *service = [[CBMutableService alloc] initWithType:serviceUUID primary:YES];
    
    // Publish the service
    [self.peripheralManager addService:service];
}

//===================================================================================================================
- (void)setupCommunicationsService;
{
    DBLogMethod(@"%s");
    
    // Create the Tx characteristic UUID for Reading (NOTIFY) by the Central (First Responder)
    CBUUID *txCharacteristicUUID = [CBUUID UUIDWithString:charCommsTx];
    
    // Create the Tx characteristic
    CBMutableCharacteristic *atxCharacteristic = [[CBMutableCharacteristic alloc] initWithType:txCharacteristicUUID properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    self.txCharacteristic = atxCharacteristic;
    //self.txCharacteristic.value = [[NSData alloc] initWithData:[[@"0001" stringByAppendingString:SELECT_PIV] dataFromHexString]];
    
    // Create the Rx characteristic UUID for Writing by the Central (First Responder)
    CBUUID *rxCharacteristicUUID = [CBUUID UUIDWithString:charCommsRx];
    
    // Create the Rx characteristic
    CBMutableCharacteristic *arxCharacteristic = [[CBMutableCharacteristic alloc] initWithType:rxCharacteristicUUID properties:CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsWriteable];
    self.rxCharacteristic = arxCharacteristic;
    
    // Create the service UUID
    CBUUID *serviceUUID = [CBUUID UUIDWithString:serviceComms];
    
    // Create the service and adds the characteristic to it
    CBMutableService *service = [[CBMutableService alloc] initWithType:serviceUUID primary:YES];
    
    // Set the characteristics for this service
    [service setCharacteristics:@[txCharacteristic,rxCharacteristic]];
    
    // Publish the service
    [self.peripheralManager addService:service];
}

//===================================================================================================================
- (void)setTxValue:(NSData *)value
{
    self.txCharacteristic.value = value;
    //BOOL txChanged = [self.peripheralManager updateValue:value forCharacteristic:self.txCharacteristic onSubscribedCentrals:nil];
    DBLogInfo(@"setTxValue: %@", self.txCharacteristic.value);
}

//===================================================================================================================
- (void)sendMessageWithPayload:(NSData *)payload;
{
    DBLogMethod(@"%s");
    
    eomSent = NO;
    dataSent = NO;
    
    self.payload = payload;
    self.payloadIndex = 0;
    
    // Start sending
    [self sendData];
}

//===================================================================================================================
- (void)sendData;
{
    DBLogMethod(@"%s");
    
    if(dataSent)
        return;
    
    DBLogError(@"payloadIndex: %li, payload length: %lu, payload: %@\n", (long)self.payloadIndex, (unsigned long)self.payload.length, self.payload);
    
    if (self.payloadIndex >= self.payload.length) {
        if (!eomSent) {
            eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.txCharacteristic onSubscribedCentrals:nil];
            if (eomSent) {
                DBLogInfo(@"EOM successfully sent.");
                
                SEL selector = NSSelectorFromString(@"blePeripheralControllerDidSendMessage:");
                if ([(id)self.delegate respondsToSelector:selector])
                    [(id)self.delegate performSelector:selector withObject:self.payload];
            }
        }
        return;
    }
        
    // There's data left, so send until the callback fails, or we're done.
    BOOL didSend = YES;
    
    while (didSend)
    {
        // Make the next chunk
        NSInteger amountToSend = self.payload.length - self.payloadIndex;
        
        // Can't be longer than NOTIFY_MTU bytes
        if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
        
        // Copy out the data we want
        NSData *chunk = [NSData dataWithBytes:self.payload.bytes+self.payloadIndex length:amountToSend];
        
        NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        DBLogVerbose(@"Data to send: %@", stringFromData);
        
        // Send it
        didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.txCharacteristic onSubscribedCentrals:nil];
        
        // If it didn't work, drop out and wait for the callback
        if (didSend) {
            DBLogVerbose(@"Data successfully sent");
        }
        else {
            DBLogVerbose(@"Data send failed");
            return;
        }
        
        // It did send, so update our index
        self.payloadIndex += amountToSend;
        
        // Was it the last one?
        if (self.payloadIndex >= self.payload.length && !eomSent)
            {
            
            // It was - send an EOM. Set this so if the send fails, we'll send it next time
            
            DBLogVerbose(@"Sending EOM");
            eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.txCharacteristic onSubscribedCentrals:nil];
            
            if (eomSent) {
                // It sent, we're all done
                DBLogVerbose(@"EOM sent. All done.");
                }
            else {
                DBLogVerbose(@"EOM not sent");
            }
            return;
        }
    }
}

#pragma mark - CBPeripheralManager Delegate Methods
//===================================================================================================================
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheralManager;
{
    DBLogMethod(@"%s");
    
    switch (peripheralManager.state) {
        case CBPeripheralManagerStatePoweredOn:
            [self setupAdvertisingService];
            [self setupCommunicationsService];
            break;
        default:
            DBLogInfo(@"Peripheral Manager did change state");
            break;
    }
}

//==========================================================================================================================
- (void)peripheralManager:(CBPeripheralManager *)peripheralManager didAddService:(CBService *)service error:(NSError *)error;
{
    DBLogMethod(@"%s");
    
    DBLogInfo(@"Peripheral Manager %@, didAddService: %@", peripheralManager, service);
    
    NSString *message = [NSString stringWithFormat:@"Peripheral Manager %@ advertising", peripheralManager];
    DBLogInfo(@"%@",message);
    
    if (error == nil) {
        // Starts advertising the service
        DBLogInfo(@"Start advertising");

        [self.peripheralManager startAdvertising:@{CBAdvertisementDataLocalNameKey : @"DHS AUTH", CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:serviceAdvertising]] }];
    }
}

// Catch when someone subscribes to our characteristic, then start sending them data
//===================================================================================================================
- (void)peripheralManager:(CBPeripheralManager *)peripheralManager central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    DBLogMethod(@"%s");
    
    NSString *message = [NSString stringWithFormat:@"Received subscription to characteristic %@ on characteristic", characteristic];
    DBLogInfo(@"%@",message);
    
    //NSString *firstMessageString = @"This is the guard sending a message to the first responder.";
    //NSData *firstMessage = [firstMessageString dataUsingEncoding:NSUTF8StringEncoding];
    NSData *firstMessage = [[@"0001" stringByAppendingString:SELECT_PIV] dataFromHexString];
    [self sendMessageWithPayload: firstMessage];
    
    SEL selector = NSSelectorFromString(@"blePeripheralControllerDidStartSendingMessage:");
    if ([(id)self.delegate respondsToSelector:selector])
        [(id)self.delegate performSelector:selector withObject:firstMessage];
}

//===================================================================================================================
- (void)peripheralManager:(CBPeripheralManager *)peripheralManager central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic;
{
    DBLogMethod(@"%s");
    NSString *message = [NSString stringWithFormat:@"Listener unsubscribed from characteristic: %@ on characteristic", characteristic];
    DBLogInfo(@"%@",message);
}

//===================================================================================================================
// This callback comes in when the PeripheralManager is ready to send the next chunk of data.
// This is to ensure that packets will arrive in the order they are sent
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheralManager;
{
    DBLogMethod(@"%s");

    // Start sending again
    [self sendData];
}

////===================================================================================================================
//- (void)peripheralManager:(CBPeripheralManager *)peripheralManager didReceiveReadRequests:(NSArray<CBATTRequest *> *)requests;
//{
//    DBLogMethod(@"%s");
//
//    DBLogInfo(@"peripheralManager:%@ didReceiveReadRequests:%@", peripheralManager, requests);
//
//    CBATTRequest *request = [requests  objectAtIndex: 0];
//    NSData *request_data = request.value;
//
//    for (CBATTRequest * req in requests) {
//        //IMPORTANT: send response to central otherwise there is a large slowdown!!
//        [self.peripheralManager respondToRequest:req withResult:CBATTErrorSuccess];
//    }
//
//    SEL selector = NSSelectorFromString(@"blePeripheralControllerDidReceiveMessage:");
//    if ([(id)self.delegate respondsToSelector:selector])
//        [(id)self.delegate performSelector:selector withObject:request_data];
//}


//===================================================================================================================
- (void)peripheralManager:(CBPeripheralManager *)peripheralManager didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests;
{
    DBLogMethod(@"%s");
    
    DBLogInfo(@"peripheralManager:%@ didReceiveWriteRequests:%@", peripheralManager, requests);
    
    CBATTRequest *request = [requests  objectAtIndex: 0];
    NSData *request_data = request.value;
    
    
    
    for (CBATTRequest * req in requests) {
        //IMPORTANT: send response to central otherwise there is a large slowdown!!
        [self.peripheralManager respondToRequest:req withResult:CBATTErrorSuccess];
    }
    //NSString *receivedMessage = [[NSString alloc] initWithData:request_data encoding:NSUTF8StringEncoding];
    //DBLogInfo(@"receivedMessage: %@", receivedMessage);
    DBLogInfo(@"receivedMessage: %@", toHexString(request_data, @" "));
    
    
    SEL selector = NSSelectorFromString(@"blePeripheralControllerDidReceiveMessage:");
    if ([(id)self.delegate respondsToSelector:selector])
        [(id)self.delegate performSelector:selector withObject:request_data];
}

//===================================================================================================================
#pragma mark - Terminate
- (void)didReceiveMemoryWarning;
{
    DBLogMethod(@"%s");

    [super didReceiveMemoryWarning];
}

@end
