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


@interface MyApp : NSObject {

}

+ (int)appid;
+ (NSString *)appName;
+ (NSString *)appBundleID;
+ (NSString *)appNameEscaped;
+ (NSString *)appShortName;
+ (NSString *)appStoreID;
+ (NSString *)versionFullString;
+ (NSString *)versionString;
+ (NSString *)buildString;


+ (void)setup;
+ (UIColor *)appTintColor;
+ (UIColor *)appColor;
+ (UIColor *)navBarBackgroundColor;
+ (UIColor *)navBarTextColor;
+ (UIColor *)toolbarBackgroundColor;
+ (UIColor *)toolbarTextColor;
+ (BOOL)isScannerDarkTheme;

@end
