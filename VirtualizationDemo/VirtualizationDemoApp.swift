//
//  VirtualizationDemoApp.swift
//  VirtualizationDemo
//
//  Created by Zhuowei Zhang on 2021-06-07.
//

import SwiftUI
import ArgumentParser

// Examples:
// ./VirtualizationDemo.app/Contents/MacOS/VirtualizationDemo --apple-model 2 \
// --apple-nvram Nvram.bin --add-entropy-device --add-graphics \
// --apple-rom Rom.bin --apple-ecid fadeface

@main
struct VirtualizationDemoOptions : ParsableCommand {
    @Option(name: .customLong("NSDocumentRevisionsDebugMode", withSingleDash: true))
    var unusedForXcode:String?
    @Option
    var linuxKernel:String?
    @Option
    var linuxRamdisk:String?
    @Option
    var linuxCmdline:String = "console=hvc0 serial"
#if arch(arm64)
    // The hardware version: either 1 or 2.
    // (macOS 12 has bootroms and device trees for both vma1 and vma2.)
    @Option
    var appleModel:Int?
    // Override the bootrom path. Loaded at 0x100000, signature not checked, but seems to
    // run with the rest of RAM disabled: loading an iBoot here gets me a
    // "Unhandled encoding a8817cbf" error from the first `stp` in the relocation loop,
    @Option
    var appleROM:String?
    // The NVRAM of the macOS VM. If it doesn't exist, this creates it.
    @Option
    var appleNVRAM:String?
    // The ECID of the device. A 64-bit number written in hexadecimal.
    // Leave blank for a random ECID.
    @Option
    var appleECID:String?
    // Not sure what this does: needs the private entitlement.
    @Flag
    var appleTurnOffProduction:Bool = false
#endif
    @Option
    var disk:String?
    @Option
    var memorySizeMegabytes:UInt64 = 1024
    @Option
    var ipswPath:String?
    // Might be needed for Fedora aarch64?
    // https://github.com/coreos/fedora-coreos-tracker/issues/431
    @Flag
    var addEntropyDevice:Bool = false
    // Needs the private entitlement on Intel, crashes immediately.
    // Doesn't need it on Apple Silicon.
    @Flag
    var addGraphics:Bool = false
    func run() {
        gOptions = self
        VirtualizationDemoApp.main()
    }
}

var gOptions:VirtualizationDemoOptions!

struct VirtualizationDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
