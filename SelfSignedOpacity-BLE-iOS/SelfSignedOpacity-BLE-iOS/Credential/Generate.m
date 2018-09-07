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
#import "Generate.h"

#import "openssl/x509.h"
#import "AppGlobals.h"

BOOL GenerateNewCredential(int days, NSString *flavor, int *time)
{
    long long startTime = (long long) (NSTimeInterval) ([[NSDate date] timeIntervalSince1970] * 1000);
    
    //Clear old key and certs
    NSData *tag = [@"com.opacity.selfSignedPiv" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *getquery = @{ (id)kSecClass: (id)kSecClassKey,
                                (id)kSecAttrApplicationTag: tag,
                                (id)kSecAttrKeyType: (id)kSecAttrKeyTypeEC,
                                (id)kSecReturnRef: @YES,
                                };
    
    
    SecKeyRef privateKey = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) getquery, (CFTypeRef *)&privateKey);
    if (status!=errSecSuccess) { DBLogInfo(@"No Key:  %@\tKeystore Empty", [[NSString alloc] initWithData:tag encoding:NSUTF8StringEncoding]); }
    else {
        DBLogInfo(@"Clearing old key: %@", [[NSString alloc] initWithData:tag encoding:NSUTF8StringEncoding]);
        SecItemDelete((__bridge CFDictionaryRef)getquery);
    }
    if (privateKey) { CFRelease(privateKey);}
    
    NSDictionary *certquery = @{ (id)kSecClass:     (id)kSecClassCertificate,
                                (id)kSecAttrLabel: @"selfSignedPivCert",
                                (id)kSecReturnRef: @YES,
                                };
    SecCertificateRef certificate = NULL;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)certquery,
                                          (CFTypeRef *)&certificate);
    if (status != errSecSuccess) { DBLogInfo(@"No Cert.  %d\n", (int) status); }
    else {
        DBLogInfo(@"Clearing old cert: %@", certificate);
        SecItemDelete((__bridge CFDictionaryRef)certquery);
    }
    if (certificate) { CFRelease(certificate); }
    


    X509 *x509 = X509_new();

    EC_KEY *eccKey = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1);
    EC_KEY_set_asn1_flag(eccKey, OPENSSL_EC_NAMED_CURVE);
    EC_KEY_generate_key(eccKey);

    EVP_PKEY *pKey = EVP_PKEY_new();
    EVP_PKEY_set1_EC_KEY(pKey, eccKey);

    X509_set_version(x509, 2);
    X509_set_pubkey(x509, pKey);
    ASN1_UTCTIME *tm = ASN1_UTCTIME_new();
    X509_set1_notBefore(x509, X509_gmtime_adj(tm, 0));
    X509_set1_notAfter(x509, X509_gmtime_adj(tm, (int)days*3600*24));

    X509_NAME *name = X509_get_subject_name(x509);
    const unsigned char cn[] = "Self-Signed PIV";
    X509_NAME_add_entry_by_txt(name, "CN", MBSTRING_ASC, cn, -1, -1, 0);

    X509_set_issuer_name(x509, name);

    X509_sign(x509, pKey, EVP_sha256());

    X509_print_fp(stdout, x509);
    //PEM_write_X509(stdout, x509);
    
    int certlen;
    unsigned char *tt = NULL;
    certlen = i2d_X509(x509, &tt);
    for (int i = 0; i<certlen; i++){
        printf("%02X:", tt[i]);
    }
    printf("\n\nLength: %d\n\n", certlen);
    
    int tbslen;
    unsigned char *tbs = NULL;
    printf("\n\nTBS:\n");
    tbslen = i2d_re_X509_tbs(x509, &tbs);
    NSMutableData *tbsData = [NSMutableData dataWithBytes:tbs length:tbslen];
    
    for (int i = 0; i<tbslen; i++){
        printf("%02X:", tbs[i]);
    }
    printf("\n\nLength: %d\n\n", tbslen);
    

//    printf("Dummy public key:\n");
    unsigned char *pp = NULL;
    int len = i2d_PUBKEY(X509_get_pubkey(x509), &pp);
    NSData * dummyKeyData = [NSData dataWithBytes:&pp[len-65] length:65];
//    for(int i=len-65; i<len; i++){
//        printf("%02X:",pp[i]);
//    }
//    printf("\n\n");
    
    //Generate key in secure enclave
    SecAccessControlRef access = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                                 kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                                                 kSecAccessControlPrivateKeyUsage, NULL);
    NSDictionary* attributes =
    @{ (id)kSecAttrKeyType:             (id)kSecAttrKeyTypeEC,
       (id)kSecAttrKeySizeInBits:       @256,
       (id)kSecAttrTokenID:             (id)kSecAttrTokenIDSecureEnclave,
       (id)kSecPrivateKeyAttrs:
           @{ (id)kSecAttrIsPermanent:  @YES,
              (id)kSecAttrCanSign:      @YES,
              (id)kSecAttrApplicationTag: tag,
              (id)kSecAttrAccessControl:  (__bridge id)access,
              },
       };

    CFErrorRef error = NULL;

    privateKey = SecKeyCreateRandomKey((__bridge CFDictionaryRef)attributes, &error);
    SecKeyRef publicKey = SecKeyCopyPublicKey(privateKey);

    CFDataRef publicKeyData = SecKeyCopyExternalRepresentation(publicKey, NULL);

    unsigned char *d = CFDataGetBytePtr(publicKeyData);
    len = CFDataGetLength(publicKeyData);
    printf("\n\nGenerated Key with Public:\n");
    for (int i = 0; i< len-1; i++){
        printf("%02X:",d[i]);
    }
    printf("%02X\nLength: %d\n\n",d[len],len);

    NSRange keyRange = [tbsData rangeOfData:dummyKeyData options:0 range:NSMakeRange(0, tbsData.length)];
    [tbsData replaceBytesInRange:keyRange withBytes:((NSData *)publicKeyData).bytes];
    
    NSData* newSignature = nil;
    error = NULL;

    int pass = 0;
    while(newSignature.length != 72){
        pass++;
        newSignature = (NSData*)CFBridgingRelease(SecKeyCreateSignature(privateKey,
                                                                     kSecKeyAlgorithmECDSASignatureMessageX962SHA256,
                                                                     (__bridge CFDataRef) tbsData,
                                                                     &error));
        if (!newSignature) {
            NSError *err = CFBridgingRelease(error);
            DBLogError(@"Signature Error. %@\n", err);
            return NO;
        }

        printf("Pass %d New Signature:\n", pass);
        unsigned char *sigBytes = newSignature.bytes;
        for(int i = 0; i<newSignature.length; i++){
            printf("%02X:",sigBytes[i]);
        }
        printf("\n\nLength: %lu\n\n", (unsigned long)newSignature.length);
    }
    
    [tbsData appendData:[@"30:0A:06:08:2A:86:48:CE:3D:04:03:02:03:49:00:" dataFromHexString]]; //Signature Algorithm ecdsa-with-SHA256
    [tbsData appendData:newSignature];

    NSMutableData *finalCredential = [NSMutableData dataWithData:[@"30" dataFromHexString]];
    [finalCredential appendData:BERTLVEncodeLen(tbsData.length)];
    [finalCredential appendData:tbsData];
    
    unsigned char *finalBytes = finalCredential.bytes;
    printf("\n\nFinalCredential:\n");
    for(int i = 0; i< finalCredential.length; i++){
        printf("%02X:",finalBytes[i]);
    }
    printf("\n");
    
    X509 *finalX509 = X509_new();
    d2i_X509(&finalX509, &finalBytes, (long) finalCredential.length);
    X509_print_fp(stdout,finalX509);

    printf("\n\n");
    unsigned char *ft = NULL;
    len = i2d_X509(finalX509, &ft);
    for(int i=0; i<len; i++){
        printf("%02X:",ft[i]);
    }
    printf("\n\nLength: %d\n\n", len);

    printf("Verify Self-Sign:  %d\n",X509_verify(finalX509, X509_get_pubkey(finalX509)));

    printf("\n\n");
    
    SecCertificateRef selfSignedPivCert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)finalCredential );
    
    NSLog(@"%@", selfSignedPivCert);
    
    NSDictionary* addquery = @{ (id)kSecValueRef:   (__bridge id)selfSignedPivCert,
                                (id)kSecClass:      (id)kSecClassCertificate,
                                (id)kSecAttrLabel:  @"selfSignedPivCert",
                                };
    status = SecItemAdd((__bridge CFDictionaryRef)addquery, NULL);
    if (status != errSecSuccess) {
        DBLogError(@"Adding Certificate to KeyChain Failed.  %d", (int)status);
        return NO;
    }


    CFRelease(publicKey);
    CFRelease(privateKey);
    CFRelease(selfSignedPivCert);
    
    *time = (int) ((long long) (NSTimeInterval) ([[NSDate date] timeIntervalSince1970] * 1000) - startTime);
    
    return YES;
}

