# Who Dis? (new fone)
This tweak provides caller ID and checks to unknown numbers using the Truecaller API. 

To use this, the Truecaller app *must* be installed and setup on the device.

## Dependancies

- rocketbootstrap
- Cydia Substrate

## Building

iOSOpenDev is used to develop this tweak, though should be easy enough to port to theos' makefile system.

The following libraries are linked into this tweak:
- libSustrate
- CoreTelephony
- MobileCoreServices
- UIKit
- CoreGraphics
- AppSupport
- libRocketBootstrap

## Nice technical details
Since this utilises multiple processes to complete the task, feel free to use this as a learning resource on how to use CPDistributedMessagingCenter. 

TODO: Write more here.

Released under the BSD 2-Clause License.
