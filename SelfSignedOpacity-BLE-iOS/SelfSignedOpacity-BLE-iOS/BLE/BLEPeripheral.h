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

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "AppGlobals.h"

@protocol BLEPeripheralDelegate <NSObject>
@optional
- (void)sampleComplete:(BOOL)isProx sender:(id)blePeripheral;

@end

@interface BLEPeripheral : NSObject
{
    id<BLEPeripheralDelegate> delegate;
    CBPeripheral *peripheral;
    NSMutableArray *rssiData;
    int tagNumber;
    NSTimer *timer;
}

@property (nonatomic, retain) id<BLEPeripheralDelegate> delegate;
@property (nonatomic, retain) CBPeripheral *peripheral;
@property (nonatomic, retain) NSMutableArray *rssiData;
@property (nonatomic, readwrite) int tagNumber;
@property (nonatomic, retain) NSTimer *timer;

- (id)init;
- (id)initWithPeripheral:(CBPeripheral *)peripheral;
- (void)startReadingRSS;
- (void)readRSSI:(id)sender;
- (void)peripheralDidUpdateRSSI;
- (void)sampleRSSI;
- (void)goodScan;
- (void)resetScan;
- (void)sampleComplete:(BOOL)isProx sender:(id)blePeripheral;

@end
