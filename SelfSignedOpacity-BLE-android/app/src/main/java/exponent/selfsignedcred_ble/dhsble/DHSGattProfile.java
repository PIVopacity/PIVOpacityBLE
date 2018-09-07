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

package exponent.selfsignedcred_ble.dhsble;

import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.os.ParcelUuid;

import java.nio.charset.Charset;
import java.util.UUID;

public class DHSGattProfile{
    public static ParcelUuid ADVERTISE = new ParcelUuid(UUID.nameUUIDFromBytes("DHS Auth".getBytes(Charset.forName("UTF-8"))));
    public static ParcelUuid COMMS = new ParcelUuid(UUID.nameUUIDFromBytes("DHS Auth Comms".getBytes(Charset.forName("UTF-8"))));
    public static ParcelUuid TX = new ParcelUuid(UUID.nameUUIDFromBytes("DHS Auth Comms Tx".getBytes(Charset.forName("UTF-8"))));
    public static ParcelUuid RX = new ParcelUuid(UUID.nameUUIDFromBytes("DHS Auth Comms Rx".getBytes(Charset.forName("UTF-8"))));


    public static BluetoothGattService createService(){
        BluetoothGattService comms = new BluetoothGattService(COMMS.getUuid(), BluetoothGattService.SERVICE_TYPE_PRIMARY);

        BluetoothGattCharacteristic tx = new BluetoothGattCharacteristic(TX.getUuid(), BluetoothGattCharacteristic.PROPERTY_NOTIFY, BluetoothGattCharacteristic.PERMISSION_READ);
        BluetoothGattCharacteristic rx = new BluetoothGattCharacteristic(RX.getUuid(), BluetoothGattCharacteristic.PROPERTY_WRITE|BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE, BluetoothGattCharacteristic.PERMISSION_WRITE);

        BluetoothGattDescriptor txDesc = new BluetoothGattDescriptor(UUID.fromString("00002902-0000-1000-8000-00805F9B34FB"), BluetoothGattCharacteristic.PERMISSION_READ|BluetoothGattCharacteristic.PERMISSION_WRITE);

        tx.addDescriptor(txDesc);

        comms.addCharacteristic(tx);
        comms.addCharacteristic(rx);
        return comms;
    }



}
