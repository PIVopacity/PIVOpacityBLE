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
#import <Security/Security.h>
#import "OTP.h"
#import "AppGlobals.h"
#import "openssl/sha.h"
#import "openssl/hmac.h"

NSString * GenerateOTP(NSData *keyData, NSData *nonceData){
    //DBLogInfo(@"Key Data:\t%@",keyData);
    //DBLogInfo(@"Nonce Data:\t%@",nonceData);
    
    unsigned char * key = (unsigned char *) keyData.bytes;
    unsigned char * nonce = (unsigned char *) nonceData.bytes;
    
    unsigned char md[HMAC_MAX_MD_CBLOCK];
    HMAC_CTX *h = HMAC_CTX_new();
    HMAC_Init_ex(h, key, (int)keyData.length, EVP_sha384(), NULL);
    HMAC_Update(h, nonce, (int)nonceData.length);
    unsigned int len;
    HMAC_Final(h, md, &len);
    DBLogInfo(@"Length: %d, HMAC: %@", len, [NSData dataWithBytes:md length:len]);

    key = NULL;
    nonce = NULL;

    
    return [NSString stringWithFormat:@"%d%d%d %d%d%d",
            (md[0] & 0xff) % 10,
            (md[1] & 0xff) % 10,
            (md[2] & 0xff) % 10,
            (md[3] & 0xff) % 10,
            (md[4] & 0xff) % 10,
            (md[5] & 0xff) % 10];
}
