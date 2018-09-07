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

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattServer;
import android.bluetooth.BluetoothGattServerCallback;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseData;
import android.bluetooth.le.AdvertiseSettings;
import android.bluetooth.le.BluetoothLeAdvertiser;
import android.content.Context;
import android.os.Handler;
import android.os.ParcelUuid;
import android.util.Log;
import android.widget.Toast;

import java.nio.ByteBuffer;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.locks.Lock;

import exponent.selfsignedcred_ble.dhsdemo.ByteUtil;
import exponent.selfsignedcred_ble.dhsdemo.Logger;

import static android.bluetooth.BluetoothGatt.GATT_SUCCESS;

public class BleAdvertiser {

    private Logger logger;
    private BluetoothAdapter bluetoothAdapter;
    private int timeout = 100000;
    String TAG = "BLE Advertiser";
    private ParcelUuid advtUuid = DHSGattProfile.ADVERTISE;

    private AdvertiseCallback mAdvertiseCallback = new AdvertiseCallback() {
        @Override
        public void onStartSuccess(AdvertiseSettings settingsInEffect) {
            Log.i(TAG, "LE Advertise Started.");
        }

        @Override
        public void onStartFailure(int errorCode) {
            Log.w(TAG, "LE Advertise Failed: " + errorCode);
        }
    };

    private AdvertiseSettings settings = new AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
            .setConnectable(true)
            .setTimeout(timeout)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
            .build();

    // Defines which service to advertise.
    private AdvertiseData data = new AdvertiseData.Builder()
            .setIncludeDeviceName(true)
            .setIncludeTxPowerLevel(false)
            .addServiceUuid(advtUuid)
            .build();


    public BleAdvertiser(Logger logger, BluetoothAdapter blAdapt, int timeout){
        this.bluetoothAdapter = blAdapt;
        this.timeout = timeout;
        this.logger = logger;
    }

    public BleAdvertiser(Logger logger, BluetoothAdapter blAdapt){
        this.bluetoothAdapter = blAdapt;
        this.logger = logger;
    }


    public AdvertiseCallback advertise(){
        try {
            BluetoothLeAdvertiser bluetoothLeAdvertiser = bluetoothAdapter.getBluetoothLeAdvertiser();
            if(null != bluetoothLeAdvertiser ){
                bluetoothLeAdvertiser.stopAdvertising(mAdvertiseCallback);
                bluetoothLeAdvertiser.startAdvertising(settings, data, mAdvertiseCallback);
                Thread.sleep(1000);
            }
        } catch (Exception ex){
            logger.error(TAG,"Advertising Error: " + ex);
            return null;
        }

        logger.info(TAG,"\nDevice Name:  "+bluetoothAdapter.getName());
        logger.info(TAG,"Advertising UUID:  "+advtUuid.toString()+"\n");
        return mAdvertiseCallback;
    }

    private BluetoothGattServer mGattServer;
    private byte[] rxValue = {0x00};
    private byte[] txValue;
    private int sessionCommandCount = 1;
    private int sessionReceiveCount = 0;
    private boolean txBool = false;
    private List<BluetoothDevice> registeredDevices = new ArrayList<>();
    private int mMtu = 20;
    private byte[] longCommand;

    private BluetoothGattServerCallback mGattServerCallback = new BluetoothGattServerCallback() {
        @Override
        public void onConnectionStateChange(BluetoothDevice device, int status, int newState) {
            super.onConnectionStateChange(device, status, newState);
            if(newState == BluetoothProfile.STATE_CONNECTED) {
                logger.info(TAG,"Connection State:  "+newState);
                bluetoothAdapter.getBluetoothLeAdvertiser().stopAdvertising(mAdvertiseCallback);
            }
        }

        @Override
        public void onServiceAdded(int status, BluetoothGattService service) {
            super.onServiceAdded(status, service);
        }

        @Override
        public void onCharacteristicReadRequest(BluetoothDevice device, int requestId, int offset, BluetoothGattCharacteristic characteristic) {
            super.onCharacteristicReadRequest(device, requestId, offset, characteristic);
            logger.info(TAG, "Read Request  ");
            mGattServer.sendResponse(device, requestId, GATT_SUCCESS, 0, characteristic.getValue());
//            if (characteristic.getUuid().equals(DHSGattProfile.TX.getUuid()) && txBool) {
//                mGattServer.sendResponse(device, requestId, GATT_SUCCESS, 0, txValue);
//                characteristic.setValue(txValue);
//                mGattServer.notifyCharacteristicChanged(device, characteristic, true);
//            } else mGattServer.sendResponse(device, requestId, BluetoothGatt.GATT_READ_NOT_PERMITTED, 0, txValue);
        }

        @Override
        public void onCharacteristicWriteRequest(BluetoothDevice device, int requestId, BluetoothGattCharacteristic characteristic, boolean preparedWrite, boolean responseNeeded, int offset, byte[] value) {
            super.onCharacteristicWriteRequest(device, requestId, characteristic, preparedWrite, responseNeeded, offset, value);
            if (characteristic.getUuid().equals(DHSGattProfile.RX.getUuid())) {
//                rxValue = value;
//                logger.info(TAG, "Write Request  " + ByteUtil.toHexString(rxValue," "));
//                sessionReceiveCount = (int)((rxValue[0] & 0xFF) << 8 | (rxValue[1] & 0xFF));
//                rxValue = Arrays.copyOfRange(rxValue,2,rxValue.length);


                logger.info(TAG, "Characteristic Changed " + characteristic.getUuid().toString());
                logger.info(TAG, "Value: " + ByteUtil.toHexString(value, " "));

                if( Arrays.equals(value, ByteUtil.hexStringToByteArray("45 4F 4D"))) {
                    logger.info(TAG, "Received Full Command: " + ByteUtil.toHexString(longCommand, " "));
                    rxValue = longCommand;
                    sessionReceiveCount=(int)((rxValue[0] & 0xFF) << 8 | (rxValue[1] & 0xFF));
                    rxValue = Arrays.copyOfRange(rxValue,2,rxValue.length);
                    longCommand=null;

                } else longCommand = ByteUtil.concatenate(longCommand, value);

                mGattServer.sendResponse(device, requestId, GATT_SUCCESS, 0, null);
            }
        }

//        @Override
//        public void onDescriptorReadRequest(BluetoothDevice device, int requestId, int offset, BluetoothGattDescriptor descriptor) {
//            super.onDescriptorReadRequest(device, requestId, offset, descriptor);
//        }
//
        @Override
        public void onDescriptorWriteRequest(BluetoothDevice device, int requestId, BluetoothGattDescriptor descriptor, boolean preparedWrite, boolean responseNeeded, int offset, byte[] value) {
            super.onDescriptorWriteRequest(device, requestId, descriptor, preparedWrite, responseNeeded, offset, value);
            if (UUID.fromString("00002902-0000-1000-8000-00805F9B34FB").equals(descriptor.getUuid())) {
                if (Arrays.equals(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE, value)) {
                    registeredDevices.add(device);
                    notifySubscribers(null);
                } else if (Arrays.equals(BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE, value)) {
                    registeredDevices.remove(device);
                }

                if (responseNeeded) {
                    mGattServer.sendResponse(device, requestId, GATT_SUCCESS, 0, null);
                }

            }
        }
//
//        @Override
//        public void onExecuteWrite(BluetoothDevice device, int requestId, boolean execute) {
//            super.onExecuteWrite(device, requestId, execute);
//        }
//
        @Override
        public void onNotificationSent(BluetoothDevice device, int status) {
            super.onNotificationSent(device, status);
            logger.info(TAG,"Notification Sent:  "+device.getAddress()+" status: "+status);
        }

        @Override
        public void onMtuChanged(BluetoothDevice device, int mtu) {
            super.onMtuChanged(device, mtu);
            logger.info(TAG,"MTU Changed: "+device.toString()+"  New MTU: "+String.valueOf(mtu));
            mMtu = mtu;
        }
//
//        @Override
//        public void onPhyUpdate(BluetoothDevice device, int txPhy, int rxPhy, int status) {
//            super.onPhyUpdate(device, txPhy, rxPhy, status);
//        }
//
//        @Override
//        public void onPhyRead(BluetoothDevice device, int txPhy, int rxPhy, int status) {
//            super.onPhyRead(device, txPhy, rxPhy, status);
//        }
    };


    public boolean initializeGattServer(Context context, BluetoothManager bluetoothManager) {
        try{
            mGattServer = bluetoothManager.openGattServer(context, mGattServerCallback);
            mGattServer.addService(DHSGattProfile.createService());
            return true;
        } catch( Exception ex){
            logger.error(TAG,"Gatt Server Error: " + ex.getStackTrace());
            return false;
        }

    }

//    public byte[] transceive(byte[] txData){
//        txValue = ByteUtil.concatenate(new byte[] {(byte) ((sessionCommandCount >> 8 ) & 0xFF), (byte) (sessionCommandCount & 0xFF)}, txData);
//        notifySubscribers(txData);
//        txBool = true;
//        while(sessionCommandCount != sessionReceiveCount){
//            try {
//                Thread.sleep(200);
//            } catch (InterruptedException e) {
//                e.printStackTrace();
//            }
//        }
//        sessionCommandCount++;
//        return rxValue;
//    }

    public byte[] transceive(byte[] txData){
        txValue = ByteUtil.concatenate(new byte[] {(byte) ((sessionCommandCount >> 8 ) & 0xFF), (byte) (sessionCommandCount & 0xFF)}, txData);
        if(sessionCommandCount == 1){
            BluetoothGattCharacteristic ch = mGattServer.getService(DHSGattProfile.COMMS.getUuid()).getCharacteristic(DHSGattProfile.TX.getUuid());
            ch.setValue(txValue);
        }
        else notifySubscribers(txValue);

        txBool = true;
        while(sessionCommandCount != sessionReceiveCount){
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        sessionCommandCount++;
        return rxValue;
    }

    private void notifySubscribers(byte[] command)
    {
        BluetoothGattCharacteristic ch = mGattServer.getService(DHSGattProfile.COMMS.getUuid()).getCharacteristic(DHSGattProfile.TX.getUuid());
        if(null == command) command = ch.getValue();
        for(byte[] frag : subFragement(command)) {
            for (BluetoothDevice d : registeredDevices) {
                ch.setValue(frag);
                mGattServer.notifyCharacteristicChanged(d, ch, false);
            }
        }

    }

    private List<byte[]> subFragement(byte[] longCommand) {
        int split = mMtu - 5;
        int steps = (int) Math.floor(longCommand.length / split);
        List<byte[]> value = new ArrayList<>();
        if (steps == 0) value.add(longCommand);
        else {
            for (int i = 0; i < steps; i++) {
                value.add(Arrays.copyOfRange(longCommand, i * split, (i + 1) * split));
            }
            if (longCommand.length % split != 0) value.add(Arrays.copyOfRange(longCommand, (steps) * split, longCommand.length));
        }

        value.add(ByteUtil.hexStringToByteArray("45 4F 4D"));

        return value;
    }
}
