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


#import "BLECentralController.h"

@implementation BLECentralController

@synthesize delegate;
@synthesize centralManager, data, peripherals;
@synthesize discoveredPeripheral;
@synthesize rssiData;
@synthesize timer;
@synthesize tagNumber;
@synthesize connectionsLabel;
@synthesize txCharacteristic;
@synthesize rxCharacteristic;
@synthesize checkManagerStillScanningTimer;
@synthesize incomingMessage;

#pragma mark - Setup Methods
//===================================================================================================================
- (id)init;
{
    DBLogMethod(@"%s");
    
    if (self = [super init]) {
        
        self.data = [[NSMutableData alloc] init];
        
        NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:0];
        self.peripherals = tempArray;
        
        tagNumber = 0;
        incomingMessage = false;
    }
    return self;
}

#pragma mark - Utility Methods

//===================================================================================
- (void)startManager;
{
    DBLogMethod(@"%s");
    
    CBCentralManager *aManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.centralManager = aManager;
    [aManager release];
    
    //self.rssiData = [NSMutableArray arrayWithCapacity:0];
    [self.timer invalidate];
}

//===================================================================================
- (void)stopManager;
{
    DBLogMethod(@"%s");
    
    DBLogInfo(@"Stopping Central Manager");
    
    [self.centralManager stopScan];
    [self cancelAllConnections];
    [self checkManagerStillScanning];
}

//===================================================================================
- (void)cancelAllConnections;
{
    DBLogMethod(@"%s");
    
    for (BLEPeripheral *blePeripheral in self.peripherals) {
        [self.centralManager cancelPeripheralConnection:blePeripheral.peripheral];
    }
}

//===================================================================================
- (void)checkManagerStillScanning;
{
    DBLogMethod(@"%s");
    //Have to do this as no delegate method called when central stops scanning

    self.checkManagerStillScanningTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkManagerStatus) userInfo:nil repeats:YES] retain];
}

//===================================================================================
- (void)checkManagerStatus;
{
    DBLogMethod(@"%s");
    
    if (!self.centralManager.isScanning) {
        [self.checkManagerStillScanningTimer invalidate];
    }
}

//===================================================================================
- (BOOL)peripheralAlreadyExists:(CBPeripheral *)peripheral{
    //DBLogMethod(@"%s");
    
    for (BLEPeripheral *blePeripheral in self.peripherals) {
        DBLogInfo(@"TAP: %@, Peripheral: %@", blePeripheral, blePeripheral.peripheral);
        if (blePeripheral.peripheral == peripheral) {
            DBLogInfo(@"Peripheral already exists");
            return YES;
        }
    }
    DBLogInfo(@"Peripheral does not exist");

    return NO;
}

//===================================================================================
- (void)scan
{
    DBLogMethod(@"%s");
    
    NSDictionary *scanOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    [self.centralManager scanForPeripheralsWithServices:[NSArray arrayWithObjects:[CBUUID UUIDWithString:serviceAdvertising], nil] options:scanOptions];
    
    DBLogInfo(@"Scanning started...");
}

#pragma mark - CBCentralManagerDelegate Methods
//===================================================================================
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    DBLogMethod(@"%s");
    
    NSString *message = [NSString stringWithFormat:@"Central %@ updated", central];
    DBLogInfo(@"%@",message);
    
    NSString *stateString = @"";
    
    switch(central.state)
    {
        case CBCentralManagerStateResetting: stateString = @"The connection with the system service was momentarily lost, update imminent."; break;
        case CBCentralManagerStateUnsupported: stateString = @"The platform doesn't support Bluetooth Low Energy."; break;
        case CBCentralManagerStateUnauthorized: stateString = @"The app is not authorized to use Bluetooth Low Energy."; break;
        case CBCentralManagerStatePoweredOff: stateString = @"Bluetooth is currently powered off."; break;
        case CBCentralManagerStatePoweredOn: stateString = @"Bluetooth is currently powered on and available to use."; break;
        default: stateString = @"State unknown, update imminent."; break;
    }
    
    DBLogInfo(@"Central manager state: %@", stateString);

    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
        {
            [self scan];
        }
            break;
        default:
            DBLogInfo(@"Central did change state");
            break;
    }
}

//===================================================================================
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    DBLogMethod(@"%s");
    DBLogInfo(@"Perhiperal: %@, Name: %@, Length: %lu", peripheral, peripheral.name, [peripheral.name length]);
    
    if (![self peripheralAlreadyExists:peripheral]) {
        if (self.discoveredPeripheral != peripheral) {
            self.discoveredPeripheral = peripheral;
            DBLogInfo(@"Discovered peripheral: %@", peripheral);
        }
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

//===================================================================================
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    DBLogMethod(@"%s");
    
    BOOL peripheralAlreadyExists = [self peripheralAlreadyExists:peripheral];
    
    if (!peripheralAlreadyExists) {
        
        NSString *message = [NSString stringWithFormat:@"Connected to peripheral %@", peripheral];
        DBLogInfo(@"%@",message);

        // Stop scanning
        [self.centralManager stopScan];
        
        DBLogInfo(@"Scanning stopped");
        
        // Clear the data that we may already have
        [self.data setLength:0];
        
        // Make sure we get the discovery callbacks
        peripheral.delegate = self;
        
        BLEPeripheral *blePeripheral = [[BLEPeripheral alloc ] initWithPeripheral: peripheral];
        blePeripheral.delegate = self;
        blePeripheral.peripheral.delegate = self;
        blePeripheral.tagNumber = tagNumber;
        
        [self.peripherals addObject:blePeripheral];
        tagNumber = tagNumber + 1;
        [blePeripheral startReadingRSS];
        [blePeripheral.peripheral discoverServices:@[[CBUUID UUIDWithString:serviceComms]]];
        
        DBLogInfo(@"Peripheral: name: %@, services: %@", blePeripheral.peripheral.name, [blePeripheral.peripheral services]);
        
        SEL selector = NSSelectorFromString(@"bleCentralControllerDidConnectToPeripheral:");
        if ([delegate respondsToSelector:selector])
            [self.delegate performSelector:selector withObject:peripheral];
    }
    else {
        DBLogInfo(@"Peripheral already exists!");
    }
    
    for (BLEPeripheral *blePeripheral in self.peripherals) {
        DBLogInfo(@"Tap: %@, peripheral: %@", blePeripheral, blePeripheral.peripheral);
    }
}

//===================================================================================
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
{
    DBLogMethod(@"%s");
    
    NSString *message = [NSString stringWithFormat:@"A peripheral disconnected: %@", peripheral.name];
    DBLogInfo(@"%@", message);
    
    for (BLEPeripheral *blePeripheral in self.peripherals) {
        if (blePeripheral.peripheral == peripheral) {
            blePeripheral.peripheral.delegate = nil;
            [self.peripherals removeObject:blePeripheral];
            break;
        }
    }
    
    for (BLEPeripheral *blePeripheral in self.peripherals) {
        DBLogInfo(@"Peripheral: %@", blePeripheral.peripheral);
    }

    //[self startManager];
    //[self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
}

//===================================================================================
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    DBLogInfo(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    [self cleanup];
}

#pragma mark - CBPeripheral Delegate Methods
//===================================================================================
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    DBLogMethod(@"%s");
    
    NSString *message = [NSString stringWithFormat:@"Peripheral services discovered for peripheral %@", peripheral];
    DBLogInfo(@"%@",message);
    
    if (error) {
        DBLogInfo(@"Error discovering service: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    for (CBService *service in peripheral.services) {
        
        NSString *message = [NSString stringWithFormat:@"Service found with UUID: %@", service.UUID];
        DBLogInfo(@"%@",message);
        
        // Discovers the characteristics for a given service
        if ([service.UUID isEqual:[CBUUID UUIDWithString:serviceComms]]) {
            [self.discoveredPeripheral discoverCharacteristics:@[[CBUUID UUIDWithString:charCommsTx]] forService:service];
            [self.discoveredPeripheral discoverCharacteristics:@[[CBUUID UUIDWithString:charCommsRx]] forService:service];
        }
        //Discover all characteriestics
        //[self.discoveredPeripheral discoverCharacteristics:nil forService:service];
    }
}

//===================================================================================
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    DBLogMethod(@"%s");
    
    NSString *message = [NSString stringWithFormat:@"Characteristics discovered for peripheral %@ with service %@", peripheral, service];
    DBLogInfo(@"%@", message);
    
    if (error) {
        DBLogInfo(@"Error discovering characteristic: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }

    if ([service.UUID isEqual:[CBUUID UUIDWithString:serviceComms]]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:charCommsTx]]) {
                DBLogInfo(@"TX Characteristic found");
                self.txCharacteristic = characteristic;
                // If it is, subscribe to it
                //[peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:charCommsRx]]) {
                DBLogInfo(@"RX Characteristic found");
                self.rxCharacteristic = characteristic;
            }
        }
    }
}

//===================================================================================
- (void)subscribeToComms
{
    [self.discoveredPeripheral setNotifyValue:YES forCharacteristic:self.txCharacteristic];
}


//===================================================================================
- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error;
{
    BLEPeripheral *blePeripheral = [self parentForPeripheral:peripheral];
    
    if(blePeripheral != nil)
    {
        [blePeripheral sampleRSSI];
    }
}

//===================================================================================
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    DBLogMethod(@"%s");
    
    if (error) {
        DBLogInfo(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Exits if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:charCommsTx]]) {
        DBLogInfo(@"Not the right characteristic");
        return;
    }
    
    // Notification has started
    if (characteristic.isNotifying) {
        DBLogInfo(@"Notification began on %@", characteristic);
        //[peripheral readValueForCharacteristic:characteristic];
    } else { // Notification has stopped
        // so disconnect from the peripheral
        DBLogInfo(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
    }
}

//===================================================================================
- (void)updateMessageForPeripheral: (CBPeripheral *)peripheral characteristic:(CBCharacteristic *)characteristic {
    
    DBLogMethod(@"%s");
    
    //incomingMessage = true;

    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    //NSString *stringFromData = toHexString(characteristic.value, @" ");
    DBLogVerbose(@"StringFromData: %@", stringFromData);
    
    // Have we got everything we need?
    if ([stringFromData isEqualToString:@"EOM"]) {
        DBLogVerbose(@"EOM received");
        DBLogVerbose(@"DONE");
        
        //NSString *fullMessage = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
        NSString *fullMessage = toHexString(self.data, @" ");
        DBLogInfo(@"Message received: %@", fullMessage);
        
        SEL selector = NSSelectorFromString(@"bleCentralControllerDidReceiveMessage:");
        if ([(id)self.delegate respondsToSelector:selector])
            [(id)self.delegate performSelector:selector withObject:self.data];

        [self.data setLength:0];
        incomingMessage = false;

        //ERM
        //Comment out follow to disallow disconnect
        // Cancel our subscription to the characteristic
        //[peripheral setNotifyValue:NO forCharacteristic:characteristic];
        
        // and disconnect from the peripehral
        //[self.centralManager cancelPeripheralConnection:peripheral];
        
        [self bleCentralControllerDidReceiveData];
    }
    else {
    // Otherwise, just add the data on to what we already have
    [self.data appendData:characteristic.value];
    }
}

//===================================================================================
- (void)sendMessageWithPayload:(NSData *)message;
{
    DBLogMethod(@"%s");
    DBLogInfo(@"withMessage: %@", message);
    NSMutableArray *frags = [self subFragment:message];
    for(NSData* d in frags) {
      [self.discoveredPeripheral writeValue:d forCharacteristic:self.rxCharacteristic type:CBCharacteristicWriteWithResponse];
    }
    
    //[self.discoveredPeripheral writeValue:message forCharacteristic:self.rxCharacteristic type:CBCharacteristicWriteWithResponse];
    
    SEL selector = NSSelectorFromString(@"bleCentralControllerDidSendMessage:");
    if ([self.delegate respondsToSelector:selector]) {
        [self.delegate performSelector:selector withObject:message];
    }
}

//===================================================================================
- (NSMutableArray *)subFragment:(NSData *)message;
{
    NSMutableArray *output = [[NSMutableArray alloc] init];
    int split = 128 - 5;
    int reps = floor(message.length/split);
    DBLogInfo(@"reps:  %d", reps);
    if(reps == 0 ) [output addObject:message];
    else {
        for ( int i = 0; i<reps; i++){
            [output addObject:[[NSData alloc] initWithData:[message subdataWithRange:NSMakeRange(i*split, split)]]];
        }
        if(message.length % split != 0) [output addObject:[[NSData alloc] initWithData:[message subdataWithRange:NSMakeRange(reps*split, message.length % split)]]];
    }
    [output addObject:[@"45 4F 4D" dataFromHexString]];

    DBLogInfo(@"Fragmented Command: ");
    for(NSData *d in output) DBLogInfo(@"%@", d);

    return output;
}

//===================================================================================
- (void)bleCentralControllerDidReceiveData; {
    DBLogMethod(@"%s");
    
    SEL selector = NSSelectorFromString(@"bleCentralControllerDidReceiveData");
    if ([self.delegate respondsToSelector:selector]) {
        [self.delegate performSelector:selector];
    }
}

//===================================================================================
/** This callback lets us know more data has arrived via notification on the characteristic
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    DBLogMethod(@"%s");
    
    if (!incomingMessage) {
        SEL selector = NSSelectorFromString(@"bleCentralControllerDidStartReceivingMessage:");
        if ([(id)self.delegate respondsToSelector:selector])
            [(id)self.delegate performSelector:selector withObject:nil];
        incomingMessage = true;
    }

    if (error) {
        DBLogInfo(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    [self updateMessageForPeripheral:peripheral characteristic:characteristic];
}

#pragma mark - BLEPeripheral Methods
//===================================================================================
- (BLEPeripheral *)parentForPeripheral:(CBPeripheral *)peripheral;
{
    for (BLEPeripheral *blePeripheral in self.peripherals) {
        if (blePeripheral.peripheral == peripheral) {
            return blePeripheral;
        }
    }
    return nil;
}

//===================================================================================
- (void)peripheral:(CBPeripheral *)peripheral
       didReadRSSI:(NSNumber *)RSSI
             error:(NSError *)error;

{
    //DBLogMethod(@"%s");    
}

#pragma mark -
#pragma mark Cleanup Methods
//===================================================================================
/** Call this when things either go wrong, or you're done with the connection.
 *  This cancels any subscriptions if there are any, or straight disconnects if not.
 *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
 */
- (void)cleanup
{
    DBLogMethod(@"%s");
    
    // Don't do anything if we're not connected
    if (self.discoveredPeripheral.state != CBPeripheralStateConnected) {
        return;
    }
    
    // See if we are subscribed to a characteristic on the peripheral
    if (self.discoveredPeripheral.services != nil) {
        for (CBService *service in self.discoveredPeripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:charCommsTx]]) {
                        if (characteristic.isNotifying) {
                            // It is notifying, so unsubscribe
                            [self.discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                            
                            // And we're done.
                            return;
                        }
                    }
                }
            }
        }
    }
    
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
}

//===================================================================================
- (void)didReceiveMemoryWarning
{
    DBLogMethod(@"%s");

    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
