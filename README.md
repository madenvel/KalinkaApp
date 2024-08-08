# Kalinka Audio Player App

This project is a flutter application for multiple platforms (Windows, Linux, Android, iPhone) that allows you to control the backend (Kalinka Audio Player) running on a device in your network.

## Installation of the APK

**Make sure you build and install and run Kalinka Player (backend) before proceeding with the next steps**.

A pre-built APK for Android is provided. To install the app to your phone you need:
1. Install Android Platform Tools
2. Connect your phone to the PC and enable developer mode
3. Download the package and run the command:
```
adb install <apk_name>
```
## First run
The application will show connection screen on the first start which will allow you to choose the machine where the server is running.
Zeroconf is used for the discovery and it is known to not work sometimes in some networks. If your server cannot be found after a minute or so, try entering the address and port manually.
