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

#import "PACSView.h"

@implementation  PACSView

@synthesize delegate;
@synthesize schemeField;
@synthesize devicesField;
@synthesize logTextView;

//===================================================================================================================
- (id)initWithFrame:(CGRect)frame delegate:(MainViewController *)delegate;
{
    DBLogMethod(@"%s");

    if (self = [super initWithFrame:frame]) {

        self.delegate = delegate;
        self.backgroundColor = [UIColor whiteColor];
        
        CGFloat buttonHeight = 38;
        CGFloat buttonWidth = 100;
        UIColor *buttonColor = [UIColor colorWithRed:210/255.0 green:210/255.0 blue:210/255.0 alpha:1.0];
        UIColor *buttonColorPressed = [UIColor darkGrayColor];
        
        UIButton *scanButton = [MyButtons buttonWithTitle:@"SCAN BLE"
                                                         target:self
                                                       selector:@selector(scanBLEPressed:)
                                                          frame:CGRectMake(20,30,buttonWidth,buttonHeight)
                                                     buttonSize:0
                                                          image:[MyImages imageWithColor:buttonColor]
                                                   imagePressed:[MyImages imageWithColor:buttonColorPressed]
                                                   overlayImage:nil
                                            overlayImagePressed:nil
                                                       darkText:YES
                                                        revText:YES
                                                  darkTextColor:[UIColor colorWithRed:70/255.0 green:70/255.0 blue:70/255.0 alpha:1.0]
                                                   revTextColor:[UIColor whiteColor]
                                                       boldText:YES
                                                       fontSize:14.0
                                                         radius:3.0];
        [self addSubview:scanButton];
        [scanButton release];
        
    //Scheme Field
        CGFloat fieldHeight = 40;
        UITextField *aField = [[UITextField alloc] initWithFrame:CGRectMake(160,36,180,30)];
        aField.delegate = (id)self.delegate;
        aField.textColor = [UIColor colorWithRed:70/255.0 green:70/255.0 blue:70/255.0 alpha:1.0];
        aField.textAlignment = NSTextAlignmentLeft;
        aField.borderStyle = UITextBorderStyleNone;
        aField.font = [UIFont systemFontOfSize: 18.0];
        aField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        aField.tag = 0;
        aField.enabled = YES;
        aField.text = @"128-bit Opacity";
        
        [self addSubview:aField];
        [aField release];
        self.schemeField = aField;
        [aField release];
        
    //Devices Label
        UILabel *certLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 90, 110, 30)];
        certLabel.font = [UIFont boldSystemFontOfSize:18.0];
        certLabel.backgroundColor = [UIColor clearColor];
        certLabel.textColor = [UIColor colorWithRed:70/255.0 green:70/255.0 blue:70/255.0 alpha:1.0];
        certLabel.highlightedTextColor = [UIColor whiteColor];
        certLabel.textAlignment = NSTextAlignmentLeft;
        certLabel.lineBreakMode = NSLineBreakByWordWrapping;
        certLabel.numberOfLines = 0;
        certLabel.text = @"Device:";
        
        [self addSubview:certLabel];
        [certLabel release];

    //Devices Field
        fieldHeight = 40;
        aField = [[UITextField alloc] initWithFrame:CGRectMake(110,90,200,30)];
        aField.delegate = (id)self.delegate;
        aField.textColor = [UIColor colorWithRed:70/255.0 green:70/255.0 blue:70/255.0 alpha:1.0];
        aField.textAlignment = NSTextAlignmentLeft;
        aField.borderStyle = UITextBorderStyleNone;
        aField.font = [UIFont boldSystemFontOfSize: 18.0];
        aField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        aField.tag = 1;
        aField.enabled = NO;
        aField.text = @"None";

        [self addSubview:aField];
        [aField release];
        self.devicesField = aField;
        [aField release];
        
        buttonHeight = 38;
        buttonWidth = 100;
        
        UIButton *clearLogButton = [MyButtons buttonWithTitle:@"CLEAR LOG"
                                                       target:self
                                                     selector:@selector(clearLogPressed:)
                                                        frame:CGRectMake(255,140,buttonWidth,buttonHeight)
                                                   buttonSize:0
                                                        image:[MyImages imageWithColor:buttonColor]
                                                 imagePressed:[MyImages imageWithColor:buttonColorPressed]
                                                 overlayImage:nil
                                          overlayImagePressed:nil
                                                     darkText:YES
                                                      revText:YES
                                                darkTextColor:[UIColor colorWithRed:70/255.0 green:70/255.0 blue:70/255.0 alpha:1.0]
                                                 revTextColor:[UIColor whiteColor]
                                                     boldText:YES
                                                     fontSize:14.0
                                                       radius:3.0];
        [self addSubview:clearLogButton];
        [clearLogButton release];
        
        buttonHeight = 38;
        buttonWidth = 180;
        
        UIButton *authenticateButton = [MyButtons buttonWithTitle:@"AUTHENTICATE"
                                                       target:self
                                                     selector:@selector(authenticatePressed:)
                                                        frame:CGRectMake(20,140,buttonWidth,buttonHeight)
                                                   buttonSize:0
                                                        image:[MyImages imageWithColor:buttonColor]
                                                 imagePressed:[MyImages imageWithColor:buttonColorPressed]
                                                 overlayImage:nil
                                          overlayImagePressed:nil
                                                     darkText:YES
                                                      revText:YES
                                                darkTextColor:[UIColor colorWithRed:70/255.0 green:70/255.0 blue:70/255.0 alpha:1.0]
                                                 revTextColor:[UIColor whiteColor]
                                                     boldText:YES
                                                     fontSize:14.0
                                                       radius:3.0];
        [self addSubview:authenticateButton];
        [authenticateButton release];
        
        
        UIButton *sendTestMessageButton = [MyButtons buttonWithTitle:@"SEND TEST MESSAGE"
                                                           target:self
                                                         selector:@selector(sendTestMessagePressed:)
                                                            frame:CGRectMake(20,190,buttonWidth,buttonHeight)
                                                       buttonSize:0
                                                            image:[MyImages imageWithColor:buttonColor]
                                                     imagePressed:[MyImages imageWithColor:buttonColorPressed]
                                                     overlayImage:nil
                                              overlayImagePressed:nil
                                                         darkText:YES
                                                          revText:YES
                                                    darkTextColor:[UIColor colorWithRed:70/255.0 green:70/255.0 blue:70/255.0 alpha:1.0]
                                                     revTextColor:[UIColor whiteColor]
                                                         boldText:YES
                                                         fontSize:14.0
                                                           radius:3.0];
        [self addSubview:sendTestMessageButton];
        [sendTestMessageButton release];

        
        CGFloat yOffset = 240.0;
        CGFloat padding = 20.0;
        
        UITextView *aLogTextView = [[UITextView alloc] initWithFrame: CGRectMake(0,yOffset,[MyDevice screenShort],[MyDevice screenLong] - yOffset -100)];
        
        [aLogTextView setTextContainerInset:UIEdgeInsetsMake(padding, padding, 0, 0)];
        aLogTextView.backgroundColor = [UIColor clearColor];
        aLogTextView.font = [UIFont systemFontOfSize:12.0];
        aLogTextView.textColor = [UIColor colorWithRed:70/255.0 green:70/255.0 blue:70/255.0 alpha:1.0];
        aLogTextView.textAlignment = NSTextAlignmentLeft;
        aLogTextView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        aLogTextView.userInteractionEnabled = YES;
        aLogTextView.scrollEnabled = YES;
        aLogTextView.editable = NO;
        
        [self addSubview:aLogTextView];
        [aLogTextView release];
        self.logTextView = aLogTextView;
        [aLogTextView release];
        
        

        
    }
    return self;
}

//===================================================================================================================
- (void)scanBLEPressed:(id)sender;
{
    DBLogMethod(@"%s");
    
    self.devicesField.text = @"None";
    
    SEL selector = NSSelectorFromString(@"scanBLE:");
    if ([delegate respondsToSelector:selector])
        [self.delegate performSelector:selector];
}

//===================================================================================================================
- (void)clearLogPressed:(id)sender;
{
    DBLogMethod(@"%s");
    
    self.logTextView.text = @"";
    
    SEL selector = NSSelectorFromString(@"clearLog:");
    if ([delegate respondsToSelector:selector])
        [self.delegate performSelector:selector];
}

//===================================================================================================================
- (void)authenticatePressed:(id)sender;
{
    DBLogMethod(@"%s");
    
    SEL selector = NSSelectorFromString(@"authenticate:");
    if ([delegate respondsToSelector:selector])
        [self.delegate performSelector:selector];
}

//===================================================================================================================
- (void)sendTestMessagePressed:(id)sender;
{
    DBLogMethod(@"%s");
    
    SEL selector = NSSelectorFromString(@"sendTestMessageToPeripheral:");
    if ([delegate respondsToSelector:selector])
        [self.delegate performSelector:selector];
}


//===================================================================================================================
- (void)appendLogWithMessage:(NSString *)message;
{
    DBLogMethod(@"%s");
    
    NSString *newLog = [NSString stringWithFormat: @"%@\r%@", self.logTextView.text, message];

    self.logTextView.text = newLog;

    [self scrollTextViewToBottom:self.logTextView];
    
    SEL selector = NSSelectorFromString(@"clearLog:");
    if ([delegate respondsToSelector:selector])
        [self.delegate performSelector:selector];
}

//===================================================================================================================
-(void)scrollTextViewToBottom:(UITextView *)textView
{
    DBLogMethod(@"%s");

    if(textView.text.length > 0 )
    {
        NSRange bottom = NSMakeRange(textView.text.length -1, 1);
        [textView scrollRangeToVisible:bottom];
    }
}

@end
