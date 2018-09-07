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

#import "BLEPeripheral.h"

@implementation BLEPeripheral

@synthesize delegate;
@synthesize peripheral;
@synthesize rssiData;
@synthesize tagNumber;
@synthesize timer;

#define kSamples	5
#define kInterval   0.01

#pragma mark - Setup Methods
//===================================================================================
- (id)init;
{
    DBLogMethod(@"%s");

    if (self = [super init])
    {
        self.rssiData = [NSMutableArray arrayWithCapacity:0];
    }
    return self;
}

//===================================================================================
- (id)initWithPeripheral:(CBPeripheral *)peripheral;
{
    DBLogMethod(@"%s");
    
    self.peripheral = peripheral;
    self.peripheral.delegate = (id)self;
    
    return[self init];
}

#pragma mark - Utility Methods
//===================================================================================
- (void)startReadingRSS;
{
    DBLogMethod(@"%s");
    
    NSTimer *aTimer = [[NSTimer scheduledTimerWithTimeInterval:kInterval target:self selector:@selector(readRSSI:) userInfo:nil repeats:YES] retain];
    self.timer = aTimer;
}

//===================================================================================
- (void)readRSSI:(id)sender;
{
   // DBLogMethod(@"%s");
    
    
    if (self.peripheral.state == CBPeripheralStateConnected)
    {
        //hack
        [self.peripheral readRSSI];
    }
    return;
    
    /*
    if ([self.peripheral isConnected]) {
        [self.peripheral readRSSI];
    }
     */
}

//===================================================================================
- (void)peripheralDidUpdateRSSI;
{
    DBLogMethod(@"%s");
    
    DBLogInfo(@"RSSI = %i", [self.peripheral.RSSI integerValue]);
    [self sampleRSSIForPeripheral:self.peripheral];
}

//===================================================================================
- (void)sampleRSSI;
{
    //DBLogMethod(@"%s");
    
    DBLogVerbose(@"tagNumber: %i, %@: RSSI = %i", tagNumber, peripheral.name, [peripheral.RSSI integerValue]);
    
    NSNumber *rssi = self.peripheral.RSSI;
    
    if (rssi == nil) {
        return;
    }
    
    CGFloat sensitivity = 50.0;
    DBLogInfo(@"sensitivity = %0.2f", sensitivity);

    int arraySize = [self.rssiData count];
    
    float total = 0.0;
    float value = 0.0;
    int items = 0;
    
    if (arraySize == kSamples) {
        for (int i = 0; i < arraySize; i++) {
            items ++;
            value = abs([[self.rssiData objectAtIndex:i] integerValue]);
            total += value;
            //NSLog(@"item: %i, reading: %0.2f, %0.2f", items, value, total);
        }
        float averageValue = total/items;
        DBLogVerbose(@"TagNumber: %i, Name: %@, av = %0.2f, limit: %0.2f", tagNumber, peripheral.name, averageValue, sensitivity);
        self.rssiData = [NSMutableArray arrayWithCapacity:0];
        
        if (averageValue < sensitivity) {
            [self goodScan];
        }
        else{
            //[self resetScan];
        }
    }
    else {
        [self.rssiData addObject:rssi];
    }
}

//===================================================================================
- (void)goodScan;
{
    DBLogMethod(@"%s");
    [self sampleComplete:YES sender:self];
}

//===================================================================================
- (void)resetScan;
{
    DBLogMethod(@"%s");
    [self sampleComplete:NO sender:self];
}


#pragma mark - BLEPeripheralDelegate Methods
//===================================================================================
- (void)sampleComplete:(BOOL)isProx sender:(id)blePeripheral;
{
    DBLogMethod(@"%s");
    
    if ([self.delegate respondsToSelector:@selector(sampleComplete:sender:)]) {
        [self.delegate sampleComplete:isProx sender:blePeripheral];
    }
}

@end
