/*
Copyright (c) 2017 United States Government

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Written by Christopher Williams, Ph.D. (cwilliams@exponent.com)
*/

package exponent.selfsignedcred_ble.dhsdemo;

import android.app.Activity;
import android.os.Build;
import android.os.Environment;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyInfo;
import android.security.keystore.KeyProperties;
import android.support.annotation.RequiresApi;
import android.util.Log;

import org.spongycastle.cert.X509v3CertificateBuilder;
import org.spongycastle.cert.jcajce.JcaX509CertificateConverter;
import org.spongycastle.cert.jcajce.JcaX509v3CertificateBuilder;
import org.spongycastle.operator.ContentSigner;
import org.spongycastle.operator.OperatorCreationException;
import org.spongycastle.operator.jcajce.JcaContentSignerBuilder;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.math.BigInteger;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.PrivateKey;
import java.security.Provider;
import java.security.SecureRandom;
import java.security.Security;
import java.security.Signature;
import java.security.SignatureException;
import java.security.UnrecoverableEntryException;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.security.spec.ECGenParameterSpec;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.RSAKeyGenParameterSpec;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Date;

import javax.security.auth.x500.X500Principal;


public class SelfSignedCred
{
    private Activity activity;
	private Logger logger;
    private Integer daysValid;
    private String flavor;

	private final static String TAG = "SelfSignedCred";

	private final static String GET_DISCOVERY_OBJECT = "00 CB 3F FF 03 5C 01 7E 00";
	private final static String MCV = "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00"; // 16 bytes
	private final static String RMCV = "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00"; // 16 bytes

	private final static String ERROR_TITLE = "Error";
	private final static String SUCCESS_TITLE = "SUCCESS";
	private final static String CARD_COMM_ERROR = "Error communicating with card: check log for details.";
	private final static String CRYPTO_ERROR = "Cryptography error: check log for details.";
    private final static String AUTH_ERROR = "Authentication error: check log for details.";

    private String keystoreCondition=null;


	public SelfSignedCred(Activity activity, Logger logger, Integer days, String flavor)
	{
        this.activity = activity;
		this.logger = logger;
        this.daysValid = days;
        this.flavor=flavor;
    }


	@RequiresApi(api = Build.VERSION_CODES.M)
	public void GenerateSelfSignedCred() throws NoSuchProviderException, CertificateException, NoSuchAlgorithmException, InvalidKeyException, SignatureException
    {
        logger.clear();

        logger.info(TAG, "Generating new Self-signed Credential");

        Calendar cal = Calendar.getInstance();
        Date startDate = cal.getTime();                // time from which certificate is valid
        cal.add(cal.DATE,daysValid);
        Date expiryDate = cal.getTime();               // time after which certificate is not valid
        BigInteger serialNumber = new BigInteger(40,new SecureRandom());       // serial number for certificate

        X500Principal subName=new X500Principal("CN=SELF-SIGNED PIV, C=US");


        KeyPairGenerator kpg = null, spg = null;

        //Self-Signed Credential Key
        //secp224r1, prime 256: prime256v1, prime 384: secp384r1, prime 512: secp521r1
        KeyPair pair=null;
        KeyPair signerHolder=null;
        long start=System.currentTimeMillis();
//        if(flavor.startsWith("RSA"))
//        {
//            //AKS
//            try
//            {
//                kpg = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_RSA,"AndroidKeyStore");
//                kpg.initialize(new KeyGenParameterSpec.Builder(
//                        "selfSignedPivKey",
//                        KeyProperties.PURPOSE_SIGN|KeyProperties.PURPOSE_VERIFY)
//                        .setAlgorithmParameterSpec(new RSAKeyGenParameterSpec(Integer.parseInt(flavor.substring(4)),new BigInteger("65537")))
//                        .setDigests(KeyProperties.DIGEST_NONE,KeyProperties.DIGEST_SHA256,KeyProperties.DIGEST_SHA384,KeyProperties.DIGEST_SHA512)
//                        .setSignaturePaddings(KeyProperties.SIGNATURE_PADDING_RSA_PKCS1)
//                        .setRandomizedEncryptionRequired(true)
//                        .setCertificateSubject(subName)
//                        .setCertificateSerialNumber(serialNumber)
//                        .setCertificateNotBefore(startDate)
//                        .setCertificateNotAfter(expiryDate)
//                        .setAttestationChallenge(null)
//                        // Only permit the private key to be used if the user authenticated
//                        // within the last five minutes.
//                        .setUserAuthenticationRequired(true)
//                        .setUserAuthenticationValidityDurationSeconds(5 * 60)
//                        .build());
//            } catch (NoSuchAlgorithmException e)
//            {
//                e.printStackTrace();
//            } catch (InvalidAlgorithmParameterException e)
//            {
//                e.printStackTrace();
//            } catch (NoSuchProviderException e)
//            {
//                e.printStackTrace();
//            }
//            pair=kpg.generateKeyPair(); // public/private key pair that we are creating for credential
//
//            try
//            {
//                spg = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_RSA);
//                spg.initialize(new RSAKeyGenParameterSpec(Integer.parseInt(flavor.substring(4)),new BigInteger("65537")), new SecureRandom());
//                signerHolder=spg.generateKeyPair();
//            } catch (InvalidAlgorithmParameterException e)
//            {
//                e.printStackTrace();
//            }
//
//        } else

        if(flavor.startsWith("ECC"))
        {
            //AKS
            try
            {
                kpg = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC,"AndroidKeyStore");
                kpg.initialize(new KeyGenParameterSpec.Builder(
                    "selfSignedPivKey",
                    KeyProperties.PURPOSE_SIGN|KeyProperties.PURPOSE_VERIFY)
                    .setAlgorithmParameterSpec(new ECGenParameterSpec(flavor.substring(4)))
                    .setDigests(KeyProperties.DIGEST_NONE,KeyProperties.DIGEST_SHA256,KeyProperties.DIGEST_SHA384,KeyProperties.DIGEST_SHA512)
                    .setCertificateSubject(subName)
                    .setCertificateSerialNumber(serialNumber)
                    .setCertificateNotBefore(startDate)
                    .setCertificateNotAfter(expiryDate)
                    .setAttestationChallenge(null)
                    // Only permit the private key to be used if the user authenticated
                    // within the last five minutes.
                    .setUserAuthenticationRequired(true)
                    .setUserAuthenticationValidityDurationSeconds(60 * 60)
                    .build());

            } catch (NoSuchAlgorithmException e)
            {
                e.printStackTrace();
            } catch (InvalidAlgorithmParameterException e)
            {
                e.printStackTrace();
            } catch (NoSuchProviderException e)
            {
                e.printStackTrace();
            }

            pair=kpg.generateKeyPair(); // public/private key pair that we are creating for credential

            try
            {
                spg = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC);
                spg.initialize(new ECGenParameterSpec(flavor.substring(4)), new SecureRandom());
                signerHolder=spg.generateKeyPair();
            } catch (InvalidAlgorithmParameterException e)
            {
                e.printStackTrace();
            }

        }else
        {
            logger.error(TAG, "Crypto Error");
            logger.alert(CRYPTO_ERROR, ERROR_TITLE);
            return;
        }
        logger.info(TAG,"Key generation time: "+(System.currentTimeMillis()-start)+" ms");

        KeyStore aks = null;
        try
        {
            aks = KeyStore.getInstance("AndroidKeyStore");
            aks.load(null);
        } catch (KeyStoreException e)
        {
            e.printStackTrace();
        } catch (CertificateException e)
        {
            e.printStackTrace();
        } catch (NoSuchAlgorithmException e)
        {
            e.printStackTrace();
        } catch (IOException e)
        {
            e.printStackTrace();
        }

        try
        {
            logger.debug(TAG,"AKS Cert:\n"+aks.getCertificate("selfSignedPivKey").toString());
        } catch (KeyStoreException e)
        {
            e.printStackTrace();
        }


        KeyFactory factory = null;
        try
        {
            factory = KeyFactory.getInstance(pair.getPrivate().getAlgorithm(), "AndroidKeyStore");
            KeyInfo keyInfo;
            try {
                keyInfo = factory.getKeySpec(pair.getPrivate(), KeyInfo.class);
                if(keyInfo.isInsideSecureHardware())
                {
                    keystoreCondition="Private Key Stored In Secure Hardware";
                }else
                {
                    keystoreCondition="Private Key Stored In Software";
                }

            } catch (InvalidKeySpecException e) {
                // Not an Android KeyStore key.
            }
        } catch (NoSuchAlgorithmException e)
        {
            e.printStackTrace();
        } catch (NoSuchProviderException e)
        {
            e.printStackTrace();
        }

        logger.info(TAG,keystoreCondition);

        KeyStore ks=null;
        try
        {
            ks = KeyStore.getInstance(KeyStore.getDefaultType());
        } catch (KeyStoreException e)
        {
            e.printStackTrace();
        }


        File file = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "PIV_Auth_KeyStore");

        try
        {
            if(file.exists())
            {
                ks.load(new FileInputStream(file),null);
            } else
            {
                ks.load(null);
            }
        } catch (IOException e)
        {
            e.printStackTrace();
        } catch (NoSuchAlgorithmException e)
        {
            e.printStackTrace();
        } catch (CertificateException e)
        {
            e.printStackTrace();
        }

        X509Certificate signedCert = null;

        CertificateFactory cf = CertificateFactory.getInstance("X.509");
        X509v3CertificateBuilder certGen =
                null;
        try
        {
            certGen = new JcaX509v3CertificateBuilder(subName,serialNumber,startDate,expiryDate,subName,aks.getCertificate("selfSignedPivKey").getPublicKey());
        } catch (KeyStoreException e)
        {
            e.printStackTrace();
        }
        X509Certificate dummySignedCert = null;

        String signatureAlgorithm ="NONEwithECDSA";
        if(flavor.contains("prime256v1")) signatureAlgorithm ="SHA256withECDSA";
        else if(flavor.contains("secp384r1")) signatureAlgorithm ="SHA384withECDSA";
        else if(flavor.contains("secp521r1")) signatureAlgorithm ="SHA512withECDSA";

        //Java Security Providers
//        for (Provider p : Security.getProviders()) {
//            Log.d(TAG, String.format("======================= %s =======================", p.getName()));
//            for (Provider.Service s : p.getServices()) {
//                Log.d(TAG, String.format("\t%s", s.getAlgorithm()));
//            }
//        }

        try
        {
            ContentSigner signer = new JcaContentSignerBuilder(signatureAlgorithm).setProvider("AndroidOpenSSL").build(signerHolder.getPrivate());
            dummySignedCert = new JcaX509CertificateConverter().setProvider("AndroidOpenSSL").getCertificate(certGen.build(signer));

        } catch (OperatorCreationException e)
        {
            e.printStackTrace();
        } catch (CertificateException e)
        {
            e.printStackTrace();
        }

        logger.debug(TAG,"Dummy-Signed Cert:\n\t"+dummySignedCert.toString());

        boolean loop=true;


        while (loop)
        {
            try
            {
                loop=false;
                Signature sig = Signature.getInstance(signatureAlgorithm);
                sig.initSign((PrivateKey) aks.getKey("selfSignedPivKey", null));
                sig.update(dummySignedCert.getTBSCertificate());
                byte[] certBytes = ByteUtil.concatenate(Arrays.copyOfRange(dummySignedCert.getEncoded(), 4, dummySignedCert.getEncoded().length - dummySignedCert.getSignature().length), sig.sign());
                certBytes = ByteUtil.concatenate(ByteUtil.hexStringToByteArray(String.format("3082%04X", certBytes.length)), certBytes);

                signedCert = (X509Certificate) cf.generateCertificate(new ByteArrayInputStream(certBytes));
                logger.info(TAG, signedCert.toString());
            } catch (CertificateException e)
            {
                loop=true;
                e.printStackTrace();

            } catch (KeyStoreException e)
            {
                e.printStackTrace();
            } catch (NoSuchAlgorithmException e)
            {
                e.printStackTrace();
            } catch (UnrecoverableEntryException e)
            {
                e.printStackTrace();
            } catch (InvalidKeyException e)
            {
                e.printStackTrace();
            } catch (SignatureException e)
            {
                e.printStackTrace();
            }
        }
        try
        {
            Signature sig=Signature.getInstance(signedCert.getSigAlgName());
            sig.initVerify(signedCert);
            sig.update(signedCert.getTBSCertificate());
            logger.info(TAG,"Signature Verified with Self-Signed Cert: "+sig.verify(signedCert.getSignature()));
        } catch (CertificateException e)
        {
            e.printStackTrace();
        } catch (NoSuchAlgorithmException e)
        {
            e.printStackTrace();
        } catch (InvalidKeyException e)
        {
            e.printStackTrace();
        } catch (SignatureException e)
        {
            e.printStackTrace();
        }


        try
        {
            ks.setCertificateEntry("selfSignedPivCert",signedCert);
        } catch (KeyStoreException e)
        {
            e.printStackTrace();
        }

        try
        {
            ks.store(new FileOutputStream(file),null);
        } catch (KeyStoreException e)
        {
            e.printStackTrace();
        } catch (IOException e)
        {
            e.printStackTrace();
        } catch (NoSuchAlgorithmException e)
        {
            e.printStackTrace();
        } catch (CertificateException e)
        {
            e.printStackTrace();
        }

        logger.alert("Self-Signed Temporary Credential Generated\n"+keystoreCondition, SUCCESS_TITLE);


    }


}
