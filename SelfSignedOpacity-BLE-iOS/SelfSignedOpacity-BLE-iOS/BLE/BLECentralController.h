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

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEPeripheral.h"
#import "DHSGattProfile.h"

@protocol BLECentralControllerDelegate <NSObject>
@optional
- (void)bleCentralControllerDidSendMessage:(NSData *)message;
- (void)bleCentralControllerDidReceiveMessage:(NSData *)message;
@end

@interface BLECentralController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate, BLEPeripheralDelegate>
{
    id<BLECentralControllerDelegate> delegate;
    CBCentralManager *centralManager;
    NSMutableArray *peripherals;
    NSMutableData *data;
    CBPeripheral *discoveredPeripheral;
    CBCharacteristic *txCharacterisitc;
    CBCharacteristic *rxCharacteristic;
    NSMutableArray *rssiData;
    NSTimer *timer;
    int tagNumber;
    UILabel *connectionsLabel;
    NSTimer *checkManagerStillScanningTimer;
    BOOL incomingMessage;
}

@property (nonatomic, assign) id<BLECentralControllerDelegate> delegate;
@property (nonatomic, retain) CBCentralManager *centralManager;
@property (nonatomic, retain) NSMutableArray *peripherals;
@property (nonatomic, retain) NSMutableData *data;
@property (strong) CBPeripheral *discoveredPeripheral;
@property (nonatomic, retain) NSMutableArray *rssiData;
@property (nonatomic, retain) CBCharacteristic  *txCharacteristic;
@property (nonatomic, retain) CBCharacteristic  *rxCharacteristic;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, readwrite) BOOL goodTag;
@property (nonatomic, readwrite) int tagNumber;
@property (nonatomic, retain) UILabel *connectionsLabel;
@property (nonatomic, retain) NSTimer *checkManagerStillScanningTimer;
@property (nonatomic, readwrite) BOOL incomingMessage;

- (void)startManager;
- (void)stopManager;
- (void)sendMessageWithPayload:(NSData *)message;
- (void)subscribeToComms;
- (NSMutableArray *)subFragment:(NSData *)message;

@end
