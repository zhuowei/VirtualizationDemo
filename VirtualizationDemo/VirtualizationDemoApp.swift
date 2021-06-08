//
//  VirtualizationDemoApp.swift
//  VirtualizationDemo
//
//  Created by Zhuowei Zhang on 2021-06-07.
//

import SwiftUI
import ArgumentParser

@main
struct VirtualizationDemoOptions : ParsableCommand {
    @Option(name: .customLong("NSDocumentRevisionsDebugMode", withSingleDash: true))
    var unusedForXcode:String?
    @Option
    var linuxKernel:String?
    @Option
    var linuxRamdisk:String?
    @Option
    var linuxCmdline:String?
    @Option
    var disk:String?
    @Option
    var memorySizeMegabytes:UInt64 = 1024
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
