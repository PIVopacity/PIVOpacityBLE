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
#import "Opacity.h"
#import "openssl/x509.h"
#import "openssl/sha.h"
#import "openssl/cmac.h"

NSString const *CBH = @"00";
NSString const *IDH = @"00 00 00 00 00 00 00 00";
NSData const *Cicc;
NSData const *Nicc;
NSData const *IDicc;
NSData const *pubEphKey;
NSString *authOTP = @"00";
NSMutableDictionary const *sessionKeys;


NSData * buildGenAuth()
{
    NSMutableData *dataField = [NSMutableData dataWithData:[CBH dataFromHexString]];
    [dataField appendData:[IDH dataFromHexString]];
    [dataField appendData:(NSData*)pubEphKey];
    
    NSMutableData *dataPayload = [NSMutableData dataWithData:[@"81" dataFromHexString]];
    [dataPayload appendData:[[NSString stringWithFormat:@"%02X", (int)[dataField length]] dataFromHexString]];
    [dataPayload appendData:dataField];
    [dataPayload appendData:[@"8200" dataFromHexString]];
    
    NSMutableData *dataPayload2 = [NSMutableData dataWithData:[@"7C" dataFromHexString]];
    [dataPayload2 appendData:[[NSString stringWithFormat:@"%02X", (int)[dataPayload length]] dataFromHexString]];
    [dataPayload2 appendData:dataPayload];
    
    NSMutableData *dataCommand = [NSMutableData dataWithData:[@"00 87 27 04" dataFromHexString]];
    [dataCommand appendData:[[NSString stringWithFormat:@"%02X", (int)[dataPayload2 length]] dataFromHexString]];
    [dataCommand appendData:dataPayload2];
    [dataCommand appendData:[@"00" dataFromHexString]];
    
    return (NSData *)dataCommand;
}

void destroyEphKeyPair(void)
{
    NSData* tag = [@"com.opacity.eph" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *getquery = @{ (id)kSecClass: (id)kSecClassKey,
                                (id)kSecAttrApplicationTag: tag,
                                (id)kSecAttrKeyType: (id)kSecAttrKeyTypeEC,
                                (id)kSecReturnRef: @YES,
                                };
    
    SecKeyRef privateKey = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) getquery, (CFTypeRef *)&privateKey);
    if (status!=errSecSuccess) { DBLogInfo(@"No Ephemeral Key:  %@  Creating new ephemeral key", [[NSString alloc] initWithData:tag encoding:NSUTF8StringEncoding]); }
    else {
        DBLogInfo(@"Clearing old key: %@", [[NSString alloc] initWithData:tag encoding:NSUTF8StringEncoding]);
        SecItemDelete((__bridge CFDictionaryRef)getquery);
    }
    if (privateKey) { CFRelease(privateKey);}
}

void generateEphKeyPair(void)
{
    destroyEphKeyPair();
    NSData* tag = [@"com.opacity.eph" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary* attributes =
    @{ (id)kSecAttrKeyType:               (id)kSecAttrKeyTypeEC,
       (id)kSecAttrKeySizeInBits:         @256,
       (id)kSecPrivateKeyAttrs:
           @{ (id)kSecAttrIsPermanent:    @YES,
              (id)kSecAttrApplicationTag: tag,
              },
       };
    
    CFErrorRef error = NULL;
    
    SecKeyRef privateKey = SecKeyCreateRandomKey((__bridge CFDictionaryRef)attributes, &error);
    SecKeyRef publicKey = SecKeyCopyPublicKey(privateKey);
    
    DBLogInfo(@"\nGenerated ephemeral key pair: %@\n1\nPublic: %@", privateKey, publicKey);
    pubEphKey = [[NSData alloc] initWithData:[NSData dataWithData:(NSData *)SecKeyCopyExternalRepresentation(publicKey, NULL)]];
}

NSMutableDictionary * openClientTunnel(NSData *apdu)
{
    NSData * CBsh = [apdu subdataWithRange:NSMakeRange(9, 1)];
    NSData * IDsh = [apdu subdataWithRange:NSMakeRange(10, 8)];
    NSData * Qsh = [apdu subdataWithRange:NSMakeRange(18, 65)];
    
    IDicc = generateCicc();
    
   
    NSData* tag = [@"com.opacity.eph" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *getquery = @{ (id)kSecClass: (id)kSecClassKey,
                                (id)kSecAttrApplicationTag: tag,
                                (id)kSecAttrKeyType: (id)kSecAttrKeyTypeEC,
                                (id)kSecReturnRef: @YES,
                                };
    SecKeyRef privateKey = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) getquery, (CFTypeRef *)&privateKey);
    CFErrorRef error = NULL;
    if (status!=errSecSuccess) { DBLogInfo(@"No Ephemeral Key:  %@  Create new ephemeral key", [[NSString alloc] initWithData:tag encoding:NSUTF8StringEncoding]); }
    NSDictionary * hostPubKeyAttr = @{
                                  (id)kSecAttrKeyType:          (id)kSecAttrKeyTypeEC,
                                  (id)kSecAttrKeyClass:         (id)kSecAttrKeyClassPublic,
                                  (id)kSecAttrKeySizeInBits:    @256
                                  };
    SecKeyRef hostPubKey = SecKeyCreateWithData(CFDataCreate(NULL, Qsh.bytes, Qsh.length), (__bridge CFDictionaryRef) hostPubKeyAttr, &error);
    if ( error != errSecSuccess) {DBLogError(@"Sec Error.\t %@", CFBridgingRelease(error));}
    NSData *Z = (NSData*) SecKeyCopyKeyExchangeResult(privateKey, kSecKeyAlgorithmECDHKeyExchangeStandard, hostPubKey, (__bridge CFDictionaryRef)@{ }, &error);
    if ( error != errSecSuccess) {DBLogError(@"Sec Error.\t %@", CFBridgingRelease(error));}
    if (privateKey) { CFRelease(privateKey);}
    destroyEphKeyPair();
    
    DBLogInfo(@"\nShared Secret: (Length %d)\t%@", (int)Z.length, toHexString(Z,@" "));
    
    
    unsigned char niccBytes[16];
    status = SecRandomCopyBytes(kSecRandomDefault, 16, niccBytes);
    if(status != errSecSuccess) { DBLogError(@"SecRandom ERROR.  %d", (int)status); }
    Nicc = [NSData dataWithBytes:niccBytes length:16];
    
    NSMutableData *otherInfo = [NSMutableData dataWithData:[@"04 09 09 09 09 08 " dataFromHexString]];
    [otherInfo appendData:IDsh];
    [otherInfo appendData:[@"01" dataFromHexString]];
    [otherInfo appendData:CBsh];
    [otherInfo appendData:[@"10" dataFromHexString]];
    [otherInfo appendData:[Qsh subdataWithRange:NSMakeRange(1, 16)]];
    [otherInfo appendData:[@"08" dataFromHexString]];
    [otherInfo appendData:(NSData*)IDicc];
    [otherInfo appendData:[@"10" dataFromHexString]];
    [otherInfo appendData:(NSData*)Nicc];
    [otherInfo appendData:[@"01" dataFromHexString]];
    [otherInfo appendData:[@"00" dataFromHexString]]; //CBicc
    
    NSData *keyMaterial = KDF(Z, 512, (NSData*)otherInfo);
    Z=NULL;
    NSMutableDictionary *skeys = kdfToDict(keyMaterial);
    return skeys;
}

NSMutableDictionary *openHostTunnel(NSData *apdu)
{
    NSData * CBicc = [apdu subdataWithRange:NSMakeRange(6, 1)];
    Nicc = [apdu subdataWithRange:NSMakeRange(7, 16)];
    NSData *authCryptogram = [apdu subdataWithRange:NSMakeRange(23, 16)];
    Cicc = [apdu subdataWithRange:NSMakeRange(39, apdu.length-39)];
    unsigned char * ciccBytes = (unsigned char *)Cicc.bytes;
    unsigned char md[SHA256_DIGEST_LENGTH];
    SHA256(ciccBytes, Cicc.length, md);
    
    IDicc = [NSData dataWithBytes:md length:8];
    NSRange keyRange = [Cicc rangeOfData:[@"2A 86 48 CE 3D 03 01 07 86 41" dataFromHexString] options:0 range:NSMakeRange(0, Cicc.length)];  //Find location of OID+Flag*Length bytes
    NSData *Qsicc = [Cicc subdataWithRange:NSMakeRange(keyRange.location+keyRange.length, 65)];
    
    NSData* tag = [@"com.opacity.eph" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *getquery = @{ (id)kSecClass: (id)kSecClassKey,
                                (id)kSecAttrApplicationTag: tag,
                                (id)kSecAttrKeyType: (id)kSecAttrKeyTypeEC,
                                (id)kSecReturnRef: @YES,
                                };
    SecKeyRef privateKey = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) getquery, (CFTypeRef *)&privateKey);
    CFErrorRef error = NULL;
    if (status!=errSecSuccess) { DBLogInfo(@"No Ephemeral Key:  %@  Create new ephemeral key", [[NSString alloc] initWithData:tag encoding:NSUTF8StringEncoding]); }
    NSDictionary * clientPubKeyAttr = @{
                                      (id)kSecAttrKeyType:          (id)kSecAttrKeyTypeEC,
                                      (id)kSecAttrKeyClass:         (id)kSecAttrKeyClassPublic,
                                      (id)kSecAttrKeySizeInBits:    @256
                                      };
    SecKeyRef clientPubKey = SecKeyCreateWithData(CFDataCreate(NULL, Qsicc.bytes, Qsicc.length), (__bridge CFDictionaryRef) clientPubKeyAttr, &error);
    if ( error != errSecSuccess) {DBLogError(@"Sec Error.\t %@", CFBridgingRelease(error));}
    DBLogInfo(@"Client Pub Key: %@", toHexString((NSData*)SecKeyCopyExternalRepresentation(clientPubKey, NULL), @" "));
    NSData *Z = (NSData*) SecKeyCopyKeyExchangeResult(privateKey, kSecKeyAlgorithmECDHKeyExchangeStandard, clientPubKey, (__bridge CFDictionaryRef)@{ }, &error);
    if ( error != errSecSuccess) {DBLogError(@"Sec Error.\t %@", CFBridgingRelease(error));}
    if (privateKey) { CFRelease(privateKey);}
    
    
    DBLogInfo(@"\nShared Secret: (Length %d)\t%@", (int)Z.length, toHexString(Z,@" "));
    
    NSMutableData *otherInfo = [NSMutableData dataWithData:[@"04 09 09 09 09 08 " dataFromHexString]];
    [otherInfo appendData:[IDH dataFromHexString]];
    [otherInfo appendData:[@"01" dataFromHexString]];
    [otherInfo appendData:[CBH dataFromHexString]];
    [otherInfo appendData:[@"10" dataFromHexString]];
    [otherInfo appendData:[(NSData*)pubEphKey subdataWithRange:NSMakeRange(1, 16)]];
    [otherInfo appendData:[@"08" dataFromHexString]];
    [otherInfo appendData:(NSData*)IDicc];
    [otherInfo appendData:[@"10" dataFromHexString]];
    [otherInfo appendData:(NSData*)Nicc];
    [otherInfo appendData:[@"01" dataFromHexString]];
    [otherInfo appendData:[@"00" dataFromHexString]]; //CBicc
    
    NSData *keyMaterial = KDF(Z, 512, (NSData*)otherInfo);
    Z=NULL;
    NSMutableDictionary *skeys = kdfToDict(keyMaterial);
    
    NSMutableData *message = [NSMutableData dataWithData:[@"4B435F315F56" dataFromHexString]]; //"KC_1_V"
    [message appendData:(NSData*)IDicc];
    [message appendData:[IDH dataFromHexString]];
    [message appendData:[pubEphKey subdataWithRange:NSMakeRange(1, 64)]];
    
    
    NSData *authCryptogramCalc = CMAC(skeys[@"cfrm"], (NSData*) message);
    
    DBLogInfo(@"Confirm Auth Cryptogram: %d\n%@\n%@", [authCryptogram isEqualToData:authCryptogramCalc], authCryptogram, authCryptogramCalc);
    
    [skeys setObject:[@"" dataFromHexString] forKey:@"cfrm"];
    destroyEphKeyPair();
    
    return skeys;
}

NSData * generateCicc()
{
    generateEphKeyPair();
    
    NSMutableData *cicc = [NSMutableData dataWithData:[@"5F 29 01 80 42 08" dataFromHexString]];
    [cicc appendData:[@"01 01 01 01 01 01 01 01" dataFromHexString]]; //Issuer ID
    [cicc appendData:[@"5F 20 10" dataFromHexString]];
    [cicc appendData:[@"30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30" dataFromHexString]]; //GUID
    [cicc appendData:[@"7F 49 4D 06 08" dataFromHexString]];
    [cicc appendData:[@"2A 86 48 CE 3D 03 01 07" dataFromHexString]]; //Algorithm OID for ECDH P-256
    [cicc appendData:[@"86" dataFromHexString]];
    [cicc appendData:BERTLVEncodeLen((int)pubEphKey.length)];
    [cicc appendData:pubEphKey]; //Public Ephemeral Key
    [cicc appendData:[@"5F 4C 01 00" dataFromHexString]];
    
    NSData *tag = [@"com.opacity.selfSignedPiv" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *getquery = @{ (id)kSecClass: (id)kSecClassKey,
                                (id)kSecAttrApplicationTag: tag,
                                (id)kSecAttrKeyType: (id)kSecAttrKeyTypeEC,
                                (id)kSecReturnRef: @YES,
                                };
    
    SecKeyRef privateKey = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) getquery, (CFTypeRef *)&privateKey);
    if (status!=errSecSuccess) { DBLogInfo(@"No Key:  %@\tKeystore Empty", [[NSString alloc] initWithData:tag encoding:NSUTF8StringEncoding]); }
    
    CFErrorRef error = NULL;
    NSData * ciccSig = (NSData*)CFBridgingRelease(SecKeyCreateSignature(privateKey,
                                                                        kSecKeyAlgorithmECDSASignatureMessageX962SHA256,
                                                                        (__bridge CFDataRef) cicc,
                                                                        &error));
    if (!ciccSig) {
        NSError *err = CFBridgingRelease(error);
        DBLogError(@"Signature Error. %@\n", err);
    }
    
    if (privateKey) { CFRelease(privateKey);}
    
    [cicc appendData:[@"5F 37" dataFromHexString]];
    [cicc appendData:BERTLVEncodeLen((int)ciccSig.length)];
    [cicc appendData:ciccSig];
    
    NSMutableData * CVC = [NSMutableData dataWithData:[@"7F 21" dataFromHexString]];
    [CVC appendData:BERTLVEncodeLen((int)cicc.length)];
    [CVC appendData:(NSData*)cicc];
    
    Cicc = [NSData dataWithData:(NSData*)CVC];
    
    DBLogInfo(@"\nCicc:\tLength: %d\n%@\n", (int)Cicc.length, toHexString((NSData*)Cicc, @" "));
    
    unsigned char * ciccBytes = (unsigned char *)Cicc.bytes;
    unsigned char md[SHA256_DIGEST_LENGTH];
    SHA256(ciccBytes, Cicc.length, md);
    NSData *IDicc = [NSData dataWithBytes:md length:8];
    return IDicc;
}

NSData * KDF(NSData *Z, int length, NSData *otherInfo)
{
    unsigned char md[SHA256_DIGEST_LENGTH];
    SHA256_CTX c;
    DBLogInfo(@"OTHERINFO:\t%@",toHexString(otherInfo, @" "));
    int hashLength = SHA256_DIGEST_LENGTH*8;
    int reps = (int) ceil((double) length / (double) hashLength);
    NSMutableData *output = NULL;
    NSData *count = NULL;
    unsigned char * countBytes;
    unsigned char * zBytes = (unsigned char*)Z.bytes;
    unsigned char * otherInfoBytes = (unsigned char*)otherInfo.bytes;
    
    for (int i = 1; i < reps; i++)
    {
        SHA256_Init(&c);
        count = [[NSString stringWithFormat:@"%08X",i] dataFromHexString];
        countBytes = (unsigned char*)count.bytes;
        SHA256_Update(&c, countBytes, count.length);
        SHA256_Update(&c, zBytes, Z.length);
        SHA256_Update(&c, otherInfoBytes, otherInfo.length);
        SHA256_Final(md, &c);
        if (i == 1) output = [NSMutableData dataWithBytes:md length:SHA256_DIGEST_LENGTH];
        else [output appendBytes:md length:SHA256_DIGEST_LENGTH];
    }
    
    SHA256_Init(&c);
    count = [[NSString stringWithFormat:@"%08X",reps] dataFromHexString];
    countBytes = (unsigned char*)count.bytes;
    SHA256_Update(&c, countBytes, count.length);
    SHA256_Update(&c, zBytes, Z.length);
    SHA256_Update(&c, otherInfoBytes, otherInfo.length);
    SHA256_Final(md, &c);
    if (length % hashLength != 0) [output appendBytes:md length:(length % hashLength) / 8];
    else [output appendBytes:md length:SHA256_DIGEST_LENGTH];
    
    return output;
}

NSMutableDictionary * kdfToDict(NSData *kdf)
{
    int keyLen = (int)kdf.length/4;
    
    NSMutableDictionary *keyDict = [NSMutableDictionary dictionaryWithCapacity:4];
    [keyDict setObject:[kdf subdataWithRange:NSMakeRange(0, keyLen)] forKey:@"cfrm"];
    [keyDict setObject:[kdf subdataWithRange:NSMakeRange(keyLen, keyLen)] forKey:@"mac"];
    [keyDict setObject:[kdf subdataWithRange:NSMakeRange(2*keyLen, keyLen)] forKey:@"enc"];
    [keyDict setObject:[kdf subdataWithRange:NSMakeRange(3*keyLen, keyLen)] forKey:@"rmac"];
    
    return keyDict;
}

NSData * CMAC(NSData *key, NSData *msg)
{
    CMAC_CTX *cmac_c = CMAC_CTX_new();
    unsigned char * cmacKey = (unsigned char*) key.bytes;
    CMAC_Init(cmac_c, cmacKey, key.length, EVP_aes_128_cbc(), NULL);
    unsigned char * msgBytes = (unsigned char*) msg.bytes;
    CMAC_Update(cmac_c, msgBytes, msg.length);
    unsigned char cmac_digest[key.length];
    size_t poutlen;
    CMAC_Final(cmac_c, cmac_digest, &poutlen);
    NSData *digest = [NSData dataWithBytes:cmac_digest length:key.length];
    return digest;
}
