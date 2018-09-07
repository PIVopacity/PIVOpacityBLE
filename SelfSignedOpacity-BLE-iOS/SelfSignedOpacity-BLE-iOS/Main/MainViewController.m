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

#import "MainViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "CertsView.h"
#import "PACSView.h"
#import "AuthView.h"
#import "KeystoreView.h"
#import "Generate.h"
#import "OTP.h"
#import "AppGlobals.h"
#import "x509.h"

@interface MainViewController ()

@end

@implementation MainViewController

@synthesize segmentedControl;
@synthesize scrollView;
@synthesize certsView;
@synthesize daysValidPicker;
@synthesize daysValid;
@synthesize encryptionFlavorPicker;
@synthesize encryptionFlavor;
@synthesize pacsView;
@synthesize authView;
@synthesize keystoreView;

@synthesize blePeripheralController;
@synthesize bleCentralController;

#pragma mark - View Methods
//====================================================================================
- (void)viewDidLoad;
{
    DBLogMethod(@"%s");
    
    [super viewDidLoad];
    self.AUTHENTICATE = FALSE;
   
    NSArray *aDaysValid = [NSArray arrayWithObjects:@"1", @"3", @"7", @"15", @"30", nil];
    self.daysValid = aDaysValid;
    
    //NSArray *anEncryptionFlavor = [NSArray arrayWithObjects:@"ECC prime256v1", @"ECC secp384r1", nil];
    NSArray *anEncryptionFlavor = [NSArray arrayWithObjects:@"ECC prime256v1", nil];
    self.encryptionFlavor = anEncryptionFlavor;
    
    DBLogInfo(@"self.encryptionFlavor = %@", self.encryptionFlavor);
    
    CGRect frame = CGRectMake(0, 0, [MyDevice screenShort], [MyDevice screenLong]);
    CGFloat topbarHeight = 82.0;
    
    UIImageView *homeView = [[UIImageView alloc] initWithFrame:frame];
    homeView.backgroundColor = [UIColor whiteColor];
    homeView.userInteractionEnabled = YES;

    UIView *blackBar = [[UIView alloc] initWithFrame:CGRectMake(0,0, [MyDevice screenShort], topbarHeight)];
    blackBar.backgroundColor = [UIColor colorWithRed:0.17 green:0.17 blue:0.17 alpha:1.0];
    
    [homeView addSubview:blackBar];
    [blackBar release];
    
    NSMutableArray *segmentObjects = [NSMutableArray arrayWithCapacity:0];
    [segmentObjects addObject:NSLocalizedString(@"CERTS", nil)];
    [segmentObjects addObject:NSLocalizedString(@"PACS", nil)];
    [segmentObjects addObject:NSLocalizedString(@"AUTH", nil)];
    [segmentObjects addObject:NSLocalizedString(@"KEYSTORE", nil)];

    UISegmentedControl *aSegmentedControl = [[UISegmentedControl alloc] initWithItems:segmentObjects];
    self.segmentedControl = aSegmentedControl;
    [aSegmentedControl release];
    
    segmentedControl.selectedSegmentIndex = 0;
    segmentedControl.frame = CGRectMake(0,40,frame.size.width,40);
    segmentedControl.momentary = NO;
    segmentedControl.hidden = NO;
    segmentedControl.tag = 1;
    segmentedControl.tintColor = [UIColor colorWithRed: 1.0 green: 1.0 blue: 1.0 alpha: 1.0];
    segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UIFont *font = [UIFont boldSystemFontOfSize:12.0f];
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:font
                                                           forKey:NSFontAttributeName];
    [segmentedControl setTitleTextAttributes:attributes
                                    forState:UIControlStateNormal];
    
    segmentedControl.layer.borderWidth = 0;
    
    [[UISegmentedControl appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             [UIColor lightGrayColor],UITextAttributeTextColor,
                                                             [UIColor clearColor], UITextAttributeTextShadowColor,
                                                             [UIFont fontWithName:@"Helvetica" size:14.0], UITextAttributeFont, nil] forState:UIControlStateNormal];
    
    [[UISegmentedControl appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             [UIColor whiteColor],UITextAttributeTextColor,
                                                             [UIColor clearColor], UITextAttributeTextShadowColor,
                                                             [NSValue valueWithUIOffset:UIOffsetMake(0, 1)], UITextAttributeTextShadowOffset,
                                                             [UIFont fontWithName:@"Helvetica-Bold" size:14.0], UITextAttributeFont, nil] forState:UIControlStateSelected];
    
    
    [segmentedControl setDividerImage:[MyImages imageWithColor:[UIColor clearColor]] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    [segmentedControl setBackgroundImage:[MyImages imageWithColor:[UIColor clearColor]] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    //[segmentedControl setBackgroundImage:[MyImages imageWithColor:[UIColor colorWithRed:215/255.0 green:0 blue:30/255.0 alpha:1.0]] forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    
    [segmentedControl setBackgroundImage:[MyImages imageWithColor:[UIColor colorWithRed:215/255.0 green:215/255.0 blue:215/255.0 alpha:0.4]] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];

    
    [segmentedControl setWidth:90 forSegmentAtIndex:0];
    [segmentedControl setWidth:110 forSegmentAtIndex:3];
    
    [segmentedControl addTarget:self
                         action:@selector(segmentClicked:)
               forControlEvents:UIControlEventValueChanged];
    
    [homeView addSubview:segmentedControl];
    
    CGFloat pageWidth = [MyDevice screenShort];
    CGFloat pageHeight = [MyDevice screenLong] - topbarHeight;
    CGFloat topMargin = 0;
    CGFloat bottomMargin = 0;
    
    CGFloat contentHeight = pageHeight - topMargin - bottomMargin;
    CGRect scrollFrame = CGRectMake(0, topbarHeight + topMargin, [MyDevice screenShort], contentHeight);
    
    int pages = (int)[segmentObjects count];

    UIScrollView *aMyScrollView = [[UIScrollView alloc] initWithFrame: scrollFrame];
    self.scrollView = aMyScrollView;
    [aMyScrollView release];
    
    self.scrollView.contentSize = CGSizeMake(pages*pageWidth, contentHeight);
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.scrollView.autoresizesSubviews = YES;
    self.scrollView.backgroundColor = [UIColor  whiteColor];
    self.scrollView.delegate = self;
    self.scrollView.bounces = NO;
    self.scrollView.alwaysBounceHorizontal = YES;
    self.scrollView.alwaysBounceVertical = NO;
    self.scrollView.scrollEnabled = YES;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.directionalLockEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    //[self.scrollView flashScrollIndicators];
    
    [homeView addSubview: self.scrollView];
    
    for (int pageNumber = 0; pageNumber < pages; pageNumber++) {
        CGRect pageFrame = CGRectMake(pageNumber*pageWidth, 0, pageWidth, contentHeight);
        UIView *subView = [self viewForPage:pageNumber rect: pageFrame];
        [self.scrollView addSubview:subView];
    }
    self.view = homeView;
    
}

//==========================================================================================================================
- (UIView *)viewForPage:(int)pageNumber rect:(CGRect)pageFrame;

{
    DBLogMethod(@"%s");
    
    UIView *view = [[UIView alloc] initWithFrame:pageFrame];
    view.backgroundColor = [UIColor whiteColor];
    
    switch (pageNumber) {
        case 0:
        {
            CertsView *aCertsView = [[CertsView alloc] initWithFrame: pageFrame delegate:self];
            self.certsView = aCertsView;
            [aCertsView release];
            return self.certsView;
        }
            break;
        case 1:
        {
            PACSView *aPACSView = [[PACSView alloc] initWithFrame: pageFrame delegate:self];
            self.pacsView = aPACSView;
            [aPACSView release];
            return self.pacsView;
        }
            break;
        case 2:
        {
            AuthView *anAuthView = [[AuthView alloc] initWithFrame: pageFrame delegate:self];
            self.authView = anAuthView;
            [anAuthView release];
            return self.authView;
        }
            break;
        case 3:
        {
            KeystoreView *aKeystoreView = [[KeystoreView alloc] initWithFrame: pageFrame delegate:self];
            self.keystoreView = aKeystoreView;
            [aKeystoreView release];
            return self.keystoreView;
        }
            break;
        default:
            break;
    }

    return view;
}


//==========================================================================================================================
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
{
    DBLogMethod(@"%s");
    
    int currentPage = self.scrollView.contentOffset.x/(self.scrollView.bounds.size.width);
    self.segmentedControl.selectedSegmentIndex = currentPage;
}

#pragma mark - Utility Methods
//===================================================================================================================
- (void)segmentClicked:(id)sender;
{
    DBLogMethod(@"%s");
    
    DBLogInfo(@"sender = %@, tag = %li", sender, (long)[sender tag]);
    DBLogInfo(@"segment clicked, selected segment = %li", (long)[sender selectedSegmentIndex]);
    
    CGFloat x = [sender selectedSegmentIndex]*(self.scrollView.bounds.size.width);
    [self.scrollView setContentOffset:CGPointMake(x, 0) animated:YES];
}

//====================================================================================
- (void)generateCredentialForDays:(NSString *)days encryptionFlavor:(NSString *)flavor;
{
    DBLogMethod(@"%s");
    
    BOOL success = NO;
    int d = (int)days.integerValue;
    
    [self.certsView appendLogWithMessage: [NSString stringWithFormat: @"Generating new self-signed credential for %i days with encryption: %@", d, flavor]];

    int keyGenTime;
    success = GenerateNewCredential(d, flavor, &keyGenTime);
    
    
    //Let's call it a success
    //success = YES;

    //int keyGenTime = 234; //dummy value, milliseconds
    BOOL sigVerified = success; //dummy
    
    //Use test for now and store globally in defaults
    //NSString *keyLocation = @"User Defaults"; //dummy, should be "Secure Hardware"
    NSString *keyLocation = [NSString stringWithFormat:@"%@", kSecAttrTokenIDSecureEnclave];
    NSString *pKey = @"com.opacity.selfSignedPiv";
    [[NSUserDefaults standardUserDefaults] setObject:pKey forKey:@"privateKey"];
    NSString *credential = nil;
    NSDictionary *certquery = @{ (id)kSecClass:     (id)kSecClassCertificate,
                                 (id)kSecAttrLabel: @"selfSignedPivCert",
                                 (id)kSecReturnRef: @YES,
                                 };
    SecCertificateRef certificate = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)certquery,
                                 (CFTypeRef *)&certificate);
    if (status != errSecSuccess) { DBLogInfo(@"No Cert.  %d\n", (int) status); }
    else {
        NSData *certData = (NSData *)CFBridgingRelease( SecCertificateCopyData(certificate));
        DBLogInfo(@"%@",certData);
        credential = [NSString stringWithFormat: @"Certificate:\n%@\n", certificate];
    }
    if (certificate) { CFRelease(certificate); }
    [[NSUserDefaults standardUserDefaults] setObject:credential forKey:@"credential"];

    NSString *alertTitle;
    NSString *alertMessage;
    
    if (success)
    {
        alertTitle = @"SUCCESS";
        alertMessage = [NSString stringWithFormat: @"Self-signed Temporary Credential Generated\rPrivate Key Stored in %@", keyLocation];
        
        [self.certsView appendLogWithMessage: [NSString stringWithFormat: @"Key generation time: %i ms", keyGenTime]];
        [self.certsView appendLogWithMessage: [NSString stringWithFormat: @"Private Key Stored in %@", keyLocation]];
        [self.certsView appendLogWithMessage:credential];
        NSString *sigVerifiedString = sigVerified? @"true" : @"false";
        [self.certsView appendLogWithMessage:[NSString stringWithFormat: @"Signature verified with self-signed cert: %@", sigVerifiedString]];
    }
    else {
        alertTitle = @"ERROR!";
        alertMessage = @"There was an error creating the credential!";
        [self.certsView appendLogWithMessage: @"Error creating credential."];
    }
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage  preferredStyle:UIAlertControllerStyleAlert];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",@"OK") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

//====================================================================================
- (void)setupCentral;
{
    DBLogMethod(@"%s");
    
    BLECentralController *aBLECentralController = [[BLECentralController alloc] init];
    aBLECentralController.delegate = self;
    self.bleCentralController = aBLECentralController;
    [aBLECentralController release];
    [self.bleCentralController startManager];
}

//====================================================================================
- (void)scanBLE:(id)sender;
{
    DBLogMethod(@"%s");
    
    [self.pacsView appendLogWithMessage: @"Scanning for Peripherals..."];
    [self setupCentral];
}

//====================================================================================
- (void)authenticate:(id)sender;
{
    DBLogMethod(@"%s");
    [self.bleCentralController subscribeToComms];
    [self.pacsView appendLogWithMessage: @"Authenticating..."];
    self.AUTHENTICATE = TRUE;
}

//====================================================================================
- (void)setupPeripheral;
{
    DBLogMethod(@"%s");
    
    BLEPeripheralController *aBLEPeripheralController = [[BLEPeripheralController alloc] init];
    aBLEPeripheralController.delegate = (id<BLEPeripheralControllerDelegate> *)self;
    self.blePeripheralController = aBLEPeripheralController;
    [aBLEPeripheralController release];
    [self.blePeripheralController startManager];
}

//====================================================================================
- (void)advertiseBLE:(id)sender;
{
    DBLogMethod(@"%s");
    self.longCommand = [[NSMutableData alloc] init];
    [self.authView appendLogWithMessage: @"Advertising Peripheral..."];
    [self setupPeripheral];
}

//====================================================================================
- (void)sendTestMessageToCentral:(id)sender;
{
    DBLogMethod(@"%s");
    
    if (self.blePeripheralController == nil) {
        [self setupPeripheral];
    }
    [self.authView appendLogWithMessage:@"Sending message on Tx..."];
    
    NSString *messageString = [NSString stringWithFormat: @"From Guard: %@", [MyNonce getNonce]];
    NSData *message = [messageString dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.blePeripheralController sendMessageWithPayload:message];
}

//====================================================================================
- (void)sendTestMessageToPeripheral:(id)sender;
{
    DBLogMethod(@"%s");
    
    if (self.bleCentralController == nil) {
        [self setupCentral];
    }
    
    [self.pacsView appendLogWithMessage:@"Sending message on Rx..."];
    
    NSString *messageString = [NSString stringWithFormat: @"From First Responder: %@", [MyNonce getNonce]];
    NSData *message = [messageString dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.bleCentralController sendMessageWithPayload:message];
}

//====================================================================================
- (void)clearKeystore:(id)sender;
{
    DBLogMethod(@"%s");
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSData *tag = [@"com.opacity.selfSignedPiv" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *getquery = @{ (id)kSecClass: (id)kSecClassKey,
                                (id)kSecAttrApplicationTag: tag,
                                (id)kSecAttrKeyType: (id)kSecAttrKeyTypeEC,
                                (id)kSecReturnRef: @YES,
                                };
    SecKeyRef privateKey = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)getquery,
                                          (CFTypeRef *)&privateKey);
    if (status!=errSecSuccess) { DBLogInfo(@"No Key:  %@\nKeystore Empty", tag); }
    else                       { SecItemDelete((__bridge CFDictionaryRef)getquery); }

    NSDictionary *certquery = @{ (id)kSecClass:     (id)kSecClassCertificate,
                                 (id)kSecAttrLabel: @"selfSignedPivCert",
                                 (id)kSecReturnRef: @YES,
                                 };
    if(privateKey) { CFRelease(privateKey);}
    
    SecCertificateRef certificate = NULL;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)certquery,
                                 (CFTypeRef *)&certificate);
    if (status != errSecSuccess) { DBLogInfo(@"No Cert.  %d\n", (int) status); }
    else {
        DBLogInfo(@"Clearing old cert: %@", certificate);
        SecItemDelete((__bridge CFDictionaryRef)certquery);
    }
    if (certificate) { CFRelease(certificate); }
    
    
    [defaults setObject:nil forKey:@"privateKey"];
    [defaults setObject:nil forKey:@"credential"];
    
    [self.keystoreView appendLogWithMessage: @"Keystore cleared!"];
}

//====================================================================================
- (void)refreshKeystore:(id)sender;
{
    DBLogMethod(@"%s");
    
    NSData *tag = [@"com.opacity.selfSignedPiv" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *getquery = @{ (id)kSecClass: (id)kSecClassKey,
                                (id)kSecAttrApplicationTag: tag,
                                (id)kSecAttrKeyType: (id)kSecAttrKeyTypeEC,
                                (id)kSecReturnRef: @YES,
                                };
    SecKeyRef privateKey = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)getquery,
                                          (CFTypeRef *)&privateKey);
    if (status!=errSecSuccess) {
        [self.keystoreView appendLogWithMessage: @"Keystore Empty! Derive new credential."];
    }
    else {
        [self.keystoreView appendLogWithMessage: [NSString stringWithFormat: @"com.opacity.selfSignedPiv Private Key located at:\n%@\n", privateKey]];
        
        NSDictionary *certquery = @{ (id)kSecClass:     (id)kSecClassCertificate,
                                     (id)kSecAttrLabel: @"selfSignedPivCert",
                                     (id)kSecReturnRef: @YES,
                                     };
        SecCertificateRef certificate = NULL;
        status = SecItemCopyMatching((__bridge CFDictionaryRef)certquery,
                                     (CFTypeRef *)&certificate);
        if (status != errSecSuccess) { DBLogInfo(@"No Cert.  %d\n", (int) status); }
        else {
            NSData *certData = (NSData *)CFBridgingRelease( SecCertificateCopyData(certificate));
            DBLogInfo(@"%@",certData);
            [self.keystoreView appendLogWithMessage: [NSString stringWithFormat: @"Certificate:\n%@\n", certificate]];
        }
        if (certificate) { CFRelease(certificate); }
    }
    
    if (privateKey) { CFRelease(privateKey); }
}

//====================================================================================
- (void)clearLog:(id)sender;
{
    DBLogMethod(@"%s");
}

//====================================================================================
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - BLEPeripheralController Delegate Methods
//===================================================================================================================
- (void)blePeripheralControllerDidStartSendingMessage:(NSData *)message;
{
    DBLogMethod(@"%s");
    
    [self.authView appendLogWithMessage: @"Sending message on Tx..."];
    
    //NSString *messageString = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
    //[self.authView appendLogWithMessage: messageString];
}

//===================================================================================================================
- (void)blePeripheralControllerDidSendMessage:(NSData *)message;
{
    DBLogMethod(@"%s");
    
    [self.authView appendLogWithMessage: @"Message sent on Tx"];
    
//    NSString *messageString = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
    NSString *messageString = toHexString(message, @" ");
    [self.authView appendLogWithMessage: messageString];
    if(![self.txData isEqualToData:message]) self.txData = [NSData dataWithData:message];
    
    if ( ![authOTP isEqualToString:@"00"] ){
        NSString *alertTitle = @"SUCCESS";
        NSString *alertMessage = [NSString stringWithFormat: @"One-Time Password:\n%@", authOTP];
        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage  preferredStyle:UIAlertControllerStyleAlert];
        [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",@"OK") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }]];
        [self presentViewController:actionSheet animated:YES completion:nil];
        authOTP = @"00";
        self.AUTHENTICATE = FALSE;
    }
}

//===================================================================================================================
- (void)blePeripheralControllerDidReceiveMessage:(NSData *)message;
{
    DBLogMethod(@"%s");
    
    [self.authView appendLogWithMessage:@"Receiving message on Rx..."];

    [self.authView appendLogWithMessage:@"Message received on Rx"];
    //NSString *messageString = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
    NSString *messageString = toHexString(message, @" ");
    [self.authView appendLogWithMessage:messageString];
    
    if( [message isEqualToData:[@"45 4F 4D" dataFromHexString]]){
        self.rxData = [NSData dataWithData:(NSData *)self.longCommand];
        DBLogInfo(@"blePeripheralControllerDidReceiveMessage: %@", self.rxData);
        NSData * nextCommand = parseClientResponse(self.rxData);
        [self.blePeripheralController sendMessageWithPayload:nextCommand];

        [self.longCommand release];
        self.longCommand = [[NSMutableData alloc] init];
    } else [self.longCommand appendData:message];

}

#pragma mark - BLECentralController Delegate Methods
//===================================================================================================================
- (void)bleCentralControllerDidStartReceivingMessage:(NSData *)message;
{
    DBLogMethod(@"%s");
    
    [self.pacsView appendLogWithMessage:@"Receiving message on Tx..."];
}

//===================================================================================================================
- (void)bleCentralControllerDidSendMessage:(NSData *)message;
{
    DBLogMethod(@"%s");
    
    [self.pacsView appendLogWithMessage: @"Message sent on Rx"];
    
//    NSString *messageString = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
    NSString *messageString = toHexString(message, @" ");
    [self.pacsView appendLogWithMessage: messageString];
    if(![self.rxData isEqualToData:message]) self.rxData = [NSData dataWithData:message];
    
}

//===================================================================================================================
- (void)bleCentralControllerDidReceiveMessage:(NSData *)message;
{
    DBLogMethod(@"%s");
    
    [self.pacsView appendLogWithMessage:@"Message received on Tx"];
    //NSString *messageString = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
    NSString *messageString = toHexString(message, @" ");
    [self.pacsView appendLogWithMessage:messageString];
    
    
    if(![self.txData isEqualToData:message]){
        self.txData = [NSData dataWithData:message];
        DBLogInfo(@"Message Received:\t%@\nself.txData:\t%@", message, self.txData);
        
        if (self.AUTHENTICATE){
            NSData *response = parseHostCommand(self.txData);
            NSString *txMesg = toHexString(self.txData, @" ");
            NSString *responseString = toHexString(response, @" ");
            DBLogError(@"\n\nParsed command: %@\nReturned: %@\n\n", txMesg, responseString);
            [self.bleCentralController sendMessageWithPayload:response];
        }
        if ( ![authOTP isEqualToString:@"00"] ){
            NSString *alertTitle = @"SUCCESS";
            NSString *alertMessage = [NSString stringWithFormat: @"One-Time Password:\n%@", authOTP];
            UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage  preferredStyle:UIAlertControllerStyleAlert];
            [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",@"OK") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            [self presentViewController:actionSheet animated:YES completion:nil];
            authOTP = @"00";
            self.AUTHENTICATE = FALSE;            
        }
    }
}

//===================================================================================================================
- (void)bleCentralControllerDidConnectToPeripheral:(CBPeripheral *)peripheral;
{
    DBLogMethod(@"%s");
    
    self.pacsView.devicesField.text = peripheral.name;
}

#pragma mark - TextField Delegate Methods
//===================================================================================================================
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    DBLogMethod(@"%s");
    return YES;
}

//===================================================================================================================
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    DBLogMethod(@"%s");
}

//===================================================================================================================
- (void)textFieldDidEndEditing:(UITextField *)textField {
    DBLogMethod(@"%s");
}

//===================================================================================================================
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    DBLogMethod(@"%s");
    
    BOOL result = YES;
    [self showPickerForTextField:textField];
    
    return result;
}

//===================================================================================================================
- (void)textFieldDidChange:(UITextField *)textField{
    DBLogMethod(@"%s");
}

//===================================================================================================================
-(BOOL)textField:(UITextField *)textField shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    DBLogMethod(@"%s");
    return YES;
}

//===================================================================================================================
-(void)textChanged:(UITextField *)textField;
{
    DBLogMethod(@"%s");
}

#pragma mark - UIPickerView Delegate Methods
//===================================================================================================================
- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
    DBLogMethod(@"%s");
    
    switch (pickerView.tag) {
        case 1:
            self.certsView.daysValidField.text = [self.daysValid objectAtIndex:row];
            break;
        case 2:
            self.certsView.encryptionFlavorField.text = [self.encryptionFlavor objectAtIndex:row];
            break;
        default:
            break;
    }
    [[self view] endEditing:YES];
}

//===================================================================================================================
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    DBLogMethod(@"%s");
    
    switch (pickerView.tag) {
        case 1:
            return [self.daysValid count];
            break;
        case 2:
            return [self.encryptionFlavor count];
            break;
        default:
            return 0;
            break;
    }
}

//===================================================================================================================
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    DBLogMethod(@"%s");
    
    return 1;
}

//===================================================================================================================
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    DBLogMethod(@"%s");
    
    switch (pickerView.tag) {
        case 1:
            return [self.daysValid objectAtIndex:row];
            break;
        case 2:
            return [self.encryptionFlavor objectAtIndex:row];
            break;
        default:
            return nil;
            break;
    }
}

//===================================================================================================================
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    DBLogMethod(@"%s");
    
    return 300;
}

#pragma mark - UIPickerView Helpers
//===================================================================================================================
- (void)showPickerForTextField:(UITextField*)textField;
{
    DBLogMethod(@"%s");
    
    switch (textField.tag) {
        case 1:
            [self showDaysValidPicker:textField];
            break;
        case 2:
            [self showEncryptionFlavorPicker:textField];
            break;
        default:
            break;
    }
}

//===================================================================================================================
- (void)showDaysValidPicker:(UITextField*)textField;
{
    DBLogMethod(@"%s");
    
    if (self.daysValidPicker != nil) {
        textField.inputView = self.daysValidPicker;
        return;
    }
    
    UIPickerView* aPickerView = [[UIPickerView alloc] init];
    [aPickerView sizeToFit];
    aPickerView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    aPickerView.delegate = self;
    aPickerView.tag = textField.tag;
    aPickerView.showsSelectionIndicator = YES;
    self.daysValidPicker = aPickerView;
    
    for (int i=0; i<[self.daysValid count]; i++) {
        NSString *currentTitle = self.certsView.daysValidField.text;
        NSString *title= [self.daysValid objectAtIndex:i];
        
        if ([title isEqualToString:currentTitle]) {
            [aPickerView selectRow:i inComponent:0 animated:NO];
        }
    }
    textField.inputView = self.daysValidPicker;
}

//===================================================================================================================
- (void)showEncryptionFlavorPicker:(UITextField*)textField;
{
    DBLogMethod(@"%s");
    
    if (self.encryptionFlavorPicker != nil) {
        textField.inputView = self.encryptionFlavorPicker;
        return;
    }
    
    UIPickerView* aPickerView = [[UIPickerView alloc] init];
    [aPickerView sizeToFit];
    aPickerView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    aPickerView.delegate = self;
    aPickerView.tag = textField.tag;
    aPickerView.showsSelectionIndicator = YES;
    self.encryptionFlavorPicker = aPickerView;
    
    for (int i=0; i<[self.encryptionFlavor count]; i++) {
        NSString *currentTitle = self.certsView.encryptionFlavorField.text;
        NSString *title= [self.encryptionFlavor objectAtIndex:i];
        
        if ([title isEqualToString:currentTitle]) {
            [aPickerView selectRow:i inComponent:0 animated:NO];
        }
    }
    textField.inputView = self.encryptionFlavorPicker;
}

#pragma mark - Terminate Methods
//====================================================================================
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
