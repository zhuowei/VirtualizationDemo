//
//  VirtualizationDemoMakeMachine.swift
//  VirtualizationDemo
//
//  Created by Zhuowei Zhang on 2021-06-07.
//

import Foundation
import Virtualization

class VMDelegate: NSObject, VZVirtualMachineDelegate {
    func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
        print(error)
    }
    func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        print("stopped")
    }
}

func createMachineConfig(options: VirtualizationDemoOptions) -> VZVirtualMachineConfiguration {
    let vmConfig = VZVirtualMachineConfiguration()
    vmConfig.memorySize = options.memorySizeMegabytes * 1024 * 1024
    if let linuxKernel = options.linuxKernel {
        let bootloader = VZLinuxBootLoader(kernelURL: URL(fileURLWithPath: linuxKernel))
        if let linuxRamdisk = options.linuxRamdisk {
            bootloader.initialRamdiskURL = URL(fileURLWithPath: linuxRamdisk)
        }
        bootloader.commandLine = options.linuxCmdline
        vmConfig.bootLoader = bootloader
    }
    vmConfig.cpuCount = 4
    #if arch(arm64)
    if let appleModel = options.appleModel {
        // TODO(zhuowei): actually add some params into this
        let platform = VZMacPlatformConfiguration()
        let modelPlist:[String: Any] = [
            "DataRepresentationVersion": 1,
            "MinimumSupportedOS": [12, 0, 0],
            "PlatformVersion": appleModel,
        ]
        let modelData = try! PropertyListSerialization.data(fromPropertyList: modelPlist, format: .binary, options: 0)
        let model = VZMacHardwareModel(dataRepresentation: modelData)!
        platform.hardwareModel = model
        if let appleNVRAM = options.appleNVRAM {
            var auxStorage:VZMacAuxiliaryStorage!
            if FileManager.default.fileExists(atPath: appleNVRAM) {
                auxStorage = VZMacAuxiliaryStorage(contentsOf: URL(fileURLWithPath: appleNVRAM))
            } else {
                auxStorage = try! VZMacAuxiliaryStorage(creatingStorageAt: URL(fileURLWithPath: appleNVRAM), hardwareModel: model, options: [])
            }
            platform.auxiliaryStorage = auxStorage
        }
        if let appleECID = options.appleECID {
            let ecidPlist:[String: Any] = [
                "ECID": UInt64(appleECID, radix: 16)!,
            ]
            let ecidData = try! PropertyListSerialization.data(fromPropertyList: ecidPlist, format: .binary, options: 0)
            platform.machineIdentifier = VZMacMachineIdentifier(dataRepresentation: ecidData)!
        }
        if options.appleTurnOffProduction {
            platform.setValue(false, forKey: "_productionModeEnabled")
        }
        vmConfig.platform = platform
        // If we have a Linux bootloader, that takes presidence
        if options.linuxKernel == nil {
            let bootloader = VZMacOSBootLoader()
            if let appleROM = options.appleROM {
                bootloader.setValue(URL(fileURLWithPath: appleROM), forKey: "_romURL")
            }
            vmConfig.bootLoader = bootloader
        }
    }
    #endif
    let serialPort = VZVirtioConsoleDeviceSerialPortConfiguration()
    serialPort.attachment = VZFileHandleSerialPortAttachment(fileHandleForReading: .standardInput, fileHandleForWriting: .standardOutput)
    vmConfig.serialPorts = [serialPort]
    if let disk = options.disk {
        let virtioBlockDevice = VZVirtioBlockDeviceConfiguration(attachment: try! VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: disk), readOnly: false))
        vmConfig.storageDevices = [virtioBlockDevice]
    }
    if options.addEntropyDevice {
        let entropyDevice = VZVirtioEntropyDeviceConfiguration()
        vmConfig.entropyDevices = [entropyDevice]
    }

    // Graphics requires a separate entitlement on Intel!
    // For some reason Xcode's letting me sign with com.apple.private.virtualization?
    // It's fine on Apple Silicon;
    // Note: this panics the kernel when running in VMWare Fusion
    // probably since there's no Metal acceleration
    // so comment out if you're doing nested virtualization
    // the keyboard works fine.
    if options.addGraphics {
        let graphics = VZMacGraphicsDeviceConfiguration()
        graphics.displays = [VZMacGraphicsDisplayConfiguration(widthInPixels: 1024, heightInPixels: 768, pixelsPerInch: 72)]
        vmConfig.graphicsDevices = [graphics]
    }
    // end comment out

    let keyboard = VZUSBKeyboardConfiguration()
    vmConfig.keyboards = [keyboard]
    let usbTablet = VZUSBScreenCoordinatePointingDeviceConfiguration()
    vmConfig.pointingDevices = [usbTablet]
    let network = VZNATNetworkDeviceAttachment()
    let networkDevice = VZVirtioNetworkDeviceConfiguration()
    networkDevice.attachment = network
    vmConfig.networkDevices = [networkDevice]
    return vmConfig
}

let standardDelegate = VMDelegate()

func startInstall(virtualMachine: VZVirtualMachine, ipswPath: String) {
    #if arch(arm64)
    print(URL(fileURLWithPath: ipswPath))
    VZMacOSRestoreImage.load(from: URL(fileURLWithPath: ipswPath)) {
        result in
        print("result!!!")
        guard case .success(let restoreImage) = result else {
            print("no restore image!!!")
            return
        }
        print(restoreImage)
        let installer = VZMacOSInstaller(virtualMachine: virtualMachine, restoreImage: restoreImage)
        installer.install() { error in
            print(error)
        }
    }
    #endif
}

func runIt(options: VirtualizationDemoOptions) -> VZVirtualMachine {
    let vmConfig = createMachineConfig(options: options)
    let vm = VZVirtualMachine(configuration: vmConfig)
    vm.delegate = standardDelegate
    vm.start() { error in
        print(error)
        if let ipswPath = options.ipswPath {
            startInstall(virtualMachine: vm, ipswPath: ipswPath)
        }
    }
    return vm
}

