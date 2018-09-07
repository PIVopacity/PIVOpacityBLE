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

#import "MyTimer.h"

@implementation MyTimer

@synthesize startDate, stopDate;


//===================================================================================================================
-(id)init;
{
    DBLogMethod(@"%s");
    
    if (self = [super init]) {
        self.startDate = [NSDate date];
        self.stopDate = startDate;
    }
    return self;
}

//===================================================================================================================
- (NSTimeInterval)elapsedTime;
{
    return [self.stopDate timeIntervalSinceDate:self.startDate];
}

//===================================================================================================================
- (void)setElapsedTime:(NSTimeInterval)theElapsedTime;
{
    DBLogMethod(@"%s");
    elapsedTime = theElapsedTime;
}

//===================================================================================================================
-(void)start;
{
    DBLogMethod(@"%s");
    
    self.startDate = [NSDate date];
}

//===================================================================================================================
-(void)stop;
{
    DBLogMethod(@"%s");
    
    self.stopDate = [NSDate date];
}


@end