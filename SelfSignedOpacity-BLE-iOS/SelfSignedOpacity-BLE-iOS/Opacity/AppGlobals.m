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
#import "AppGlobals.h"

NSString * const SELECT_PIV = @"00A404000AA000000308000010009900";

NSData * BERTLVEncodeLen(int num){
    NSString *hexString = nil;
    if (num<128)
    {
        hexString = [NSString stringWithFormat:@"%02x", num];
    }
    else if (num>127 && num<256)
    {
        hexString = [NSString stringWithFormat:@"81%02x", num];
    }
    else if (num>255 && num<65536)
    {
        hexString = [NSString stringWithFormat:@"82%04x", num];
    }
    else if (num>65535 && num<16777216)
    {
        hexString = [NSString stringWithFormat:@"83%06x", num];
    }
    else if (num>16777215 && num<2147483647)
    {
        hexString = [NSString stringWithFormat:@"84%08x", num];
    }
    
    return [hexString dataFromHexString];
}

int BERTLVParseLen(unsigned char * num){
    int mark=(int)num[0]&0xFF;
    switch(mark){
        default:
            return mark;
        case 0x81:
            return (int)num[1] & 0xFF;
        case 0x82:
            return (((int)num[1] & 0xFF)<<8)+((int)num[2] & 0xFF);
        case 0x83:
            return (((int)num[1] & 0xFF)<<16)+(((int)num[2] & 0xFF)<<8)+((int)num[3] & 0xFF);
        case 0x84:
            return (((int)num[1] & 0xFF)<<24)+(((int)num[2] & 0xFF)<<16)+(((int)num[3] & 0xFF)<<8)+((int)num[4] & 0xFF);
    }
}

int BERTLVTagLen(Byte b){
    if((b & 0xFF)>127)
    {
        return (b & 0xF)+1;
    } else
    {
        return 1;
    }
}

@implementation NSString (NSStringExtensions)
- (NSData *) dataFromHexString;
{
    if ( [self rangeOfString:@" "].location != NSNotFound ) self = [self stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ( [self rangeOfString:@":"].location != NSNotFound ) self = [self stringByReplacingOccurrencesOfString:@":" withString:@""];
    
    char byteChar[2] = {'\0','\0'};
    if( self.length % 2 == 0 ){
        unsigned char bytes[self.length/2];
        for( int i=0; i< self.length; i+=2){
            byteChar[0] = [self characterAtIndex:i];
            byteChar[1] = [self characterAtIndex:i+1];
            bytes[i/2] = strtol(byteChar,NULL,16);
        }
        return [NSData dataWithBytes:bytes length:self.length/2];
    } else  {
        DBLogError(@"Incompatible Hex String.");
        return nil;
    }
}
@end

NSString * toHexString(NSData *data, NSString *sp)
{
    NSString *str = @"";
    unsigned const char * byts = data.bytes;
    for (int i = 0; i < data.length; i++)
    {
        str = [str stringByAppendingString:[NSString stringWithFormat:@"%02X", byts[i]]];
        str = [str stringByAppendingString:sp];
    }
    return str;
}
