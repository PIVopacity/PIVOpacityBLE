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
#import "OpacityParser.h"

int sessionCommandCount=1;
int sessionReceiveCount=0;

NSData * parseHostCommand(NSData * fullcommand)
{
    NSData *response;
    unsigned char * commandBytes = (unsigned char*)fullcommand.bytes;
    NSData *command = [fullcommand subdataWithRange:NSMakeRange(2, fullcommand.length-2)];
    
    sessionCommandCount = (int)((commandBytes[0] & 0xFF) << 8) + (int)(commandBytes[1] & 0xFF); //set receive count to command count that is being responded to
    

    if ( [command isEqualToData:[SELECT_PIV dataFromHexString]] ) {
        response = [@"9999999999AC06800127060100" dataFromHexString];
    } else if ([[command subdataWithRange:NSMakeRange(0, 4)] isEqualToData:[@"00 87 27 04" dataFromHexString]]) {
        sessionKeys = openClientTunnel(command);
        for (NSString * key in sessionKeys){
            DBLogInfo(@"KEY: %@\tVAL: %@", key, toHexString((id)sessionKeys[key], @" "));
        }
        
        /*
         //  NIST Example values for AES CMAC compliant with NIST SP 800-38B
         //  https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Standards-and-Guidelines/documents/examples/AES_CMAC.pdf
         NSData *nistKey = [@"2b 7e 15 16 28 ae d2 a6 ab f7 15 88 09 cf 4f 3c" dataFromHexString];
         NSData *nistMsg = [@"" dataFromHexString];
         NSData *nistCmac = CMAC(nistKey,nistMsg);
         DBLogInfo(@"\nNIST 800-38B AES-128 Check: %d\t\tCMAC:  %@", [nistCmac isEqualToData:[@"BB 1D 69 29 E9 59 37 28 7F A3 7D 12 9B 75 67 46" dataFromHexString]], toHexString(nistCmac, @" "));
         */
        
        NSMutableData *message = [NSMutableData dataWithData:[@"4B435F315F56" dataFromHexString]]; //"KC_1_V"
        [message appendData:(NSData*)IDicc];
        [message appendData:[IDH dataFromHexString]];
        [message appendData:[command subdataWithRange:NSMakeRange(19, 64)]];
        
        
        NSData *authCryptogram = CMAC(sessionKeys[@"cfrm"], (NSData*) message);
        
        [sessionKeys setObject:[@"" dataFromHexString] forKey:@"cfrm"];
        DBLogInfo(@" ");
        for (NSString * key in sessionKeys){
            DBLogInfo(@"KEY: %@\tVAL: %@", key, toHexString((id)sessionKeys[key], @" "));
        }
        
        
        NSMutableData *rsp = [NSMutableData dataWithData:[@"00" dataFromHexString]]; //CBicc
        [rsp appendData:(NSData*)Nicc];
        [rsp appendData:authCryptogram];
        [rsp appendData:(NSData*)Cicc];
        
        NSMutableData *rsp2 = [NSMutableData dataWithData:[@"82" dataFromHexString]];
        [rsp2 appendData:BERTLVEncodeLen((int)rsp.length)];
        [rsp2 appendData:rsp];
        
        rsp = [NSMutableData dataWithData:[@"7C" dataFromHexString]];
        [rsp appendData:BERTLVEncodeLen((int)rsp2.length)];
        [rsp appendData:rsp2];
        
        response = (NSData*)rsp;
        
        authOTP = GenerateOTP((NSData *)sessionKeys[@"enc"], (NSData*)Nicc);
        
    } else {
        response = [@"" dataFromHexString];
    }
    sessionReceiveCount = sessionCommandCount;
    NSMutableData *fullresponse = [NSMutableData dataWithData:[[NSString stringWithFormat:@"%04X", sessionReceiveCount] dataFromHexString]];
    [fullresponse appendData:response];
    if ( [response isEqualToData:[@"" dataFromHexString]] ) [fullresponse appendData:[@"6A81" dataFromHexString]];
    else [fullresponse appendData:[@"9000" dataFromHexString]];
    return (NSData*)fullresponse;
}


NSData * parseClientResponse(NSData * fullresponse)
{
    NSData *command;
    unsigned char * responseBytes = (unsigned char*)fullresponse.bytes;
    NSData *response = [fullresponse subdataWithRange:NSMakeRange(2, fullresponse.length-4)];
    
    sessionReceiveCount = (int)((responseBytes[0] & 0xFF) << 8) + (int)(responseBytes[1] & 0xFF);
    
    switch(sessionReceiveCount)
    {
        case 1:
            generateEphKeyPair();
            command = buildGenAuth();
            DBLogError(@"GEN_AUTH:   %@",toHexString(command, @" "));
            break;
        case 2:
            DBLogInfo(@"Pub Key:\t%@", toHexString((NSData*)pubEphKey, @" "));
            
            sessionKeys = openHostTunnel(response);
            for (NSString * key in sessionKeys){
                DBLogInfo(@"KEY: %@\tVAL: %@", key, toHexString((id)sessionKeys[key], @" "));
            }
            command = [@"NEXT Command" dataUsingEncoding:NSUTF8StringEncoding];
            authOTP = GenerateOTP((NSData *)sessionKeys[@"enc"], (NSData*)Nicc);
            break;
        default:
            command = [@"" dataFromHexString];
            break;
    }
    
    sessionCommandCount++;
    
    NSMutableData *fullcommand = [NSMutableData dataWithData:[[NSString stringWithFormat:@"%04X", sessionCommandCount] dataFromHexString]];
    [fullcommand appendData:command];
    return (NSData*)fullcommand;
}
