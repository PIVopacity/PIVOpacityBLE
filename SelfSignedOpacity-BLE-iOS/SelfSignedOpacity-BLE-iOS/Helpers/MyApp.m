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


#import "MyApp.h"

@implementation MyApp


//===================================================================================================================
+ (int) appid;
{
	return (appIDs)[[NSUserDefaults standardUserDefaults] integerForKey:@"appid"];
}

//===================================================================================================================
+ (NSString *)appName;
{
	DBLogMethod(@"%s");
    
    NSString *appBundleID = [self appBundleID];
    NSString *appName;
    
    if ([appBundleID isEqualToString:@"com.tapbase.OpacityBLE"]) {
        appName = @"OpacityBLE";
	}
	else {
        appName = @"";
	}
    
    return appName;
}

//===================================================================================================================
+ (NSString *)appBundleID;
{
	DBLogMethod(@"%s");
    
	return  [[NSBundle mainBundle] bundleIdentifier];
}

//===================================================================================================================
+ (NSString *)appNameEscaped;
{
	DBLogMethod(@"%s");
	
	return [[self appName] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
}

//===================================================================================================================
+ (NSString *)appShortName;
{
	DBLogMethod(@"%s");
	
	return [[NSUserDefaults standardUserDefaults] valueForKey:@"appShortName"];
}

//===================================================================================================================
+ (NSString *)appStoreID;
{
	DBLogMethod(@"%s");
	
	return [[NSUserDefaults standardUserDefaults] valueForKey:@"appStoreID"];
}

//===================================================================================================================
+ (NSString *)versionFullString;
{
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    return [NSString stringWithFormat:@"v%@ (Build %@)", version, build];
}

//===================================================================================================================
+ (NSString *)versionString;
{
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return [NSString stringWithFormat:@"v%@", version];
}

//===================================================================================================================
+ (NSString *)buildString;
{
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    return [NSString stringWithFormat:@"%@", build];
}

//===================================================================================================================
+ (void)setup;
{
	DBLogMethod(@"%s");
    
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
	int appid;
	NSString *appShortName;
	NSString *appName = [self appName];
    NSString *appBundleID = [self appBundleID];
	NSString *appStoreID;
    
    appid = 0;
    appShortName = @"";
    appStoreID = @"";

    [defaults setInteger:appid forKey:@"appid"];
	[defaults setValue:appShortName forKey:@"appShortName"];
	[defaults setValue:appName forKey:@"appName"];
	[defaults setValue:appStoreID forKey:@"appStoreID"];
    
    DBLogInfo(@"appid = %i", appid);
    DBLogInfo(@"appShortName = %@", appShortName);
    DBLogInfo(@"appName = %@", appShortName);
    DBLogInfo(@"appStoreID = %@", appStoreID);
}


+ (UIColor *)appTintColor;
{
    
    return [UIColor blackColor];
}


+ (UIColor *)appColor;
{
    UIColor *color;
    color = [UIColor orangeColor];
    return color;
}

+ (UIColor *)navBarBackgroundColor;
{
    UIColor *color;
    
    switch ([MyApp appid]) {
        default:
            color = [UIColor orangeColor];
            break;
    }
    return color;
}

+ (UIColor *)navBarTextColor;
{
    UIColor *color;
    switch ([MyApp appid]) {
        default:
            color = [UIColor whiteColor];
            break;
        }
    return color;
}

+ (UIColor *)toolbarBackgroundColor;
{
    UIColor *color;
    switch ([MyApp appid]) {
        default:
            color = [UIColor colorWithRed:70/255.0 green:70/255.0 blue:70/255.0 alpha:1.0];
            break;
    }
    return color;
}

+ (UIColor *)toolbarTextColor;
{
    UIColor *color;
    switch ([MyApp appid]) {
        default:
            color = [UIColor lightGrayColor];
            break;
    }
    return color;
}

+ (BOOL)isScannerDarkTheme;
{
    DBLogMethod(@"%s");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *theme = [defaults objectForKey:@"appPrefs_ScannerColorTheme"];

    return [theme isEqualToString:@"Dark"];
}


@end
