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
    
     // *************  INITIALIZE  *************
    // Device info & cells
    @IBOutlet weak var connectionSwitch: UISwitch!
    @IBOutlet weak var connectionStateLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var setNameButton: UIButton!
    
    @IBOutlet var allCells: [UITableViewCell]!
    @IBOutlet var infoAndStateCells: [UITableViewCell]!
    @IBOutlet weak var firmwareUpdateLabel: UILabel!

    // Monitoring & Streaming Buttons
    @IBOutlet weak var startMonitoringButton: UIButton!
    @IBOutlet weak var stopMonitoringButton: UIButton!
    
    @IBOutlet weak var AmbientEnvironmentStartStream: UIButton!
    @IBOutlet weak var AmbientEnvironmentStopStream: UIButton!
    
    // Measurement Labels
    @IBOutlet weak var temperatureMeasurement: UILabel!
    @IBOutlet weak var humidityMeasurement: UILabel!
    @IBOutlet weak var lightMeasurement: UILabel!
    
    // Graph Views & Data
    @IBOutlet weak var accelerometerGraphView: APLGraphView!
    @IBOutlet weak var lightGraphView: APLGraphView!
    @IBOutlet weak var gyroBMI160Graph: APLGraphView!
    var accelerometerBMI160Data = [MBLAccelerometerData]()
    var gyroBMI160Data = [MBLGyroData]()
    
    // Events
    var hygrometerBME280Event: MBLEvent<MBLNumericData>!
    var temperatureEvent: MBLEvent<MBLNumericData>!
    
    // Controllers, etc.
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
    
    
    
     // *************  SETUP & GENERAL FUNCTIONS  *************
    
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
        

        if device.programedByOtherApp {
            if UserDefaults.standard.object(forKey: "ihaveseenprogramedByOtherAppmessage") == nil {
                UserDefaults.standard.set(1, forKey: "ihaveseenprogramedByOtherAppmessage")
                UserDefaults.standard.synchronize()
                self.showAlertTitle("WARNING", message: "You have connected to a device being used by another app.  To prevent errors and data loss for the other application we are only showing a limited number of features.  If you wish to take control please press 'Reset To Factory Defaults', which will wipe the device clean.")
            }
            reloadData(animated: true)
            return
        }
        
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
   
/*    @IBAction func turn(onCyanLEDPressed sender: UIButton) {
        device.led?.setLEDColorAsync(UIColor.cyan, withIntensity: 1.0)
    }
    
    @IBAction func flashWhiteLEDPressed(_ sender: Any) {
        device.led?.flashColorAsync(UIColor.white, withIntensity: 1.0)
    }
*/    
    @IBAction func turnOffLEDPressed(_ sender: Any) {
        device.led?.setLEDOnAsync(false, withOptions: 1)
    }
    
    
    // *************  Accelerometer  *************
 
    func updateAccelerometerBMI160Settings() {
        let accelerometerBMI160 = self.device.accelerometer as! MBLAccelerometerBMI160
    
        
        accelerometerBMI160.fullScaleRange = .range2G
        self.accelerometerGraphView.fullScale = 2
        accelerometerBMI160.sampleFrequency = 50
        
    }
    
/*    @IBAction func accelerometerBMI160EmailDataPressed(_ sender: Any) {
        var accelerometerData = Data()
        for dataElement in accelerometerBMI160Data {
            accelerometerData.append("\(dataElement.timestamp.timeIntervalSince1970),\(dataElement.x),\(dataElement.y),\(dataElement.z)\n".data(using: String.Encoding.utf8)!)
        }
        send(accelerometerData, title: "AccData")
    }
*/

    // *************  Gyroscope  *************
    
    func updateGyroBMI160Settings() {
        
        let gyroBMI160 = self.device.gyro as! MBLGyroBMI160
        gyroBMI160.fullScaleRange = .range500
        self.gyroBMI160Graph.fullScale = 4
        gyroBMI160.sampleFrequency = 50

    }
    
/*    @IBAction func gyroBMI160EmailDataPressed(_ sender: Any) {
        var gyroData = Data()
        for dataElement in self.gyroBMI160Data {
            gyroData.append("\(dataElement.timestamp.timeIntervalSince1970),\(dataElement.x),\(dataElement.y),\(dataElement.z)\n".data(using: String.Encoding.utf8)!)
        }
        self.send(gyroData, title: "GyroData")
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
        let hygrometerBME280 = device.hygrometer as! MBLHygrometerBME280
            hygrometerBME280.humidityOversampling = .oversample1X
        
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

    // ***************  BABY LOGGING ***************
    
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
