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

import android.app.Activity;
import android.nfc.NfcAdapter;
import android.os.Bundle;
import android.os.Environment;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;
import java.io.File;

import exponent.selfsignedcred_ble.dhsdemo.BleCredReader;
import exponent.selfsignedcred_ble.dhsdemo.Logger;
import exponent.selfsignedcred_ble.opacity.Opacity;

import static exponent.selfsignedcred_ble.MainActivity.bleCredReader;


public class AuthFragment extends Fragment
{
    private final static String TAG = "AuthFragment";
    private final static int NFC_READER_FLAGS = NfcAdapter.FLAG_READER_NFC_A | NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK;

    private Activity activity=MainActivity.mainActivity;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState)
    {
        final View v = inflater.inflate(R.layout.fragment_auth, container, false);

        TextView logText = (TextView) v.findViewById(R.id.logTextAuth);
        MainActivity.logger = new Logger(MainActivity.mainActivity, logText);
        Opacity.logger = MainActivity.logger;

        Button advtbutton = (Button) v.findViewById(R.id.advertiseBLE);

        advtbutton.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View arg0)
            {

                MainActivity.logger.clear();
                MainActivity.bleCredReader = new BleCredReader(MainActivity.mainActivity, Opacity.logger);

                new Thread(new Runnable() {
                    @Override
                    public void run() {
                      bleCredReader.authenticate();
                    }
                }).start();
                Toast.makeText(MainActivity.mainActivity,"Advertising BLE for Authentication",Toast.LENGTH_LONG).show();

                //bleCredReader.authenticate();

            }
        });

        Button clearbutton = (Button) v.findViewById(R.id.clearLogAuth);

        clearbutton.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View arg0)
            {
                MainActivity.logger.clear();
            }
        });

        Button clearDownloadButton = (Button) v.findViewById(R.id.clearDownloadsAuth);
        clearDownloadButton.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View arg0)
            {
                for( File child : new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),"/Auth/").listFiles())
                {
                 child.delete();
                }
            }
        });


        return v;
    }

}
