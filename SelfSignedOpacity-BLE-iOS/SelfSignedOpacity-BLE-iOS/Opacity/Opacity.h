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


#ifndef Opacity_h
#define Opacity_h

#import <Foundation/Foundation.h>
#import "AppGlobals.h"

extern NSString const *CBH;
extern NSString const *IDH;

extern NSData const *Cicc;
extern NSData const *Nicc;
extern NSData const *IDicc;
extern NSData const *pubEphKey;

extern NSMutableDictionary const *sessionKeys;

extern NSString *authOTP;

NSData * buildGenAuth(void);

void destroyEphKeyPair(void);
void generateEphKeyPair(void);
NSData * generateCicc(void);

NSData * KDF(NSData *Z, int length, NSData *otherInfo);
NSMutableDictionary *kdfToDict(NSData *kdf);
NSMutableDictionary *openClientTunnel(NSData *apdu);
NSMutableDictionary *openHostTunnel(NSData *apdu);

NSData *CMAC(NSData *key, NSData *msg);



#endif /* Opacity_h */
