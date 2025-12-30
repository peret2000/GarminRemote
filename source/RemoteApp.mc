using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Ant;
using Toybox.System;
using Toybox.Graphics;

// --- ANT+ Controls Profile Constants ---
const DEVICE_TYPE_CONTROLS = 16;  // Specific ID used by GoldenCheetah
const RF_FREQ = 57;               // 2457 MHz
const PERIOD = 8192;              // 4 Hz
const TRANS_TYPE = 0;             // Wildcard for search

// Command Codes
const ANT_CONTROL_GENERIC_CMD_PAGE = 0x49;
const CMD_PLAY = 0x20;  // Mapped to START in GC
const CMD_STOP = 0x21;  // Mapped to STOP in GC
const CMD_LAP  = 0x24;  // Mapped to LAP (or Next Track)

class RemoteDataField extends WatchUi.DataField {
    var antChannel;
    var commandSeq = 0;
    var statusText = "Ready";
    var connectedDeviceId = 0;
    var lastStatusTime = 0;

    function initialize() {
        DataField.initialize();
        setupAnt();
    }

    // ANT+ Channel Configuration
    function setupAnt() {
        // Create generic channel
        // SLAVE (RX) - GoldenCheetah is the Master broadcasting
        try {
            antChannel = new Ant.GenericChannel(method(:onMessage), new Ant.ChannelAssignment(
                Ant.CHANNEL_TYPE_RX_NOT_TX, // Slave (Receives, but can send responses)
                Ant.NETWORK_PLUS            // Public ANT+ Network
            ));

            // Search configuration
            var deviceCfg = new Ant.DeviceConfig({
                :deviceNumber => 0,                 // 0 = Wildcard (search for any)
                :deviceType => DEVICE_TYPE_CONTROLS,// Must match GC (16)
                :transmissionType => TRANS_TYPE,
                :messagePeriod => PERIOD,
                :radioFrequency => RF_FREQ,
                :searchTimeoutLowPriority => 10,
                :searchThreshold => 0
            });

            antChannel.setDeviceConfig(deviceCfg);
            antChannel.open();
        } catch (e) {
            System.println("Error setupAnt: " + e.getErrorMessage());
            statusText = "Error ANT";
        }
    }

    // ANT message handling
    function onMessage(msg as Ant.Message) as Void {
        if (Ant.MSG_CODE_EVENT_CHANNEL_CLOSED == msg.messageId) {
            antChannel.open(); // Reopen if closed
        } 
        else if (Ant.MSG_ID_BROADCAST_DATA == msg.messageId) {
            // We found the Master (GC)
            var deviceId = msg.deviceNumber;
            if (connectedDeviceId != deviceId) {
                connectedDeviceId = deviceId;
                WatchUi.requestUpdate();
            }
        }
    }

    // Send command to GoldenCheetah
    function sendCommand(commandId) {
        if (antChannel == null) { return; }

        commandSeq = (commandSeq + 1) % 256;

        var cmdLow = commandId & 0xFF;
        var cmdHigh = (commandId >> 8) & 0xFF;

        // Payload according to ANT+ Remote Control Profile - Generic Command Page 0x49
        var payload = [
            ANT_CONTROL_GENERIC_CMD_PAGE,
            0xFF,
            0xFF,
            0xFF,
            0xFF,
            commandSeq,
            cmdLow,
            cmdHigh
        ];
        
        var message = new Ant.Message();
        message.setPayload(payload);
        antChannel.sendAcknowledge(message);
        
    }

    function setStatus(text) {
        statusText = text;
        lastStatusTime = System.getTimer();
        WatchUi.requestUpdate();
    }

    function onTimerStart() {
        sendCommand(CMD_PLAY);
        setStatus("START");
    }

    function onTimerPause() {
        sendCommand(CMD_PLAY);
        setStatus("PAUSE");
    }

    function onTimerResume() {
        sendCommand(CMD_PLAY);
        setStatus("RESUME");
    }

    function onTimerStop() {
        sendCommand(CMD_PLAY);
        setStatus("STOP");
    }

    function onTimerLap() {
        sendCommand(CMD_LAP);
        setStatus("LAP");
    }

    // DataField compute
    function compute(info) {
        return statusText;
    }
    
    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var bgColor = getBackgroundColor();
        var fgColor = Graphics.COLOR_WHITE;
        
        if (bgColor == Graphics.COLOR_WHITE) {
            fgColor = Graphics.COLOR_BLACK;
        }
        
        dc.setColor(bgColor, bgColor);
        dc.clear();
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        
        // Header
        dc.drawText(width/2, 0, Graphics.FONT_XTINY, "ANT+Remote", Graphics.TEXT_JUSTIFY_CENTER);

        // Determine text to show
        var textToShow = statusText;
        var now = System.getTimer();
        
        if (now - lastStatusTime > 5000) {
             if (connectedDeviceId != 0) {
                 textToShow = "ID: " + connectedDeviceId;
             } else {
                 textToShow = "Ready";
             }
        }
        
        dc.drawText(width/2, height/2, Graphics.FONT_MEDIUM, textToShow, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class RemoteApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [ new RemoteDataField() ];
    }
}
