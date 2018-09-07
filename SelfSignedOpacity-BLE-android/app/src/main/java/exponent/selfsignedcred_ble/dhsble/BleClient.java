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

import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothProfile;
import android.os.Handler;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

import exponent.selfsignedcred_ble.credentialservice.SelfSignedCredBLE;
import exponent.selfsignedcred_ble.dhsdemo.ByteUtil;
import exponent.selfsignedcred_ble.dhsdemo.Logger;

public class BleClient extends BluetoothGattCallback {
    private byte[] rxData;
    private byte[] txData;

    private String TAG = "BleClient";
    private Logger logger;
    private List<BluetoothGattService> services;
    private BluetoothGatt gatt;
    Handler h = new Handler();
    private int mMtu = 20;
    private int MTU = 512;
    private int sessionCommandCount = 0;
    public int connectionEstablished = 0;

    private SelfSignedCredBLE credBLE = new SelfSignedCredBLE();

    public int connectionState=BluetoothProfile.STATE_DISCONNECTED;

    public BleClient(Logger logger){
        this.logger = logger;
    }

    public BleClient(Logger logger, int mtu){
        this.logger = logger;
        MTU = mtu;
    }

    private byte[] longCommand;

//    private void readRemote(){
//        if (null != gatt) {
//            if (null != gatt.getService(DHSGattProfile.COMMS.getUuid())) {
//                if (null != gatt.getService(DHSGattProfile.COMMS.getUuid()).getCharacteristic(DHSGattProfile.TX.getUuid())) {
//                    gatt.readCharacteristic(gatt.getService(DHSGattProfile.COMMS.getUuid()).getCharacteristic(DHSGattProfile.TX.getUuid()));
//
//                }
//            }
//        }
//    }

//    private void writeRemote(byte[] data){
//        boolean wb = false;
//        rxData = data;
//
//        while (!wb) {
//            if (null != gatt) {
//                if (null != gatt.getService(DHSGattProfile.COMMS.getUuid())) {
//                    if (null != gatt.getService(DHSGattProfile.COMMS.getUuid()).getCharacteristic(DHSGattProfile.RX.getUuid())) {
//                        gatt.getService(DHSGattProfile.COMMS.getUuid()).getCharacteristic(DHSGattProfile.RX.getUuid())
//                                .setValue(ByteUtil.concatenate(new byte[] {(byte) ((sessionCommandCount >> 8 ) & 0xFF), (byte) (sessionCommandCount & 0xFF)}, rxData));
//                        wb = gatt.writeCharacteristic(gatt.getService(DHSGattProfile.COMMS.getUuid()).getCharacteristic(DHSGattProfile.RX.getUuid()));
//
//                    }
//                }
//            }
//        }
//
//    }

    private void writeRemote(byte[] data){
        boolean wb;
        rxData = ByteUtil.concatenate(new byte[] {(byte) ((sessionCommandCount >> 8 ) & 0xFF), (byte) (sessionCommandCount & 0xFF)}, data);
        for(byte[] frag : subFragement(rxData)) {
            wb = false;
            while (!wb) {
                    if (null != gatt) {
                        if (null != gatt.getService(DHSGattProfile.COMMS.getUuid())) {
                            if (null != gatt.getService(DHSGattProfile.COMMS.getUuid()).getCharacteristic(DHSGattProfile.RX.getUuid())) {
                                gatt.getService(DHSGattProfile.COMMS.getUuid()).getCharacteristic(DHSGattProfile.RX.getUuid())
                                        .setValue(frag);
                                wb = gatt.writeCharacteristic(gatt.getService(DHSGattProfile.COMMS.getUuid()).getCharacteristic(DHSGattProfile.RX.getUuid()));
                            }
                        }
                    }
            }
        }
    }

    private int sessionCommandCountPrev=0;

    public boolean pushAuthenticate(){
        if (sessionCommandCount>0 && mMtu != MTU) {
            logger.error(TAG, "mMtu: " + mMtu + "\tRequest MTU " + MTU + " Change: " + gatt.requestMtu(MTU));
            return false;
        }
        if (mMtu == MTU && sessionCommandCount == (sessionCommandCountPrev + 1)) {
            writeRemote(credBLE.processCommandApdu(txData));
            sessionCommandCountPrev = sessionCommandCount;
            return true;
        }
//        readRemote();
        return true;
    }

    @Override
    public void onPhyUpdate(BluetoothGatt gatt, int txPhy, int rxPhy, int status) {
        super.onPhyUpdate(gatt, txPhy, rxPhy, status);
    }

    @Override
    public void onPhyRead(BluetoothGatt gatt, int txPhy, int rxPhy, int status) {
        super.onPhyRead(gatt, txPhy, rxPhy, status);
    }

    @Override
    public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
        super.onConnectionStateChange(gatt, status, newState);
        connectionState=newState;
        logger.error(TAG,"Connection State:  " + connectionState);
        if(newState == BluetoothProfile.STATE_CONNECTED) {
            logger.info(TAG, "Connection State Changed: " + newState + "  " + gatt.discoverServices());
            connectionEstablished = newState;
            logger.error(TAG, "mMtu: " + mMtu + "\tRequest MTU " + MTU + " Change: " + gatt.requestMtu(MTU));
            this.gatt = gatt;
        }
    }

    @Override
    public void onServicesDiscovered(BluetoothGatt gatt, int status) {
        super.onServicesDiscovered(gatt, status);
        logger.info(TAG,"Services Discovered:  ");
        for (BluetoothGattService gs : gatt.getServices()){
            logger.info(TAG, "\t\t" + gs.getUuid().toString());
            for(BluetoothGattCharacteristic gc : gs.getCharacteristics())
            {
                logger.info(TAG, "\t\t\t\t" + gc.getUuid().toString());
                if(gc.getUuid().equals(DHSGattProfile.TX.getUuid())) {
                    gatt.setCharacteristicNotification(gc, true);
                    BluetoothGattDescriptor descriptor = gc.getDescriptor(UUID.fromString("00002902-0000-1000-8000-00805F9B34FB"));
                    descriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
                    gatt.writeDescriptor(descriptor);
                }
            }
        }
    }

    @Override
    public void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
        super.onCharacteristicRead(gatt, characteristic, status);
        txData = characteristic.getValue();
        logger.info(TAG,"Reading Characteristic  " + characteristic.getUuid().toString() + "\n\t  " + ByteUtil.toHexString(txData, " "));
        sessionCommandCount=(int)((txData[0] & 0xFF) << 8 | (txData[1] & 0xFF));
        txData = Arrays.copyOfRange(txData,2,txData.length);
        //logger.error(TAG,"Separated: " + sessionCommandCount +"  "+ ByteUtil.toHexString(txData, " "));
    }

    @Override
    public void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
        super.onCharacteristicWrite(gatt, characteristic, status);
        logger.info(TAG,"Writing Characteristic  " + characteristic.getUuid().toString() + "   " + status);
    }

    @Override
    public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
        super.onCharacteristicChanged(gatt, characteristic);
        logger.info(TAG, "Characteristic Changed " + characteristic.getUuid().toString());
        logger.info(TAG, "Value: " + ByteUtil.toHexString(characteristic.getValue(), " "));

        if( Arrays.equals(characteristic.getValue(), ByteUtil.hexStringToByteArray("45 4F 4D"))) {
            logger.info(TAG, "Received Full Command: " + ByteUtil.toHexString(longCommand, " "));
            txData = longCommand;
            sessionCommandCount=(int)((txData[0] & 0xFF) << 8 | (txData[1] & 0xFF));
            txData = Arrays.copyOfRange(txData,2,txData.length);
            longCommand=null;

        } else longCommand = ByteUtil.concatenate(longCommand, characteristic.getValue());

    }

    @Override
    public void onDescriptorRead(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
        super.onDescriptorRead(gatt, descriptor, status);
    }

    @Override
    public void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
        super.onDescriptorWrite(gatt, descriptor, status);
        logger.info(TAG, "Descriptor Write:  "+descriptor.getUuid().toString()+"    "+status);
        if (descriptor.getUuid().equals(UUID.fromString("00002902-0000-1000-8000-00805F9B34FB"))) {
            //BluetoothGattCharacteristic ch = gatt.getService(DHSGattProfile.COMMS.getUuid()).getCharacteristic(DHSGattProfile.TX.getUuid());
            //gatt.readCharacteristic(ch);
        }
    }

    @Override
    public void onReliableWriteCompleted(BluetoothGatt gatt, int status) {
        super.onReliableWriteCompleted(gatt, status);
        logger.info(TAG,"Reliable Write Completed:  " + status);
    }

    @Override
    public void onReadRemoteRssi(BluetoothGatt gatt, int rssi, int status) {
        super.onReadRemoteRssi(gatt, rssi, status);
    }

    @Override
    public void onMtuChanged(BluetoothGatt gatt, int mtu, int status) {
        super.onMtuChanged(gatt, mtu, status);
        mMtu=mtu;
        logger.info(TAG,"BluetoothGattCallback MTU changed: " + mtu + "  " + status);
    }


    private List<byte[]> subFragement(byte[] command) {
        int split = mMtu - 5;
        int steps = (int) Math.floor(command.length / split);
        List<byte[]> value = new ArrayList<>();
        if (steps == 0) value.add(command);
        else {
            for (int i = 0; i < steps; i++) {
                value.add(Arrays.copyOfRange(command, i * split, (i + 1) * split));
            }
            if (command.length % split != 0) value.add(Arrays.copyOfRange(command, (steps) * split, command.length));
        }

        value.add(ByteUtil.hexStringToByteArray("45 4F 4D"));
//        Log.e(TAG,"\n\nFrags: ");
//        for(byte[] f : value) Log.e(TAG,"\t"+ByteUtil.toHexString(f," "));
        return value;
    }

}
