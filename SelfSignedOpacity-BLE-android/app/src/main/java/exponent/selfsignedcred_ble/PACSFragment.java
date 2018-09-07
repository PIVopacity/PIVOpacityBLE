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

package exponent.selfsignedcred_ble;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseSettings;
import android.content.Intent;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableKeyException;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;
import java.util.UUID;

import exponent.selfsignedcred_ble.credentialservice.SelfSignedCredBLE;
import exponent.selfsignedcred_ble.dhsble.BleClient;
import exponent.selfsignedcred_ble.dhsble.BleScanner;
import exponent.selfsignedcred_ble.dhsble.DHSGattProfile;
import exponent.selfsignedcred_ble.dhsdemo.Logger;
import exponent.selfsignedcred_ble.dhsdemo.SelfSignedCred;


public class PACSFragment extends Fragment
{

    private static String TAG = "PACS";
    private final static String SUCCESS_TITLE = "SUCCESS";
    public static String opacityTag;
    private List<BluetoothDevice> devices;
    private Spinner spinner;
    private ArrayAdapter<String> adapter;
    private List<String>devList = new ArrayList<>();
    private BluetoothDevice authDevice;
    private Handler h = new Handler();
    private Handler hBleAuth = new Handler();

    private Logger logger;

    public static String otp="null";

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState)
    {
        final View v = inflater.inflate(R.layout.fragment_pacs, container, false);

        TextView pacsLogText = (TextView) v.findViewById(R.id.pacsLogText);

        MainActivity.logger = new Logger(MainActivity.mainActivity, pacsLogText);
        logger = MainActivity.logger;

        final BluetoothAdapter mBluetoothAdapter = MainActivity.bluetoothManager.getAdapter();
        final AdvertiseCallback mAdvertiserCallback = new AdvertiseCallback() {
            @Override
            public void onStartSuccess(AdvertiseSettings settingsInEffect) {
                super.onStartSuccess(settingsInEffect);
                logger.info(TAG,"LE Advertiser Started");
            }

            @Override
            public void onStartFailure(int errorCode) {
                super.onStartFailure(errorCode);
                logger.error(TAG,"LE Advertiser Failed: " + errorCode);
            }
        };

        spinner = v.findViewById(R.id.spinnerDevices);


        Button clearbutton = (Button) v.findViewById(R.id.pacsClearLog);

//        final RadioGroup opacRadio=(RadioGroup) v.findViewById(R.id.radioOpacity);

        clearbutton.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View arg0)
            {
                logger.clear();
            }
        });
        final TextView flavorText = (TextView) v.findViewById(R.id.flavorText);

        getOpacityFlavor(flavorText);




//Removed radio button and credential selector, Read Opacity type from self-signed PIV
//        RadioButton opac128Button=(RadioButton) v.findViewById(R.id.radio128);
//        RadioButton opac192Button=(RadioButton) v.findViewById(R.id.radio192);
//        if(SelfSignedCredBLE.opacityTag.equals("2E"))
//        {
//            opac128Button.setChecked(false);
//            opac192Button.setChecked(true);
//        }
//        else
//        {
//            opac128Button.setChecked(true);
//            opac192Button.setChecked(false);
//        }
//
//        final RadioButton[] opacityRadioButton = new RadioButton[1];
//        Button opacResetButton = (Button) v.findViewById(R.id.opacButton);
//        opacResetButton.setOnClickListener(new View.OnClickListener() {
//            @Override
//            public void onClick(View arg0)
//            {
//                //MainActivity.mainActivity.stopService(new Intent(MainActivity.mainActivity,SelfSignedCredBLE.class));
//                opacityRadioButton[0] = (RadioButton) v.findViewById(opacRadio.getCheckedRadioButtonId());
//                opacityTag = (String) opacityRadioButton[0].getText();
//                if(opacityTag.startsWith("192"))
//                {
//                    opacityTag="2E";
//                }
//                else
//                {
//                    opacityTag="27";
//                }
//                logger.clear();
//                Toast.makeText(MainActivity.mainActivity,"Credential Service Restarting",Toast.LENGTH_SHORT).show();
//                //MainActivity.mainActivity.startService(new Intent(MainActivity.mainActivity,SelfSignedCredBLE.class));
//            }
//        });


        Button scanButton = (Button) v.findViewById(R.id.scanButton);
        scanButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                getOpacityFlavor(flavorText);
                BleScanner bleScan = new BleScanner(logger, mBluetoothAdapter, mAdvertiserCallback);
                if(null != devices) devices.clear();
                devList.clear();
                devices = bleScan.scan();

            }
        });

        h.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (devices != null){
                    for(BluetoothDevice d : devices){
                        if(!devList.contains(d.getName() + "  " + d.getAddress())) {
                            devList.add(d.getName() + "  " + d.getAddress());
                        }
                    }
                }
                if (!devList.isEmpty()){
                    // Create an ArrayAdapter using the string array and a default spinner layout
                    adapter = new ArrayAdapter<String>(getContext(), R.layout.spinner_item_custom, devList);
                    // Specify the layout to use when the list of choices appears
                    adapter.setDropDownViewResource(R.layout.spinner_drop_menu_custom);
                    // Apply the adapter to the spinner
                    spinner.setAdapter(adapter);
                }
                h.postDelayed(this,500);
            }
        }, 500);


        spinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int pos, long id) {

                for(BluetoothDevice d : devices){
                        if(parent.getItemAtPosition(pos).toString().contains(d.getAddress())) authDevice = d;

                }

            }

            @Override
            public void onNothingSelected(AdapterView<?> parent)
            {

            }
        });

        final BleClient bleClient = new BleClient(logger);

        final boolean[] gattConnected = {false};

        final Button authButton = (Button) v.findViewById(R.id.authButton);
        authButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if(null != authDevice){
                    otp="null";

                    logger.info(TAG, "Auth Device:  " + authDevice.getName() + "  " + authDevice.getAddress());

                    final BluetoothAdapter mBluetoothAdapter = MainActivity.bluetoothManager.getAdapter();
                    BluetoothDevice remoteDevice = mBluetoothAdapter.getRemoteDevice(authDevice.getAddress());
                    final BluetoothGatt mGatt = remoteDevice.connectGatt(MainActivity.mainActivity, false, bleClient);
                    gattConnected[0] = mGatt.connect();
                    logger.info(TAG, "mGatt connect: " + gattConnected[0]);

                    final Timer t = new Timer();
                    t.schedule(new TimerTask() {
                        @Override
                        public void run() {
                            bleClient.pushAuthenticate();
                            if(bleClient.connectionEstablished == BluetoothProfile.STATE_CONNECTED &&
                                    bleClient.connectionState == BluetoothProfile.STATE_DISCONNECTED) {
                                logger.error(TAG, "Canceling authentication task timer");
                                t.cancel();
//                                BluetoothGattDescriptor descriptor = mGatt
//                                        .getService(DHSGattProfile.COMMS.getUuid())
//                                        .getCharacteristic(DHSGattProfile.TX.getUuid())
//                                        .getDescriptor(UUID.fromString("00002902-0000-1000-8000-00805F9B34FB"));
//                                descriptor.setValue(BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE);
//                                mGatt.writeDescriptor(descriptor);
                                mGatt.disconnect();
                            }
                            if(!otp.equalsIgnoreCase("null")){
                                t.cancel();
//                                BluetoothGattDescriptor descriptor = mGatt
//                                        .getService(DHSGattProfile.COMMS.getUuid())
//                                        .getCharacteristic(DHSGattProfile.TX.getUuid())
//                                        .getDescriptor(UUID.fromString("00002902-0000-1000-8000-00805F9B34FB"));
//                                descriptor.setValue(BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE);
//                                mGatt.writeDescriptor(descriptor);
                                mGatt.disconnect();
                                logger.alert("OTP   " + otp.substring(0,3) + "  " + otp.substring(3), SUCCESS_TITLE);
                                logger.info(TAG, "\n\nOTP   " + otp.substring(0,3) + "  " + otp.substring(3));
                            }
                            //bleClient.pushAuthenticate();
                        }
                    }, 300, 100);



                }else logger.error(TAG, "Auth Device:  Null");

            }
        });


        return v;

    }

    private void getOpacityFlavor(TextView flavorText){
        File file = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "PIV_Auth_KeyStore");
        if(file.exists()){
            KeyStore ks = null;
            try
            {
                ks = KeyStore.getInstance(KeyStore.getDefaultType());
                ks.load(new FileInputStream(file),null);
                if(((X509Certificate)ks.getCertificate("selfSignedPivCert")).getSigAlgName().contains("384")){
                    opacityTag = "2E";
                    flavorText.setText("192-bit Opacity");
                }else if (((X509Certificate)ks.getCertificate("selfSignedPivCert")).getSigAlgName().contains("256")){
                    opacityTag = "27";
                    flavorText.setText("128-bit Opacity");
                } else throw new CertificateException();

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
        }else {
            flavorText.setText("Keystore Empty!\nDerive new credential");
        }
    }
}
