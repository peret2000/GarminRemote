# RemoteApp - Garmin ANT+ Remote Control

RemoteApp is a Connect IQ DataField designed to act as a remote control using the ANT+ protocol. It is specifically configured to interface with software like [**GoldenCheetah**](https://github.com/GoldenCheetah/GoldenCheetah), allowing you to control playback (Start, Stop, Lap) directly from your Garmin device during an activity.

## Compatibility

This application has been explicitly tested and verified on the following devices:
*   **Garmin Fenix 6**
*   **Garmin Fenix 6X Pro**

However, due to the standard nature of the Connect IQ and ANT+ APIs used, it is highly likely to work on **almost any modern Garmin device** that supports Connect IQ DataFields and ANT+ connectivity (minSdkVersion 3.2.0).

## Development Setup

To build and modify this project, you need to set up the Connect IQ environment.

### 1. Prerequisites

*   **Java Development Kit (JDK)**: Version 8 or 11 is recommended.
*   **Connect IQ SDK Manager**: Download it from the [Garmin Developer site](https://developer.garmin.com/connect-iq/sdk/).

### 2. Installing the SDK

#### Option A: Via Visual Studio Code (Recommended)
1.  Install **Visual Studio Code**.
2.  Install the **Monkey C** extension from the VS Code Marketplace.
3.  Open the extension settings or run the command `Monkey C: Verify Installation`.
4.  It will prompt you to download the SDK Manager if you haven't already. Use the SDK Manager to download the latest Connect IQ SDK and the device definitions (e.g., fenix6).

#### Option B: Command Line (Linux)
1.  Download the Connect IQ SDK Manager for Linux.
2.  Run the SDK manager to download the SDK and Devices:
    ```bash
    ./sdkmanager
    ```
3.  Set your environment variables (add to your `.bashrc` or `.zshrc`):
    ```bash
    export GARMIN_HOME=~/.garmin/connectiq/sdks/connectiq-sdk-lin-x.x.x-yyyy
    export PATH=$PATH:$GARMIN_HOME/bin
    ```
4.  Generate a developer key (if you don't have one):
    ```bash
    openssl genrsa -out developer_key.pem 4096
    openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
    ```

## Building the Project

### Using Visual Studio Code
1.  Open this folder in VS Code.
2.  Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac) and select **Monkey C: Build for Device**.
3.  Select the target device (e.g., `fenix6`).
4.  The output `.prg` file will be generated in the `bin/` folder.

### Using Command Line
To build the project manually, you can use the `monkeyc` compiler.

```bash
# Example for Fenix 6
monkeyc \
  -o bin/GarminRemote.prg \
  -f project.jungle \
  -y developer_key.der \
  -d fenix6 \
  -w \
  -r
```

*   `-o`: Output file path.
*   `-f`: Project jungle file (usually `monkey.jungle` or `project.jungle`).
*   `-y`: Path to your developer key.
*   `-d`: Target device ID.
*   `-r`: Release build (no debug info).

## Installing on Device

Once you have generated the binary file (e.g., `GarminRemote.prg`):

1.  Connect your Garmin watch to your computer via USB.
2.  It should mount as a mass storage device / external drive.
3.  Navigate to the `GARMIN/APPS` folder on the watch drive.
4.  Copy the `GarminRemote.prg` file from your `bin/` folder into the `GARMIN/APPS` folder on the watch.
5.  Disconnect the watch safely.
6.  On your watch, go to an Activity (e.g., Run, Bike) -> Settings -> Data Screens -> Layout -> Add the "RemoteApp" Connect IQ field.
