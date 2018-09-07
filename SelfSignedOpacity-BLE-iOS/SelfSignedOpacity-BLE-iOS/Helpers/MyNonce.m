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

#import "MyNonce.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

static char base64EncodingTable[64] = {
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
    'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
    'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
};

static char text[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

char *generate_nonce(unsigned d_len, char *dst)
{
	if (d_len < 11)
		return NULL;
	int i, len = 10 + arc4random() % (d_len - 11);
	
	for (i = 0; i < len; i++)
		
	{
		dst[i] = text[arc4random() % (sizeof text - 1)];
	}
	dst[i] = '\0';
	return dst;
}


@implementation MyNonce
//===================================================================================================================
+ (NSString *)getNonce;
{
	//must be at least 10 chars
	char result[30];
	generate_nonce(30,result);

	NSString *theNonce = [NSString stringWithUTF8String: result];
	return theNonce;
}

//===================================================================================================================
+ (NSString *) base64StringFromData: (NSData *)data length: (int)length;
{
    unsigned long ixtext, lentext;
    long ctremaining;
    unsigned char input[3], output[4];
    short i, charsonline = 0, ctcopy;
    const unsigned char *raw;
    NSMutableString *result;
    
    lentext = [data length]; 
    if (lentext < 1)
        return @"";
    result = [NSMutableString stringWithCapacity: lentext];
    raw = [data bytes];
    ixtext = 0; 
    
    while (true) {
        ctremaining = lentext - ixtext;
        if (ctremaining <= 0) 
            break;        
        for (i = 0; i < 3; i++) { 
            unsigned long ix = ixtext + i;
            if (ix < lentext)
                input[i] = raw[ix];
            else
                input[i] = 0;
        }
        output[0] = (input[0] & 0xFC) >> 2;
        output[1] = ((input[0] & 0x03) << 4) | ((input[1] & 0xF0) >> 4);
        output[2] = ((input[1] & 0x0F) << 2) | ((input[2] & 0xC0) >> 6);
        output[3] = input[2] & 0x3F;
        ctcopy = 4;
        switch (ctremaining) {
            case 1: 
                ctcopy = 2; 
                break;
            case 2: 
                ctcopy = 3; 
                break;
        }
        
        for (i = 0; i < ctcopy; i++)
            [result appendString: [NSString stringWithFormat: @"%c", base64EncodingTable[output[i]]]];
        
        for (i = ctcopy; i < 4; i++)
            [result appendString: @"="];
        
        ixtext += 3;
        charsonline += 4;
        
        if ((length > 0) && (charsonline >= length))
            charsonline = 0;
    }     
    return result;
}

//===================================================================================================================
+ (NSString *)GetUUID;
{
    DBLogMethod(@"%s");
    
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return [(NSString *)string autorelease];
}

//===================================================================================================================
+ (NSString *)uniqueID;
{
    DBLogMethod(@"%s");
    
    NSString *guid = [self GetUUID];
    NSData *data = [guid dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *base64string = [self base64StringFromData: data length: (int)[data length]];
    
    int length = 16;
    
    NSRange range = NSMakeRange([base64string length] - length, length);
    
    NSString *result = [base64string substringWithRange:range];
    
    return result;
}

//===================================================================================================================
+ (NSString *)pin;
{
    int randomID = arc4random() % 9000 + 1000;

    return [NSString stringWithFormat:@"%i", randomID];
}
@end
