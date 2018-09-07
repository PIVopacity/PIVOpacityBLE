# Secure Derived Credential Demo -- Android

### About ###
[Exponent, Inc.](http://www.exponent.com) has developed a proof of concept demonstration to show the feasibility of using Bluetooth Low Energy on a mobile device for physical access control and authentication without the reliance on device pairing or encryption and message integrity provided by the BLE channel.  This demonstration implements a protocol called OPACITY (as defined in [NIST Special Publication 800-73-4](http://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-73-4.pdf)) to rapidly establish an app layer encrypted communication channel between mobile devices.  Using the app layer encryption and treating the BLE channel as a transparent layer allows devices to rapidly and securely exchange information without the burden of pairing devices.  Additionally, this demonstration utilizes a new GATT Profile which is made available as non-proprietary and platform independent.  Platform indepence allows for secure authentication that is interoperable between Android and iOS devices. 

In both the Android and iOS demonstrations a self-signed credential is derived on the phone by generating a key pair in the mobile devices secure hardware.  An associated X.509 public certificate is then created and securely signed with the new private key to create an analog for a PIV/CAC credential (or derived credential) with a secure key pair, and necessary attributes to represent the device holder's identity and usage permissions.  

This research was conducted under contract with the U.S Department of Homeland Security (DHS) Science and Technology Directorate (S&T) and sponsored by Kantara Initiative Inc.  Any opinions contained herein are those of the author and do not necessarily reflect those of [DHS S&T](https://www.dhs.gov/science-and-technology).


### License ###
Software distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND


See [LICENSE]()


### Security ###
This project was developed to demonstrate communication functionality only and is not meant to serve as a fully secured example of the communication protocol.
