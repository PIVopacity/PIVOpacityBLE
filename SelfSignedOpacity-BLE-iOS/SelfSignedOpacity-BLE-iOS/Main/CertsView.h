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
@class MainViewController;

@interface CertsView : UIView {
    MainViewController *delegate;
    UITextField *daysValidField;
    UITextField *encryptionFlavorField;
    UITextView *logTextView;
}

@property (nonatomic, assign) MainViewController *delegate;
@property (nonatomic, retain) UITextField *daysValidField;
@property (nonatomic, retain) UITextField *encryptionFlavorField;
@property (nonatomic, retain) UITextView *logTextView;


- (id)initWithFrame:(CGRect)frame delegate:(MainViewController *)delegate;
- (void)appendLogWithMessage:(NSString *)message;

@end
