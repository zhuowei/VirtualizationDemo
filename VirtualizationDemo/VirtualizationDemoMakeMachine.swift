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
    let serialPort = VZVirtioConsoleDeviceSerialPortConfiguration()
    serialPort.attachment = VZFileHandleSerialPortAttachment(fileHandleForReading: .standardInput, fileHandleForWriting: .standardOutput)
    vmConfig.serialPorts = [serialPort]
    if let disk = options.disk {
        let virtioBlockDevice = VZVirtioBlockDeviceConfiguration(attachment: try! VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: disk), readOnly: true))
        vmConfig.storageDevices = [virtioBlockDevice]
    }

    // Graphics requires a separate entitlement!
    // For some reason Xcode's letting me sign with com.apple.private.virtualization?
    // Note: this panics the kernel when running in VMWare Fusion
    // probably since there's no Metal acceleration
    // so comment out if you're doing nested virtualization
    // the keyboard works fine.
    let graphics = VZMacGraphicsDeviceConfiguration()
    graphics.displays = [VZMacGraphicsDisplayConfiguration(widthInPixels: 1024, heightInPixels: 768, pixelsPerInch: 72)]
    vmConfig.graphicsDevices = [graphics]
    // end comment out

    let keyboard = VZUSBKeyboardConfiguration()
    vmConfig.keyboards = [keyboard]
    let usbTablet = VZUSBScreenCoordinatePointingDeviceConfiguration()
    vmConfig.pointingDevices = [usbTablet]
    return vmConfig
}

let standardDelegate = VMDelegate()

func runIt(options: VirtualizationDemoOptions) -> VZVirtualMachine {
    let vmConfig = createMachineConfig(options: options)
    let vm = VZVirtualMachine(configuration: vmConfig)
    vm.delegate = standardDelegate
    vm.start() { error in
        print(error)
    }
    return vm
}

