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

Written by Christopher Williams, Ph.D. (cwilliams@exponent.com)
*/

package exponent.selfsignedcred_ble.dhsdemo;

import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

public class OTP {

    public static String generateOTP(byte[] key, byte[] nonce){
        byte[] botp;
        String otp="NULL";
        Mac hmac = null;
        try {
            hmac = Mac.getInstance("HmacSHA384");
            hmac.init(new SecretKeySpec(key,"AES"));
            botp = Arrays.copyOfRange(hmac.doFinal(nonce),0,6);
            StringBuilder s = new StringBuilder();
            for ( byte b : botp) s.append((b & 0xff) % 10);
            otp=s.toString();
        } catch (NoSuchAlgorithmException | InvalidKeyException e) {
            e.printStackTrace();
        }
        return otp;
    }
}
