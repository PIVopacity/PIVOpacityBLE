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
#import "DHSGattProfile.h"
#import "AppGlobals.h"

@protocol BLEPeripheralControllerDelegate <NSObject>
@optional
- (void)blePeripheralControllerDidSendMessage:(NSData *)message;
- (void)blePeripheralControllerDidReceiveMessage:(NSData *)message;
@end

@interface BLEPeripheralController : UIViewController <CBPeripheralManagerDelegate> {
    
    id<BLEPeripheralControllerDelegate>  *delegate;
    CBPeripheralManager *peripheralManager;
    CBMutableCharacteristic  *rxCharacteristic;
    CBMutableCharacteristic  *txCharacteristic;
    NSData *payload;
    NSInteger payloadIndex;
    BOOL eomSent;
    BOOL dataSent;
}

@property (nonatomic, assign) id<BLEPeripheralControllerDelegate>  *delegate;
@property (nonatomic, retain) CBPeripheralManager *peripheralManager;
@property (nonatomic, retain) CBMutableCharacteristic  *rxCharacteristic;
@property (nonatomic, retain) CBMutableCharacteristic  *txCharacteristic;
@property (nonatomic, retain) NSData *payload;
@property (nonatomic, readwrite) NSInteger payloadIndex;
@property (nonatomic, readwrite) BOOL eomSent;
@property (nonatomic, readwrite) BOOL dataSent;

- (void)startManager;
- (void)stopManager;

- (void)sendMessageWithPayload:(NSData *)payload;
- (void)setTxValue:(NSData *)value;

@end
