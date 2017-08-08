 //
//  DeviceDetailViewController.swift
//  MetaWearApiTest
//
//  Created by Stephen Schiffli on 11/3/16.
//  Copyright © 2016 MbientLab. All rights reserved.
//

import UIKit
import StaticDataTableViewController
import MetaWear
import MessageUI
import Bolts
import MBProgressHUD
import iOSDFULibrary
 import CoreMotion
 import simd
 

extension String {
    var drop0xPrefix:          String { return hasPrefix("0x") ? String(characters.dropFirst(2)) : self }
}

class DeviceDetailViewController: StaticDataTableViewController, DFUServiceDelegate, DFUProgressDelegate, LoggerDelegate, DFUPeripheralSelectorDelegate {
    var device: MBLMetaWear!
    
    @IBOutlet weak var connectionSwitch: UISwitch!
    @IBOutlet weak var connectionStateLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var setNameButton: UIButton!
    
    @IBOutlet var allCells: [UITableViewCell]!
    
    @IBOutlet var infoAndStateCells: [UITableViewCell]!
/*    @IBOutlet weak var mfgNameLabel: UILabel!
    @IBOutlet weak var serialNumLabel: UILabel!
    @IBOutlet weak var hwRevLabel: UILabel!
    @IBOutlet weak var fwRevLabel: UILabel!
    @IBOutlet weak var modelNumberLabel: UILabel!
    @IBOutlet weak var batteryLevelLabel: UILabel!
    @IBOutlet weak var rssiLevelLabel: UILabel!
    @IBOutlet weak var txPowerSelector: UISegmentedControl!
*/    @IBOutlet weak var firmwareUpdateLabel: UILabel!
    
/*    @IBOutlet weak var mechanicalSwitchCell: UITableViewCell!
    @IBOutlet weak var mechanicalSwitchLabel: UILabel!
    @IBOutlet weak var startSwitch: UIButton!
    @IBOutlet weak var stopSwitch: UIButton!
*/
    @IBOutlet weak var ledCell: UITableViewCell!
    
  /*  @IBOutlet weak var tempCell: UITableViewCell!
    @IBOutlet weak var tempChannelSelector: UISegmentedControl!
    @IBOutlet weak var channelTypeLabel: UILabel!
    @IBOutlet weak var tempratureLabel: UILabel!
    @IBOutlet weak var readPinLabel: UILabel!
    @IBOutlet weak var readPinTextField: UITextField!
    @IBOutlet weak var enablePinLabel: UILabel!
    @IBOutlet weak var enablePinTextField: UITextField!
*/  var temperatureEvent: MBLEvent<MBLNumericData>!
 
 
    @IBOutlet weak var tapDetectionType: UISegmentedControl!

    @IBOutlet weak var accelerometerBMI160Cell: UITableViewCell!
    @IBOutlet weak var accelerometerBMI160Scale: UISegmentedControl!
    @IBOutlet weak var accelerometerBMI160Frequency: UISegmentedControl!
    @IBOutlet weak var accelerometerBMI160StartStream: UIButton!
    @IBOutlet weak var accelerometerBMI160StopStream: UIButton!
    @IBOutlet weak var accelerometerBMI160StartLog: UIButton!
    @IBOutlet weak var accelerometerBMI160StopLog: UIButton!
    @IBOutlet weak var accelerometerBMI160Graph: APLGraphView!
    @IBOutlet weak var accelerometerBMI160TapType: UISegmentedControl!
    @IBOutlet weak var accelerometerBMI160StartTap: UIButton!
    @IBOutlet weak var accelerometerBMI160StopTap: UIButton!
    @IBOutlet weak var accelerometerBMI160TapLabel: UILabel!
    var accelerometerBMI160TapCount = 0
    @IBOutlet weak var accelerometerBMI160StartFlat: UIButton!
    @IBOutlet weak var accelerometerBMI160StopFlat: UIButton!
    @IBOutlet weak var accelerometerBMI160FlatLabel: UILabel!
    @IBOutlet weak var accelerometerBMI160StartOrient: UIButton!
    @IBOutlet weak var accelerometerBMI160StopOrient: UIButton!
    @IBOutlet weak var accelerometerBMI160OrientLabel: UILabel!
    @IBOutlet weak var accelerometerBMI160StartStep: UIButton!
    @IBOutlet weak var accelerometerBMI160StopStep: UIButton!
    @IBOutlet weak var accelerometerBMI160StepLabel: UILabel!
    var accelerometerBMI160StepCount = 0
    var accelerometerBMI160Data = [MBLAccelerometerData]()
    

/*    @IBOutlet weak var gyroBMI160Cell: UITableViewCell!
    @IBOutlet weak var gyroBMI160Scale: UISegmentedControl!
    @IBOutlet weak var gyroBMI160Frequency: UISegmentedControl!
    @IBOutlet weak var gyroBMI160StartStream: UIButton!
    @IBOutlet weak var gyroBMI160StopStream: UIButton!
    @IBOutlet weak var gyroBMI160StartLog: UIButton!
    @IBOutlet weak var gyroBMI160StopLog: UIButton!
*/

    @IBOutlet weak var gpioCell: UITableViewCell!
    @IBOutlet weak var gpioPinSelector: UISegmentedControl!
    @IBOutlet weak var gpioPinChangeType: UISegmentedControl!
    @IBOutlet weak var gpioStartPinChange: UIButton!
    @IBOutlet weak var gpioStopPinChange: UIButton!
    @IBOutlet weak var gpioPinChangeLabel: UILabel!
    var gpioPinChangeCount = 0
    @IBOutlet weak var gpioDigitalValue: UILabel!
    @IBOutlet weak var gpioAnalogAbsoluteButton: UIButton!
    @IBOutlet weak var gpioAnalogAbsoluteValue: UILabel!
    @IBOutlet weak var gpioAnalogRatioButton: UIButton!
    @IBOutlet weak var gpioAnalogRatioValue: UILabel!
    
    @IBOutlet weak var barometerBME280Cell: UITableViewCell!
    @IBOutlet weak var barometerBME280Oversampling: UISegmentedControl!
    @IBOutlet weak var barometerBME280Averaging: UISegmentedControl!
    @IBOutlet weak var barometerBME280Standby: UISegmentedControl!
    @IBOutlet weak var barometerBME280StartStream: UIButton!
    @IBOutlet weak var barometerBME280StopStream: UIButton!
    @IBOutlet weak var barometerBME280Altitude: UILabel!
    
    @IBOutlet weak var ambientLightLTR329Cell: UITableViewCell!
    @IBOutlet weak var ambientLightLTR329Gain: UISegmentedControl!
    @IBOutlet weak var ambientLightLTR329Integration: UISegmentedControl!
    @IBOutlet weak var ambientLightLTR329Measurement: UISegmentedControl!
    @IBOutlet weak var ambientLightLTR329StartStream: UIButton!
    @IBOutlet weak var ambientLightLTR329StopStream: UIButton!
    @IBOutlet weak var ambientLightLTR329Illuminance: UILabel!
    

    @IBOutlet weak var hygrometerBME280Cell: UITableViewCell!
    @IBOutlet weak var hygrometerBME280Oversample: UISegmentedControl!
    @IBOutlet weak var hygrometerBME280StartStream: UIButton!
    @IBOutlet weak var hygrometerBME280StopStream: UIButton!
    @IBOutlet weak var hygrometerBME280Humidity: UILabel!
    var hygrometerBME280Event: MBLEvent<MBLNumericData>!
    
    @IBOutlet weak var i2cCell: UITableViewCell!
    @IBOutlet weak var i2cSizeSelector: UISegmentedControl!
    @IBOutlet weak var i2cDeviceAddress: UITextField!
    @IBOutlet weak var i2cRegisterAddress: UITextField!
    @IBOutlet weak var i2cReadByteLabel: UILabel!
    @IBOutlet weak var i2cWriteByteField: UITextField!
  

    @IBOutlet weak var startMonitoringButton: UIButton!
    @IBOutlet weak var stopMonitoringButton: UIButton!
    
    @IBOutlet weak var AmbientEnvironmentStartStream: UIButton!
    @IBOutlet weak var AmbientEnvironmentStopStream: UIButton!
    @IBOutlet weak var temperatureMeasurement: UILabel!
    @IBOutlet weak var humidityMeasurement: UILabel!
    @IBOutlet weak var lightMeasurement: UILabel!
    
    @IBOutlet weak var accelerometerGraphView: APLGraphView!
    @IBOutlet weak var lightGraphView: APLGraphView!
    @IBOutlet weak var gyroBMI160Graph: APLGraphView!
    var gyroBMI160Data = [MBLGyroData]()
  
    
    
    
    var streamingEvents: Set<NSObject> = [] // Can't use proper type due to compiler seg fault
    var isObserving = false {
        didSet {
            if self.isObserving {
                if !oldValue {
                    self.device.addObserver(self, forKeyPath: "state", options: .new, context: nil)
                }
            } else {
                if oldValue {
                    self.device.removeObserver(self, forKeyPath: "state")
                }
            }
        }
    }
    var hud: MBProgressHUD!
    
    var controller: UIDocumentInteractionController!
    var initiator: DFUServiceInitiator?
    var dfuController: DFUServiceController?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Use this array to keep track of all streaming events, so turn them off
        // in case the user isn't so responsible
        streamingEvents = []
        // Hide every section in the beginning
        hideSectionsWithHiddenRows = true
        cells(self.allCells, setHidden: true)
        reloadData(animated: false)
        // Write in the 2 fields we know at time zero
        connectionStateLabel.text! = nameForState()
        nameTextField.text = self.device.name
        // Listen for state changes
        isObserving = true
        // Start off the connection flow
        connectDevice(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        isObserving = false
        for obj in streamingEvents {
            if let event = obj as? MBLEvent<AnyObject> {
                event.stopNotificationsAsync()
            }
        }
        streamingEvents.removeAll()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        OperationQueue.main.addOperation {
            self.connectionStateLabel.text! = self.nameForState()
            if self.device.state == .disconnected {
                self.deviceDisconnected()
            }
        }
    }
    
    func nameForState() -> String {
        switch device.state {
        case .connected:
            return device.programedByOtherApp ? "Connected (LIMITED)" : "Connected"
        case .connecting:
            return "Connecting"
        case .disconnected:
            return "Disconnected"
        case .disconnecting:
            return "Disconnecting"
        case .discovery:
            return "Discovery"
        }
    }
    
    func logCleanup(_ handler: @escaping MBLErrorHandler) {
        // In order for the device to actaully erase the flash memory we can't be in a connection
        // so temporally disconnect to allow flash to erase.
        isObserving = false
        device.disconnectAsync().continueOnDispatch { t in
            self.isObserving = true
            guard t.error == nil else {
                return t
            }
            return self.device.connect(withTimeoutAsync: 15)
        }.continueOnDispatch { t in
            handler(t.error)
            return nil
        }
    }
    
    func showAlertTitle(_ title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func deviceDisconnected() {
        connectionSwitch.setOn(false, animated: true)
        cells(self.allCells, setHidden: true)
        reloadData(animated: true)
    }
    
    func deviceConnected() {
        connectionSwitch.setOn(true, animated: true)
        // Perform all device specific setup
        if let mac = device.settings?.macAddress {
            mac.readAsync().success { result in
                print("ID: \(self.device.identifier.uuidString) MAC: \(result.value)")
            }
        } else {
            print("ID: \(device.identifier.uuidString)")
        }
        // We always have the info and state features
       /* cells(self.infoAndStateCells, setHidden: false)
        mfgNameLabel.text = device.deviceInfo?.manufacturerName ?? "N/A"
        serialNumLabel.text = device.deviceInfo?.serialNumber ?? "N/A"
        hwRevLabel.text = device.deviceInfo?.hardwareRevision ?? "N/A"
        fwRevLabel.text = device.deviceInfo?.firmwareRevision ?? "N/A"
        modelNumberLabel.text = "\(device.deviceInfo?.modelNumber ?? "N/A") (\(MBLModelString(device.model)))"
        txPowerSelector.selectedSegmentIndex = Int(device.settings!.transmitPower.rawValue)
        // Automaticaly send off some reads
        device.readBatteryLifeAsync().success { result in
            self.batteryLevelLabel.text = result.stringValue
        }
        device.readRSSIAsync().success { result in
            self.rssiLevelLabel.text = result.stringValue
        }
        device.checkForFirmwareUpdateAsync().success { result in
            self.firmwareUpdateLabel.text = result.boolValue ? "AVAILABLE!" : "Up To Date"
        }
        */
        if device.led != nil {
            cell(ledCell, setHidden: false)
        }
        
        // Only allow LED module if the device is in use by other app
        if device.programedByOtherApp {
            if UserDefaults.standard.object(forKey: "ihaveseenprogramedByOtherAppmessage") == nil {
                UserDefaults.standard.set(1, forKey: "ihaveseenprogramedByOtherAppmessage")
                UserDefaults.standard.synchronize()
                self.showAlertTitle("WARNING", message: "You have connected to a device being used by another app.  To prevent errors and data loss for the other application we are only showing a limited number of features.  If you wish to take control please press 'Reset To Factory Defaults', which will wipe the device clean.")
            }
            reloadData(animated: true)
            return
        }
        
        // Go through each module and enable the correct cell for the modules on this particular MetaWear
  /*      if device.mechanicalSwitch != nil {
            cell(mechanicalSwitchCell, setHidden: false)
        }
   */
/*      if device.temperature != nil {
            cell(tempCell, setHidden: false)
            // The number of channels is variable
            tempChannelSelector.removeAllSegments()
            for i in 0..<device.temperature!.channels.count {
                tempChannelSelector.insertSegment(withTitle: "\(i)", at: i, animated: false)
            }
            tempChannelSelector.selectedSegmentIndex = 0
            tempChannelSelectorPressed(tempChannelSelector)
        }
*/
   /*     if (device.accelerometer is MBLAccelerometerBMI160) {
            cell(accelerometerBMI160Cell, setHidden: false)
            if device.accelerometer!.dataReadyEvent.isLogging() {
                accelerometerBMI160StartLog.isEnabled = false
                accelerometerBMI160StopLog.isEnabled = true
                accelerometerBMI160StartStream.isEnabled = false
                accelerometerBMI160StopStream.isEnabled = false
            } else {
                accelerometerBMI160StartLog.isEnabled = true
                accelerometerBMI160StopLog.isEnabled = false
                accelerometerBMI160StartStream.isEnabled = true
                accelerometerBMI160StopStream.isEnabled = false
            }
        }
    */
   /*     if device.gyro is MBLGyroBMI160 {
            cell(gyroBMI160Cell, setHidden: false)
            if device.gyro!.dataReadyEvent.isLogging() {
                gyroBMI160StartLog.isEnabled = false
                gyroBMI160StopLog.isEnabled = true
                gyroBMI160StartStream.isEnabled = false
                gyroBMI160StopStream.isEnabled = false
           }
            else {
                gyroBMI160StartLog.isEnabled = true
                gyroBMI160StopLog.isEnabled = false
                gyroBMI160StartStream.isEnabled = true
                gyroBMI160StopStream.isEnabled = false
            }
        }
    */
     /*   if device.gpio != nil {
            if device.gpio!.pins.count > 0 {
                cell(gpioCell, setHidden: false)
                // The number of pins is variable
                gpioPinSelector.removeAllSegments()
                for i in 0..<device.gpio!.pins.count {
                    gpioPinSelector.insertSegment(withTitle: "\(i)", at: i, animated: false)
                }
                gpioPinSelector.selectedSegmentIndex = 0
            }
        }
  */
   /*     if device.barometer is MBLBarometerBME280 {
            cell(barometerBME280Cell, setHidden: false)
        }
        
        if device.ambientLight is MBLAmbientLightLTR329 {
            cell(ambientLightLTR329Cell, setHidden: false)
        }
        
        if device.hygrometer is MBLHygrometerBME280 {
            cell(hygrometerBME280Cell, setHidden: false)
        }
        
        if device.serial != nil {
            cell(i2cCell, setHidden: false)
        }
        
*/
        
        // Make the magic happen!
        reloadData(animated: true)
    }
    
    func connectDevice(_ on: Bool) {
        let hud = MBProgressHUD.showAdded(to: UIApplication.shared.keyWindow!, animated: true)
        if on {
            hud.label.text = "Connecting..."
            device.connect(withTimeoutAsync: 15).continueOnDispatch { t in
                if (t.error?._domain == kMBLErrorDomain) && (t.error?._code == kMBLErrorOutdatedFirmware) {
                    hud.hide(animated: true)
                    self.firmwareUpdateLabel.text! = "Force Update"
                    self.updateFirmware(self.setNameButton)
                    return nil
                }
                hud.mode = .text
                if t.error != nil {
                    self.showAlertTitle("Error", message: t.error!.localizedDescription)
                    hud.hide(animated: false)
                } else {
                    self.deviceConnected()
                    
                    hud.label.text! = "Connected!"
                    hud.hide(animated: true, afterDelay: 0.5)
                }
                return nil
            }
        } else {
            hud.label.text = "Disconnecting..."
            device.disconnectAsync().continueOnDispatch { t in
                self.deviceDisconnected()
                hud.mode = .text
                if t.error != nil {
                    self.showAlertTitle("Error", message: t.error!.localizedDescription)
                    hud.hide(animated: false)
                }
                else {
                    hud.label.text = "Disconnected!"
                    hud.hide(animated: true, afterDelay: 0.5)
                }
                return nil
            }
        }
    }
    
    @IBAction func connectionSwitchPressed(_ sender: Any) {
        connectDevice(connectionSwitch.isOn)
    }
    
    @IBAction func setNamePressed(_ sender: Any) {
        if UserDefaults.standard.object(forKey: "ihaveseennamemessage") == nil {
            UserDefaults.standard.set(1, forKey: "ihaveseennamemessage")
            UserDefaults.standard.synchronize()
            showAlertTitle("Notice", message: "Because of how iOS caches names, you have to disconnect and re-connect a few times or force close and re-launch the app before you see the new name!")
        }
        nameTextField.resignFirstResponder()
        device.name = nameTextField.text!
        setNameButton.isEnabled = false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // return NO to not change text
        self.setNameButton.isEnabled = true
        // Prevent Undo crashing bug
        if range.length + range.location > textField.text!.characters.count {
            return false
        }
        // Make sure it's no longer than 8 characters
        let newLength = textField.text!.characters.count + string.characters.count - range.length
        if newLength > 8 {
            return false
        }
        // Make sure we only use ASCII characters
        return string.data(using: String.Encoding.ascii) != nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // called when 'return' key pressed. return NO to ignore.
        textField.resignFirstResponder()
        return true
    }
    
/*    @IBAction func readBatteryPressed(_ sender: Any) {
        device.readBatteryLifeAsync().success { result in
            self.batteryLevelLabel.text = result.stringValue
        }.failure { error in
            self.showAlertTitle("Error", message: error.localizedDescription)
        }
    }
*/
/*    @IBAction func readRSSIPressed(_ sender: Any) {
        device.readRSSIAsync().success { result in
            self.rssiLevelLabel.text = result.stringValue
        }.failure { error in
            self.showAlertTitle("Error", message: error.localizedDescription)
        }
    }
*/
/*    @IBAction func txPowerChanged(_ sender: Any) {
        device.settings?.transmitPower = MBLTransmitPower(rawValue: UInt8(txPowerSelector.selectedSegmentIndex))!
    }
*/
    @IBAction func checkForFirmwareUpdatesPressed(_ sender: Any) {
        device.checkForFirmwareUpdateAsync().success { result in
            self.firmwareUpdateLabel.text = result.boolValue ? "AVAILABLE!" : "Up To Date"
        }.failure { error in
            self.showAlertTitle("Error", message: error.localizedDescription)
        }
    }
    
    @IBAction func updateFirmware(_ sender: Any) {
        // Pause the screen while update is going on
        hud = MBProgressHUD.showAdded(to: UIApplication.shared.keyWindow!, animated: true)
        hud.mode = .determinateHorizontalBar
        hud.label.text = "Updating..."
        device.prepareForFirmwareUpdateAsync().success { result in
            var selectedFirmware: DFUFirmware?
            if result.firmwareUrl.pathExtension.caseInsensitiveCompare("zip") == .orderedSame {
                selectedFirmware = DFUFirmware(urlToZipFile: result.firmwareUrl)
            } else {
                selectedFirmware = DFUFirmware(urlToBinOrHexFile: result.firmwareUrl, urlToDatFile: nil, type: .application)
            }
            self.initiator = DFUServiceInitiator(centralManager: result.centralManager, target: result.target)
            let _ = self.initiator?.with(firmware: selectedFirmware!)
            self.initiator?.forceDfu = true // We also have the DIS which confuses the DFU library
            self.initiator?.logger = self // - to get log info
            self.initiator?.delegate = self // - to be informed about current state and errors
            self.initiator?.peripheralSelector = self
            self.initiator?.progressDelegate = self // - to show progress bar
            
            self.dfuController = self.initiator?.start()
        }.failure { error in
            print("Firmware update error: \(error.localizedDescription)")
            UIAlertView(title: "Update Error", message: "Please re-connect and try again, if you can't connect, try MetaBoot Mode to recover.\nError: ".appending(error.localizedDescription), delegate: nil, cancelButtonTitle: "Okay", otherButtonTitles: "").show()
            self.hud.hide(animated: true)
        }
    }
    
    @IBAction func resetDevicePressed(_ sender: Any) {
        // Resetting causes a disconnection
        deviceDisconnected()
        // Preform the soft reset
        device.resetDevice()
    }
    
    @IBAction func factoryDefaultsPressed(_ sender: Any) {
        // Resetting causes a disconnection
        deviceDisconnected()
        // In case any pairing information is on the device mark it for removal too
        device.settings?.deleteAllBondsAsync()
        // Setting a nil configuration removes state perisited in flash memory
        device.setConfigurationAsync(nil)
    }
    
/*    @IBAction func readSwitchPressed(_ sender: Any) {
        device.mechanicalSwitch?.switchValue.readAsync().success { result in
            self.mechanicalSwitchLabel.text = result.value.boolValue ? "Down" : "Up"
        }
    }
*/
/*    @IBAction func startSwitchNotifyPressed(_ sender: Any) {
        startSwitch.isEnabled = false
        stopSwitch.isEnabled = true
        streamingEvents.insert(device.mechanicalSwitch!.switchUpdateEvent)
        device.mechanicalSwitch!.switchUpdateEvent.startNotificationsAsync { (obj, error) in
            if let obj = obj {
                self.mechanicalSwitchLabel.text = obj.value.boolValue ? "Down" : "Up"
            }
        }
    }
*/
/*    @IBAction func stopSwitchNotifyPressed(_ sender: Any) {
        startSwitch.isEnabled = true
        stopSwitch.isEnabled = false
        streamingEvents.remove(device.mechanicalSwitch!.switchUpdateEvent)
        device.mechanicalSwitch!.switchUpdateEvent.stopNotificationsAsync()
    }
*/
    // *************  Data Transfer  *************
    
    func send(_ data: Data, title: String) {
        // Get current Time/Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM_dd_yyyy-HH_mm_ss"
        let dateString = dateFormatter.string(from: Date())
        let name = "\(title)_\(dateString).csv"
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
        do {
            try data.write(to: fileURL, options: .atomic)
            // Popup the default share screen
            self.controller = UIDocumentInteractionController(url: fileURL)
            if !self.controller.presentOptionsMenu(from: view.bounds, in: view, animated: true) {
                self.showAlertTitle("Error", message: "No programs installed that could save the file")
            }
        } catch let error {
            self.showAlertTitle("Error", message: error.localizedDescription)
        }
    }
    
   
    // *************  LED's  *************
   
    @IBAction func turn(onCyanLEDPressed sender: UIButton) {
        device.led?.setLEDColorAsync(UIColor.cyan, withIntensity: 1.0)
    }
    
    @IBAction func flashWhiteLEDPressed(_ sender: Any) {
        device.led?.flashColorAsync(UIColor.white, withIntensity: 1.0)
    }
    
    @IBAction func turnOffLEDPressed(_ sender: Any) {
        device.led?.setLEDOnAsync(false, withOptions: 1)
    }
    
    
    // *************  Temperature  *************
    
 /*   @IBAction func tempChannelSelectorPressed(_ sender: Any) {
        let selected = device.temperature!.channels[tempChannelSelector.selectedSegmentIndex]
        if selected == device.temperature!.onDieThermistor {
            channelTypeLabel.text = "On-Die"
        } else if selected == device.temperature!.onboardThermistor {
            channelTypeLabel.text = "On-Board"
        } else if selected == device.temperature!.externalThermistor {
            channelTypeLabel.text = "External"
        } else {
            channelTypeLabel.text = "Custom"
        }
        
        if selected is MBLExternalThermistor {
            self.readPinLabel.isHidden = false
            self.readPinTextField.isHidden = false
            self.enablePinLabel.isHidden = false
            self.enablePinTextField.isHidden = false
        } else {
            self.readPinLabel.isHidden = true
            self.readPinTextField.isHidden = true
            self.enablePinLabel.isHidden = true
            self.enablePinTextField.isHidden = true
        }
    }
    
    @IBAction func readTempraturePressed(_ sender: Any) {
        let selected = device.temperature!.channels[tempChannelSelector.selectedSegmentIndex]
        if let selected = selected as? MBLExternalThermistor {
            selected.readPin = UInt8(readPinTextField.text!) ?? 0
            selected.enablePin = UInt8(enablePinTextField.text!) ?? 0
        }
        selected.readAsync().success { result in
            self.tempratureLabel.text = result.value.stringValue.appending("°C")
        }
    }
  */
    
    // *************  Accelerometer  *************
 
    func updateAccelerometerBMI160Settings() {
        let accelerometerBMI160 = self.device.accelerometer as! MBLAccelerometerBMI160
    
        
        accelerometerBMI160.fullScaleRange = .range2G
        self.accelerometerGraphView.fullScale = 2
        
     /*   switch self.accelerometerBMI160Scale.selectedSegmentIndex {
        case 0:
            accelerometerBMI160.fullScaleRange = .range2G
            self.accelerometerBMI160Graph.fullScale = 2
        case 1:
            accelerometerBMI160.fullScaleRange = .range4G
            self.accelerometerBMI160Graph.fullScale = 4
        case 2:
            accelerometerBMI160.fullScaleRange = .range8G
            self.accelerometerBMI160Graph.fullScale = 8
        case 3:
            accelerometerBMI160.fullScaleRange = .range16G
            self.accelerometerBMI160Graph.fullScale = 16
        default:
            print("Unexpected accelerometerBMI160Scale value")
        }
     */
        
        accelerometerBMI160.sampleFrequency = Double(self.accelerometerBMI160Frequency.titleForSegment(at: self.accelerometerBMI160Frequency.selectedSegmentIndex)!)!
        accelerometerBMI160.tapEvent.type = MBLAccelerometerTapType(rawValue: UInt8(tapDetectionType.selectedSegmentIndex))!
    }
    
/*    @IBAction func accelerometerBMI160StartStreamPressed(_ sender: Any) {
        accelerometerBMI160StartStream.isEnabled = false
        accelerometerBMI160StopStream.isEnabled = true
        accelerometerBMI160StartLog.isEnabled = false
        accelerometerBMI160StopLog.isEnabled = false
        updateAccelerometerBMI160Settings()
        var array = [MBLAccelerometerData]() /* capacity: 1000 */
        accelerometerBMI160Data = array
        streamingEvents.insert(device.accelerometer!.dataReadyEvent)
        device.accelerometer!.dataReadyEvent.startNotificationsAsync { (obj, error) in
            if let obj = obj {
                self.accelerometerBMI160Graph.addX(obj.x, y: obj.y, z: obj.z)
                array.append(obj)
            }
        }
    }
    
    @IBAction func accelerometerBMI160StopStreamPressed(_ sender: Any) {
        accelerometerBMI160StartStream.isEnabled = true
        accelerometerBMI160StopStream.isEnabled = false
        accelerometerBMI160StartLog.isEnabled = true
        streamingEvents.remove(device.accelerometer!.dataReadyEvent)
        device.accelerometer!.dataReadyEvent.stopNotificationsAsync()
    }
    
    @IBAction func accelerometerBMI160StartLogPressed(_ sender: Any) {
        accelerometerBMI160StartLog.isEnabled = false
        accelerometerBMI160StopLog.isEnabled = true
        accelerometerBMI160StartStream.isEnabled = false
        accelerometerBMI160StopStream.isEnabled = false
        updateAccelerometerBMI160Settings()
        device.accelerometer!.dataReadyEvent.startLoggingAsync()
    }
    
    @IBAction func accelerometerBMI160StopLogPressed(_ sender: Any) {
        accelerometerBMI160StartLog.isEnabled = true
        accelerometerBMI160StopLog.isEnabled = false
        accelerometerBMI160StartStream.isEnabled = true
        let hud = MBProgressHUD.showAdded(to: UIApplication.shared.keyWindow!, animated: true)
        hud.mode = .determinateHorizontalBar
        hud.label.text = "Downloading..."
        device.accelerometer!.dataReadyEvent.downloadLogAndStopLoggingAsync(true) { number in
            hud.progress = number
        }.success { array in
            self.accelerometerBMI160Data = array as! [MBLAccelerometerData]
            for obj in self.accelerometerBMI160Data {
                self.accelerometerBMI160Graph.addX(obj.x, y: obj.y, z: obj.z)
            }
            hud.mode = .indeterminate
            hud.label.text = "Clearing Log..."
            self.logCleanup { error in
                hud.hide(animated: true)
                if error != nil {
                    self.connectDevice(false)
                }
            }
        }.failure { error in
            self.connectDevice(false)
            hud.hide(animated: true)
        }
    }
    
    @IBAction func accelerometerBMI160EmailDataPressed(_ sender: Any) {
        var accelerometerData = Data()
        for dataElement in accelerometerBMI160Data {
            accelerometerData.append("\(dataElement.timestamp.timeIntervalSince1970),\(dataElement.x),\(dataElement.y),\(dataElement.z)\n".data(using: String.Encoding.utf8)!)
        }
        send(accelerometerData, title: "AccData")
    }
    
    @IBAction func accelerometerBMI160StartTapPressed(_ sender: Any) {
        accelerometerBMI160StartTap.isEnabled = false
        accelerometerBMI160StopTap.isEnabled = true
        updateAccelerometerBMI160Settings()
        let accelerometerBMI160 = self.device.accelerometer as! MBLAccelerometerBMI160
        streamingEvents.insert(accelerometerBMI160.tapEvent)
        accelerometerBMI160.tapEvent.startNotificationsAsync { (obj, error) in
            if obj != nil {
                self.accelerometerBMI160TapCount += 1
                self.accelerometerBMI160TapLabel.text = "Tap Count: \(self.accelerometerBMI160TapCount)"
            }
        }
    }
    
    @IBAction func accelerometerBMI160StopTapPressed(_ sender: Any) {
        accelerometerBMI160StartTap.isEnabled = true
        accelerometerBMI160StopTap.isEnabled = false
        let accelerometerBMI160 = self.device.accelerometer as! MBLAccelerometerBMI160
        streamingEvents.remove(accelerometerBMI160.tapEvent)
        accelerometerBMI160.tapEvent.stopNotificationsAsync()
        self.accelerometerBMI160TapCount = 0
        self.accelerometerBMI160TapLabel.text = "Tap Count: 0"
    }
    
    @IBAction func accelerometerBMI160StartFlatPressed(_ sender: Any) {
        accelerometerBMI160StartFlat.isEnabled = false
        accelerometerBMI160StopFlat.isEnabled = true
        updateAccelerometerBMI160Settings()
        let accelerometerBMI160 = self.device.accelerometer as! MBLAccelerometerBMI160
        streamingEvents.insert(accelerometerBMI160.flatEvent)
        accelerometerBMI160.flatEvent.startNotificationsAsync { (obj, error) in
            if let obj = obj {
                self.accelerometerBMI160FlatLabel.text = obj.isFlat ? "Flat" : "Not Flat"
            }
        }
    }
    
    @IBAction func accelerometerBMI160StopFlatPressed(_ sender: Any) {
        accelerometerBMI160StartFlat.isEnabled = true
        accelerometerBMI160StopFlat.isEnabled = false
        let accelerometerBMI160 = self.device.accelerometer as! MBLAccelerometerBMI160
        streamingEvents.remove(accelerometerBMI160.flatEvent)
        accelerometerBMI160.flatEvent.stopNotificationsAsync()
        accelerometerBMI160FlatLabel.text = "XXXXXXX"
    }
    
    @IBAction func accelerometerBMI160StartOrientPressed(_ sender: Any) {
        accelerometerBMI160StartOrient.isEnabled = false
        accelerometerBMI160StopOrient.isEnabled = true
        updateAccelerometerBMI160Settings()
        let accelerometerBMI160 = self.device.accelerometer as! MBLAccelerometerBMI160
        streamingEvents.insert(accelerometerBMI160.orientationEvent)
        accelerometerBMI160.orientationEvent.startNotificationsAsync { (obj, error) in
            if let obj = obj {
                switch obj.orientation {
                case .portrait:
                    self.accelerometerBMI160OrientLabel.text = "Portrait"
                case .portraitUpsideDown:
                    self.accelerometerBMI160OrientLabel.text = "PortraitUpsideDown"
                case .landscapeLeft:
                    self.accelerometerBMI160OrientLabel.text = "LandscapeLeft"
                case .landscapeRight:
                    self.accelerometerBMI160OrientLabel.text = "LandscapeRight"
                }
            }
        }
    }
    
    @IBAction func accelerometerBMI160StopOrientPressed(_ sender: Any) {
        accelerometerBMI160StartOrient.isEnabled = true
        accelerometerBMI160StopOrient.isEnabled = false
        let accelerometerBMI160 = self.device.accelerometer as! MBLAccelerometerBMI160
        streamingEvents.remove(accelerometerBMI160.orientationEvent)
        accelerometerBMI160.orientationEvent.stopNotificationsAsync()
        accelerometerBMI160OrientLabel.text = "XXXXXXXXXXXXXX"
    }
    
    @IBAction func accelerometerBMI160StartStepPressed(_ sender: Any) {
        accelerometerBMI160StartStep.isEnabled = false
        accelerometerBMI160StopStep.isEnabled = true
        updateAccelerometerBMI160Settings()
        let accelerometerBMI160 = self.device.accelerometer as! MBLAccelerometerBMI160
        streamingEvents.insert(accelerometerBMI160.stepEvent)
        accelerometerBMI160.stepEvent.startNotificationsAsync { (obj, error) in
            if obj != nil {
                self.accelerometerBMI160StepCount += 1
                self.accelerometerBMI160StepLabel.text = "Step Count: \(self.accelerometerBMI160StepCount)"
            }
        }
    }
    
    @IBAction func accelerometerBMI160StopStepPressed(_ sender: Any) {
        accelerometerBMI160StartStep.isEnabled = true
        accelerometerBMI160StopStep.isEnabled = false
        let accelerometerBMI160 = self.device.accelerometer as! MBLAccelerometerBMI160
        streamingEvents.remove(accelerometerBMI160.stepEvent)
        accelerometerBMI160.stepEvent.stopNotificationsAsync()
        accelerometerBMI160StepCount = 0
        accelerometerBMI160StepLabel.text = "Step Count: 0"
    }
    
*/
    // *************  Gyroscope  *************
    
    
    func updateGyroBMI160Settings() {
        
        
        let gyroBMI160 = self.device.gyro as! MBLGyroBMI160
        gyroBMI160.fullScaleRange = .range500
        self.gyroBMI160Graph.fullScale = 4
        
  /*      let gyroBMI160 = self.device.gyro as! MBLGyroBMI160
      /*  switch self.gyroBMI160Scale.selectedSegmentIndex {
        case 0:
            gyroBMI160.fullScaleRange = .range125
            self.gyroBMI160Graph.fullScale = 1
        case 1:
      */      gyroBMI160.fullScaleRange = .range250
            self.gyroBMI160Graph.fullScale = 2
       /* case 2:
            gyroBMI160.fullScaleRange = .range500
            self.gyroBMI160Graph.fullScale = 4
        case 3:
            gyroBMI160.fullScaleRange = .range1000
            self.gyroBMI160Graph.fullScale = 8
        case 4:
            gyroBMI160.fullScaleRange = .range2000
            self.gyroBMI160Graph.fullScale = 16
        default:
            print("Unexpected gyroBMI160Scale value")
        }
        */
        gyroBMI160.sampleFrequency = Double(self.gyroBMI160Frequency.titleForSegment(at: self.gyroBMI160Frequency.selectedSegmentIndex)!)!
  */
  }
    
 /*   @IBAction func gyroBMI160StartStreamPressed(_ sender: Any) {
        gyroBMI160StartStream.isEnabled = false
        gyroBMI160StopStream.isEnabled = true
        gyroBMI160StartLog.isEnabled = false
        gyroBMI160StopLog.isEnabled = false
        updateGyroBMI160Settings()
        var array = [MBLGyroData]() /* capacity: 1000 */
        gyroBMI160Data = array
        streamingEvents.insert(device.gyro!.dataReadyEvent)
        device.gyro!.dataReadyEvent.startNotificationsAsync { (obj, error) in
            if let obj = obj {
                // TODO: Come up with a better graph interface, we need to scale value
                // to show up right
                self.gyroBMI160Graph.addX(obj.x * 0.008, y: obj.y * 0.008, z: obj.z * 0.008)
                array.append(obj)
            }
        }
    }
    
    @IBAction func gyroBMI160StopStreamPressed(_ sender: Any) {
        gyroBMI160StartStream.isEnabled = true
        gyroBMI160StopStream.isEnabled = false
        gyroBMI160StartLog.isEnabled = true
        streamingEvents.remove(device.gyro!.dataReadyEvent)
        device.gyro!.dataReadyEvent.stopNotificationsAsync()
    }
    
    @IBAction func gyroBMI160StartLogPressed(_ sender: Any) {
        gyroBMI160StartLog.isEnabled = false
        gyroBMI160StopLog.isEnabled = true
        gyroBMI160StartStream.isEnabled = false
        gyroBMI160StopStream.isEnabled = false
        updateGyroBMI160Settings()
        device.gyro!.dataReadyEvent.startLoggingAsync()
    }
    
    @IBAction func gyroBMI160StopLogPressed(_ sender: Any) {
        gyroBMI160StartLog.isEnabled = true
        gyroBMI160StopLog.isEnabled = false
        gyroBMI160StartStream.isEnabled = true
        let hud = MBProgressHUD.showAdded(to: UIApplication.shared.keyWindow!, animated: true)
        hud.mode = .determinateHorizontalBar
        hud.label.text = "Downloading..."
        device.gyro!.dataReadyEvent.downloadLogAndStopLoggingAsync(true) { number in
            hud.progress = number
        }.success { array in
            self.gyroBMI160Data = array as! [MBLGyroData]
            for obj in self.gyroBMI160Data {
                self.gyroBMI160Graph.addX(obj.x * 0.008, y: obj.y * 0.008, z: obj.z * 0.008)
            }
            hud.mode = .indeterminate
            hud.label.text = "Clearing Log..."
            self.logCleanup { error in
                hud.hide(animated: true)
                if error != nil {
                    self.connectDevice(false)
                }
            }
        }.failure { error in
            self.connectDevice(false)
            hud.hide(animated: true)
        }
    }
    
    @IBAction func gyroBMI160EmailDataPressed(_ sender: Any) {
        var gyroData = Data()
        for dataElement in self.gyroBMI160Data {
            gyroData.append("\(dataElement.timestamp.timeIntervalSince1970),\(dataElement.x),\(dataElement.y),\(dataElement.z)\n".data(using: String.Encoding.utf8)!)
        }
        self.send(gyroData, title: "GyroData")
    }
*/
    
  // *************  GPIO  *************
   
/*    @IBAction func gpioPinSelectorPressed(_ sender: Any) {
        let pin = device.gpio!.pins[gpioPinSelector.selectedSegmentIndex]
        if pin.analogAbsolute != nil {
            self.gpioAnalogAbsoluteButton.isHidden = false
            self.gpioAnalogAbsoluteValue.isHidden = false
        } else {
            self.gpioAnalogAbsoluteButton.isHidden = true
            self.gpioAnalogAbsoluteValue.isHidden = true
        }
        if pin.analogRatio != nil {
            self.gpioAnalogRatioButton.isHidden = false
            self.gpioAnalogRatioValue.isHidden = false
        } else {
            self.gpioAnalogRatioButton.isHidden = true
            self.gpioAnalogRatioValue.isHidden = true
        }
    }
    
    @IBAction func setPullUpPressed(_ sender: Any) {
        let pin = device.gpio!.pins[gpioPinSelector.selectedSegmentIndex]
        pin.setConfiguration(.pullup)
    }
    
    @IBAction func setPullDownPressed(_ sender: Any) {
        let pin = device.gpio!.pins[gpioPinSelector.selectedSegmentIndex]
        pin.setConfiguration(.pulldown)
    }
    
    @IBAction func setNoPullPressed(_ sender: Any) {
        let pin = device.gpio!.pins[gpioPinSelector.selectedSegmentIndex]
        pin.setConfiguration(.nopull)
    }
    
    @IBAction func setPinPressed(_ sender: Any) {
        let pin = device.gpio!.pins[gpioPinSelector.selectedSegmentIndex]
        pin.setToDigitalValueAsync(true)
    }
    
    @IBAction func clearPinPressed(_ sender: Any) {
        let pin = device.gpio!.pins[gpioPinSelector.selectedSegmentIndex]
        pin.setToDigitalValueAsync(false)
    }
    
    @IBAction func gpioStartPinChangePressed(_ sender: Any) {
        gpioStartPinChange.isEnabled = false
        gpioStopPinChange.isEnabled = true
        let pin = device.gpio!.pins[gpioPinSelector.selectedSegmentIndex]
        if gpioPinChangeType.selectedSegmentIndex == 0 {
            pin.changeType = .rising
        } else if gpioPinChangeType.selectedSegmentIndex == 1 {
            pin.changeType = .falling
        } else {
            pin.changeType = .any
        }
        
        streamingEvents.insert(pin.changeEvent!)
        pin.changeEvent?.startNotificationsAsync { (obj, error) in
            if obj != nil {
                self.gpioPinChangeCount += 1
                self.gpioPinChangeLabel.text = "Change Count: \(self.gpioPinChangeCount)"
            }
        }
    }
    
    @IBAction func gpioStopPinChangePressed(_ sender: Any) {
        gpioStartPinChange.isEnabled = true
        gpioStopPinChange.isEnabled = false
        let pin = device.gpio!.pins[gpioPinSelector.selectedSegmentIndex]
        streamingEvents.remove(pin.changeEvent!)
        pin.changeEvent!.stopNotificationsAsync()
        gpioPinChangeCount = 0
        gpioPinChangeLabel.text = "Change Count: 0"
    }
    
    @IBAction func readDigitalPressed(_ sender: Any) {
        let pin = device.gpio!.pins[gpioPinSelector.selectedSegmentIndex]
        pin.digitalValue!.readAsync().success { result in
            self.gpioDigitalValue.text = result.value.boolValue ? "1" : "0"
        }
    }
    
    @IBAction func readAnalogAbsolutePressed(_ sender: Any) {
        let pin = device.gpio!.pins[gpioPinSelector.selectedSegmentIndex]
        pin.analogAbsolute!.readAsync().success { result in
            self.gpioAnalogAbsoluteValue.text = String(format: "%.3fV", result.value.doubleValue)
        }
    }
    
    @IBAction func readAnalogRatioPressed(_ sender: Any) {
        let pin = device.gpio!.pins[gpioPinSelector.selectedSegmentIndex]
        pin.analogRatio!.readAsync().success { result in
            self.gpioAnalogRatioValue.text = String(format: "%.3f", result.value.doubleValue)
        }
    }
    
 */
    
    // *************  Barometer  *************
    
/*   @IBAction func barometerBME280StartStreamPressed(_ sender: Any) {
        barometerBME280StartStream.isEnabled = false
        barometerBME280StopStream.isEnabled = true
        let barometerBME280 = device.barometer as! MBLBarometerBME280
        if barometerBME280Oversampling.selectedSegmentIndex == 0 {
            barometerBME280.pressureOversampling = .ultraLowPower
        } else if barometerBME280Oversampling.selectedSegmentIndex == 1 {
            barometerBME280.pressureOversampling = .lowPower
        } else if barometerBME280Oversampling.selectedSegmentIndex == 2 {
            barometerBME280.pressureOversampling = .standard
        } else if barometerBME280Oversampling.selectedSegmentIndex == 3 {
            barometerBME280.pressureOversampling = .highResolution
        } else {
            barometerBME280.pressureOversampling = .ultraHighResolution
        }
        
        if barometerBME280Averaging.selectedSegmentIndex == 0 {
            barometerBME280.hardwareAverageFilter = .off
        } else if barometerBME280Averaging.selectedSegmentIndex == 1 {
            barometerBME280.hardwareAverageFilter = .average2
        } else if barometerBME280Averaging.selectedSegmentIndex == 2 {
            barometerBME280.hardwareAverageFilter = .average4
        } else if barometerBME280Averaging.selectedSegmentIndex == 3 {
            barometerBME280.hardwareAverageFilter = .average8
        } else {
            barometerBME280.hardwareAverageFilter = .average16
        }
        
        if barometerBME280Standby.selectedSegmentIndex == 0 {
            barometerBME280.standbyTime = .standby0_5
        } else if barometerBME280Standby.selectedSegmentIndex == 1 {
            barometerBME280.standbyTime = .standby10
        } else if barometerBME280Standby.selectedSegmentIndex == 2 {
            barometerBME280.standbyTime = .standby20
        } else if barometerBME280Standby.selectedSegmentIndex == 3 {
            barometerBME280.standbyTime = .standby62_5
        } else if barometerBME280Standby.selectedSegmentIndex == 4 {
            barometerBME280.standbyTime = .standby125
        } else if barometerBME280Standby.selectedSegmentIndex == 5 {
            barometerBME280.standbyTime = .standby250
        } else if barometerBME280Standby.selectedSegmentIndex == 6 {
            barometerBME280.standbyTime = .standby500
        } else {
            barometerBME280.standbyTime = .standby1000
        }
        
        streamingEvents.insert(barometerBME280.periodicAltitude)
        barometerBME280.periodicAltitude.startNotificationsAsync { (obj, error) in
            if let obj = obj {
                self.barometerBME280Altitude.text = String(format: "%.3f", obj.value.doubleValue)
            }
        }
    }
    
    @IBAction func barometerBME280StopStreamPressed(_ sender: Any) {
        barometerBME280StartStream.isEnabled = true
        barometerBME280StopStream.isEnabled = false
        let barometerBME280 = device.barometer as! MBLBarometerBME280
        streamingEvents.remove(barometerBME280.periodicAltitude)
        barometerBME280.periodicAltitude.stopNotificationsAsync()
        barometerBME280Altitude.text = "X.XXX"
    }
    
*/
    
    // *************  Ambient Light  *************
    
/*    @IBAction func ambientLightLTR329StartStreamPressed(_ sender: Any) {
        ambientLightLTR329StartStream.isEnabled = false
        ambientLightLTR329StopStream.isEnabled = true
        let ambientLightLTR329 = device.ambientLight as! MBLAmbientLightLTR329
        switch ambientLightLTR329Gain.selectedSegmentIndex {
        case 0:
            ambientLightLTR329.gain = .gain1X
        case 1:
            ambientLightLTR329.gain = .gain2X
        case 2:
            ambientLightLTR329.gain = .gain4X
        case 3:
            ambientLightLTR329.gain = .gain8X
        case 4:
            ambientLightLTR329.gain = .gain48X
        default:
            ambientLightLTR329.gain = .gain96X
        }
        
        switch ambientLightLTR329Integration.selectedSegmentIndex {
        case 0:
            ambientLightLTR329.integrationTime = .integration50ms
        case 1:
            ambientLightLTR329.integrationTime = .integration100ms
        case 2:
            ambientLightLTR329.integrationTime = .integration150ms
        case 3:
            ambientLightLTR329.integrationTime = .integration200ms
        case 4:
            ambientLightLTR329.integrationTime = .integration250ms
        case 5:
            ambientLightLTR329.integrationTime = .integration300ms
        case 6:
            ambientLightLTR329.integrationTime = .integration350ms
        default:
            ambientLightLTR329.integrationTime = .integration400ms
        }
        
        switch ambientLightLTR329Measurement.selectedSegmentIndex {
        case 0:
            ambientLightLTR329.measurementRate = .rate50ms
        case 1:
            ambientLightLTR329.measurementRate = .rate100ms
        case 2:
            ambientLightLTR329.measurementRate = .rate200ms
        case 3:
            ambientLightLTR329.measurementRate = .rate500ms
        case 4:
            ambientLightLTR329.measurementRate = .rate1000ms
        default:
            ambientLightLTR329.measurementRate = .rate2000ms
        }
        
        streamingEvents.insert(ambientLightLTR329.periodicIlluminance)
        ambientLightLTR329.periodicIlluminance.startNotificationsAsync { (obj, error) in
            if let obj = obj {
                self.ambientLightLTR329Illuminance.text = String(format: "%.3f", obj.value.doubleValue)
            }
        }
    }
    
    @IBAction func ambientLightLTR329StopStreamPressed(_ sender: Any) {
        ambientLightLTR329StartStream.isEnabled = true
        ambientLightLTR329StopStream.isEnabled = false
        let ambientLightLTR329 = device.ambientLight as! MBLAmbientLightLTR329
        streamingEvents.remove(ambientLightLTR329.periodicIlluminance)
        ambientLightLTR329.periodicIlluminance.stopNotificationsAsync()
        ambientLightLTR329Illuminance.text = "X.XXX"
    }
*/
    
    
    // *************  Hygrometer  *************
    
/*    @IBAction func hygrometerBME280StartStreamPressed(_ sender: Any) {
        hygrometerBME280StartStream.isEnabled = false
        hygrometerBME280StopStream.isEnabled = true
        hygrometerBME280Oversample.isEnabled = false
        let hygrometerBME280 = device.hygrometer as! MBLHygrometerBME280
        switch hygrometerBME280Oversample.selectedSegmentIndex {
        case 0:
            hygrometerBME280.humidityOversampling = .oversample1X
        case 1:
            hygrometerBME280.humidityOversampling = .oversample2X
        case 2:
            hygrometerBME280.humidityOversampling = .oversample4X
        case 3:
            hygrometerBME280.humidityOversampling = .oversample8X
        default:
            hygrometerBME280.humidityOversampling = .oversample16X
        }
        
        hygrometerBME280Event = device.hygrometer!.humidity!.periodicRead(withPeriod: 700)
        streamingEvents.insert(hygrometerBME280Event)
        hygrometerBME280Event.startNotificationsAsync { (obj, error) in
            if let obj = obj {
                self.hygrometerBME280Humidity.text = String(format: "%.2f", obj.value.doubleValue)
            }
        }
    }
    
    @IBAction func hygrometerBME280StopStreamPressed(_ sender: Any) {
        hygrometerBME280StartStream.isEnabled = true
        hygrometerBME280StopStream.isEnabled = false
        hygrometerBME280Oversample.isEnabled = true
        streamingEvents.remove(hygrometerBME280Event)
        hygrometerBME280Event.stopNotificationsAsync()
        hygrometerBME280Humidity.text = "XX.XX"
    }
*/
    
    // *************  i2c  *************
    
/*    @IBAction func i2cReadBytesPressed(_ sender: Any) {
        if let deviceAddress = UInt8(i2cDeviceAddress.text!.drop0xPrefix, radix: 16) {
            if let registerAddress = UInt8(i2cRegisterAddress.text!.drop0xPrefix, radix: 16) {
                var length: UInt8 = 1
                if i2cSizeSelector.selectedSegmentIndex == 1 {
                    length = 2
                } else if i2cSizeSelector.selectedSegmentIndex == 2 {
                    length = 4
                }
                let reg = device.serial!.data(atDeviceAddress: deviceAddress, registerAddress: registerAddress, length: length)
                reg.readAsync().success { result in
                    self.i2cReadByteLabel.text = result.data?.description
                }
            } else {
                i2cRegisterAddress.text = ""
            }
        } else {
            i2cDeviceAddress.text = ""
        }
    }
    
    @IBAction func i2cWriteBytesPressed(_ sender: Any) {
        if let deviceAddress = UInt8(i2cDeviceAddress.text!.drop0xPrefix, radix: 16) {
            if let registerAddress = UInt8(i2cRegisterAddress.text!.drop0xPrefix, radix: 16) {
                if var writeData = Int32(i2cWriteByteField.text!.drop0xPrefix, radix: 16) {
                    var length: UInt8 = 1
                    if i2cSizeSelector.selectedSegmentIndex == 1 {
                        length = 2
                    } else if i2cSizeSelector.selectedSegmentIndex == 2 {
                        length = 4
                    }
                    let reg = device.serial!.data(atDeviceAddress: deviceAddress, registerAddress: registerAddress, length: length)
                    reg.writeAsync(Data(bytes: &writeData, count: Int(length)))
                }
                i2cWriteByteField.text = ""
            } else {
                i2cRegisterAddress.text = ""
            }
        } else {
            i2cDeviceAddress.text = ""
        }
    }
*/
    
    
    
    //***************** AMBIENT ENVIRONMENT ****************
    
    /*
        Begins streaming the baby's actions, 
        data is displayed both in image form, 
        and on the time comparison graphs.
        LED shines cyan when streaming.
    */
    @IBAction func AmbientEnvironmentStartStreamPressed(_ sender: Any) {
        
        AmbientEnvironmentStartStream.isEnabled = false
        AmbientEnvironmentStopStream.isEnabled = true
        device.led?.setLEDColorAsync(UIColor.cyan, withIntensity: 1.0)
        
        // -----  TEMP -----
        let temp1 = device.temperature!.onboardThermistor
        
        temperatureEvent = temp1?.periodicRead(withPeriod: 500)
        streamingEvents.insert(temperatureEvent)
        
        temp1!.readAsync().success { result in
            self.temperatureMeasurement.text = result.value.stringValue.appending("°C")
        }

        // -----  HUMIDITY -----
        hygrometerBME280Oversample.isEnabled = false
        let hygrometerBME280 = device.hygrometer as! MBLHygrometerBME280
            hygrometerBME280.humidityOversampling = .oversample16X
        
        hygrometerBME280Event = device.hygrometer!.humidity!.periodicRead(withPeriod: 700)
        streamingEvents.insert(hygrometerBME280Event)
        hygrometerBME280Event.startNotificationsAsync { (obj, error) in
            if let obj = obj {
                self.humidityMeasurement.text = String(format: "%.0f%%", obj.value.doubleValue)
            }
        }
        
        // -----  LIGHT -----
        let ambientLightLTR329 = device.ambientLight as! MBLAmbientLightLTR329
        // set measurement parameters
        ambientLightLTR329.gain = .gain1X
        ambientLightLTR329.integrationTime = .integration100ms
        ambientLightLTR329.measurementRate = .rate1000ms
        // create data storage array
      //  array2 = []
        
        // add to streaming events
        streamingEvents.insert(ambientLightLTR329.periodicIlluminance)
        ambientLightLTR329.periodicIlluminance.startNotificationsAsync { (obj, error) in
            if let obj = obj {
                self.lightMeasurement.text = String(format: "%.0f lux", obj.value.doubleValue)
            }
            if let obj = obj {
                self.lightGraphView.addX(obj.value.doubleValue, y: 1, z: 1)
            }
      //      array2.append((obj?.value.doubleValue)!)
        }
        
       
        // ----- ACCELEROMETER -----
        updateAccelerometerBMI160Settings()
        var array = [MBLAccelerometerData]() /* capacity: 1000 */
        accelerometerBMI160Data = array
        streamingEvents.insert(device.accelerometer!.dataReadyEvent)
        device.accelerometer!.dataReadyEvent.startNotificationsAsync { (obj, error) in
            if let obj = obj {
                self.accelerometerGraphView.addX(obj.x, y: obj.y, z: obj.z)
                array.append(obj)
            }
        }
  
        // ----- GYROSCOPE -----
        updateGyroBMI160Settings()
        var array3 = [MBLGyroData]() /* capacity: 1000 */
        gyroBMI160Data = array3
        streamingEvents.insert(device.gyro!.dataReadyEvent)
        device.gyro!.dataReadyEvent.startNotificationsAsync { (obj, error) in
            if let obj = obj {
                self.gyroBMI160Graph.addX(obj.x * 0.008, y: obj.y * 0.008, z: obj.z * 0.008)
                array3.append(obj)
            }
        }
        
        
    }
    
    /*
        Stops streaming the babys actions.
    */
    @IBAction func AmbientEnvironmentStopStreamPressed(_ sender: Any) {
    
        AmbientEnvironmentStartStream.isEnabled = true
        AmbientEnvironmentStopStream.isEnabled = false
        device.led?.setLEDOnAsync(false, withOptions: 1)
        
        // ----- temp -----
        
        
        // ----- humidity -----
        hygrometerBME280Oversample.isEnabled = true
        streamingEvents.remove(hygrometerBME280Event)
        hygrometerBME280Event.stopNotificationsAsync()
        
        // ----- light -----
        let ambientLightLTR329 = device.ambientLight as! MBLAmbientLightLTR329
        streamingEvents.remove(ambientLightLTR329.periodicIlluminance)
        ambientLightLTR329.periodicIlluminance.stopNotificationsAsync()
        
        // ----- accelerometer -----
        streamingEvents.remove(device.accelerometer!.dataReadyEvent)
        device.accelerometer!.dataReadyEvent.stopNotificationsAsync()
     
        
        // ----- gyroscope -----
        streamingEvents.remove(device.gyro!.dataReadyEvent)
        device.gyro!.dataReadyEvent.stopNotificationsAsync()
    }

    // ***************  BABY STATUS ***************
    
    /* 
        Begins logging the babys actions, 
        but not streaming them to the display.
        Data is stored on the device.
        LED flashes white when logging.
    */
    @IBAction func startMonitoringPressed(_ sender: Any) {
        
        startMonitoringButton.isEnabled = false
        stopMonitoringButton.isEnabled = true
        device.led?.flashColorAsync(UIColor.white, withIntensity: 1.0)
    
        // ----- Track Movement -----
        updateAccelerometerBMI160Settings()
        device.accelerometer!.dataReadyEvent.startLoggingAsync()
        
        updateGyroBMI160Settings()
        device.gyro!.dataReadyEvent.startLoggingAsync()
        
        // ----- Track Crying -----
        
        
        
        // ----- Track Feeding -----
     
    }
    
    /* 
        Stops logging the babys actions and downloads the data to the mobile device.
        !!!!!!!!! NOT FUNCTIONING PROPERLY !!!!!!!!!!
    */
    @IBAction func stopMonitoringPressed(_ sender: Any) {
    
        startMonitoringButton.isEnabled = true
        stopMonitoringButton.isEnabled = false
        device.led?.setLEDOnAsync(false, withOptions: 1)
        
        //-----  ACCELEROMETER -----
        let hud = MBProgressHUD.showAdded(to: UIApplication.shared.keyWindow!, animated: true)
        hud.mode = .determinateHorizontalBar
        hud.label.text = "Downloading..."
        device.accelerometer!.dataReadyEvent.downloadLogAndStopLoggingAsync(true) { number in
            hud.progress = number
            }.success { array in
                self.accelerometerBMI160Data = array as! [MBLAccelerometerData]
                for obj in self.accelerometerBMI160Data {
                    self.accelerometerGraphView.addX(obj.x, y: obj.y, z: obj.z)
                }
                hud.mode = .indeterminate
                hud.label.text = "Clearing Log..."
                self.logCleanup { error in
                    hud.hide(animated: true)
                    if error != nil {
                        self.connectDevice(false)
                    }
                }
            }.failure { error in
                self.connectDevice(false)
                hud.hide(animated: true)
        }
        
        
        //-----  GYROSCOPE -----
        device.gyro!.dataReadyEvent.downloadLogAndStopLoggingAsync(true) { number in
            hud.progress = number
            }.success { array in
                self.gyroBMI160Data = array as! [MBLGyroData]
                for obj in self.gyroBMI160Data {
                    self.gyroBMI160Graph.addX(obj.x * 0.008, y: obj.y * 0.008, z: obj.z * 0.008)
                }
                hud.mode = .indeterminate
                hud.label.text = "Clearing Log..."
                self.logCleanup { error in
                    hud.hide(animated: true)
                    if error != nil {
                        self.connectDevice(false)
                    }
                }
            }.failure { error in
                self.connectDevice(false)
                hud.hide(animated: true)
                
                
                // email data
            var gyroData = Data()
            for dataElement in self.gyroBMI160Data {
                gyroData.append("\(dataElement.timestamp.timeIntervalSince1970),\(dataElement.x),\(dataElement.y),\(dataElement.z)\n".data(using: String.Encoding.utf8)!)
            }
            self.send(gyroData, title: "GyroData")
        }
        
        //-----  CRYING -----
        
        //-----  FEEDING -----
        
        //-----  TEMPERATURE -----
        
        //-----  LIGHT -----
        
        //-----  HUMIDITY -----
        
    }
    
    
    // MARK: - DFU Service delegate methods
    
    func dfuStateDidChange(to state: DFUState) {
        if state == .completed {
            hud?.mode = .text
            hud?.label.text = "Success!"
            hud?.hide(animated: true, afterDelay: 2.0)
        }
    }
    
    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        print("Firmware update error \(error): \(message)")
        
        let alertController = UIAlertController(title: "Update Error", message: "Please re-connect and try again, if you can't connect, try MetaBoot Mode to recover.\nError: \(message)", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
        
        hud?.hide(animated: true)
    }
    
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int,
                              currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        hud?.progress = Float(progress) / 100.0
    }
    
    func logWith(_ level: LogLevel, message: String) {
        if level.rawValue >= LogLevel.application.rawValue {
            print("\(level.name()): \(message)")
        }
    }
    
    func select(_ peripheral:CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) -> Bool {
        return peripheral.identifier == device.identifier
    }
    
    func filterBy(hint dfuServiceUUID: CBUUID) -> [CBUUID]? {
        return nil
    }
}