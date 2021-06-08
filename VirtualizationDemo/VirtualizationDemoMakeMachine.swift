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
        bootloader.commandLine = "console=hvc0 serial"
        vmConfig.bootLoader = bootloader
    }
    let serialPort = VZVirtioConsoleDeviceSerialPortConfiguration()
    serialPort.attachment = VZFileHandleSerialPortAttachment(fileHandleForReading: .standardInput, fileHandleForWriting: .standardOutput)
    vmConfig.serialPorts = [serialPort]
    if let disk = options.disk {
        let virtioBlockDevice = VZVirtioBlockDeviceConfiguration(attachment: try! VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: disk), readOnly: true))
        vmConfig.storageDevices = [virtioBlockDevice]
    }
    return vmConfig
}

let standardDelegate = VMDelegate()
var gVM:VZVirtualMachine!

func runIt(options: VirtualizationDemoOptions) {
    let vmConfig = createMachineConfig(options: options)
    let vm = VZVirtualMachine(configuration: vmConfig)
    vm.delegate = standardDelegate
    vm.start() { error in
        print(error)
    }
    gVM = vm
}

