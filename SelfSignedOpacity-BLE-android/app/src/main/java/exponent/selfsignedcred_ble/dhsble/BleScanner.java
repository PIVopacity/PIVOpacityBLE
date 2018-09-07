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
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanFilter;
import android.bluetooth.le.ScanResult;
import android.bluetooth.le.ScanSettings;
import android.os.ParcelUuid;
import android.util.ArrayMap;

import java.util.ArrayList;
import java.util.List;

import exponent.selfsignedcred_ble.dhsdemo.Logger;

public class BleScanner {

    private Logger logger;
    private BluetoothAdapter bluetoothAdapter;
    private AdvertiseCallback mAdvertiseCallback;
    private ParcelUuid advtUuid = new DHSGattProfile().ADVERTISE;

    String TAG = "BLE Scanner";


    private List<BluetoothDevice> devices;
    private ArrayMap<String, Integer> rssi = new ArrayMap<>();

    private ScanCallback mScanCallback = new ScanCallback() {
        @Override
        public void onScanResult(int callbackType, ScanResult result) {
            super.onScanResult(callbackType, result);
            //logger.info(TAG,"CallBack Device: "+result.getDevice().getName()+"    RSSI: "+result.getRssi());
            addBluetoothDevice(result.getDevice());
            rssi.put(result.getDevice().getAddress(), result.getRssi());
        }

        @Override
        public void onBatchScanResults(List<ScanResult> results) {
            super.onBatchScanResults(results);
            for (ScanResult result : results) {
                //logger.info(TAG,"CallBack Device: "+result.getDevice().getName());
                addBluetoothDevice(result.getDevice());
                rssi.put(result.getDevice().getAddress(), result.getRssi());
            }
        }

        @Override
        public void onScanFailed(int errorCode) {
            super.onScanFailed(errorCode);
        }

        private void addBluetoothDevice(BluetoothDevice device) {
            if (!devices.contains(device)) {
                devices.add(device);
                //logger.info(TAG,"CallBack Device: "+device.getName());
            }
        }
    };

    private final ScanSettings scanSettings = new ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .setMatchMode(ScanSettings.MATCH_MODE_AGGRESSIVE)
            .build();

    public BleScanner(Logger logger, BluetoothAdapter bluetoothAdapter, AdvertiseCallback mAdvertiseCallback){
        this.logger = logger;
        if(!bluetoothAdapter.isEnabled())bluetoothAdapter.enable();
        if(bluetoothAdapter.isDiscovering()) bluetoothAdapter.cancelDiscovery();
        this.bluetoothAdapter = bluetoothAdapter;
        this.mAdvertiseCallback = mAdvertiseCallback;
    }


    public List<BluetoothDevice> scan(){
        logger.info(TAG, "Discover DHS BLE");
        BluetoothLeScanner bluetoothLeScanner = bluetoothAdapter.getBluetoothLeScanner();
        bluetoothLeScanner.stopScan(mScanCallback);
        //bluetoothLeScanner.flushPendingScanResults(mScanCallback);
        devices = new ArrayList<>();
        List<ScanFilter> dhsFilter = new ArrayList<>();
        dhsFilter.add(new ScanFilter.Builder().setServiceUuid(advtUuid).build());
        bluetoothLeScanner.startScan(dhsFilter,scanSettings,mScanCallback);

        return devices;

    }

    public ArrayMap<String, Integer> getRssiList(){
        return rssi;
    }

}

