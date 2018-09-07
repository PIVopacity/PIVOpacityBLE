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
#import "CertsView.h"
#import "PACSView.h"
#import "AuthView.h"
#import "KeystoreView.h"
#import "BLEPeripheralController.h"
#import "BLECentralController.h"
#import "OpacityParser.h"

@interface MainViewController : UIViewController <UIAlertViewDelegate, UIScrollViewDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate, BLEPeripheralControllerDelegate, BLECentralControllerDelegate>
{
    UISegmentedControl *segmentedControl;
    UIScrollView *scrollView;
    CertsView *certsView;
    UIPickerView *daysValidPicker;
    NSArray *daysValid;
    UIPickerView *encryptionFlavorPicker;
    NSArray *encryptionFlavor;
    PACSView *pacsView;
    AuthView *authView;
    KeystoreView *keystoreView;
    BLEPeripheralController *blePeripheralController;
    BLECentralController *bleCentralController;
    NSData *txData;
    NSData *rxData;
    NSMutableData *longCommand;
}

@property (nonatomic, retain) UISegmentedControl *segmentedControl;
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) CertsView *certsView;
@property (nonatomic, retain) UIPickerView *daysValidPicker;
@property (nonatomic, retain) NSArray *daysValid;
@property (nonatomic, retain) UIPickerView *encryptionFlavorPicker;
@property (nonatomic, retain) NSArray *encryptionFlavor;
@property (nonatomic, retain) PACSView *pacsView;
@property (nonatomic, retain) AuthView *authView;
@property (nonatomic, retain) KeystoreView *keystoreView;
@property (nonatomic, retain) BLEPeripheralController *blePeripheralController;
@property (nonatomic, retain) BLECentralController *bleCentralController;
@property (nonatomic, retain) NSData *txData;
@property (nonatomic, retain) NSData *rxData;
@property (nonatomic, retain) NSMutableData *longCommand;
@property (nonatomic) BOOL AUTHENTICATE;

@end

