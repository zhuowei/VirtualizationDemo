//
//  ContentView.swift
//  VirtualizationDemo
//
//  Created by Zhuowei Zhang on 2021-06-07.
//

import SwiftUI
import Virtualization

struct VMView: NSViewRepresentable {
    @Binding var virtualMachine:VZVirtualMachine?
    func makeNSView(context: Context) -> VZVirtualMachineView {
        return VZVirtualMachineView()
    }
    func updateNSView(_ nsView: VZVirtualMachineView, context: Context) {
        nsView.virtualMachine = virtualMachine
    }
}

struct ContentView: View {
    @State var virtualMachine: VZVirtualMachine? = runIt(options: gOptions)
    var body: some View {
        VMView(virtualMachine: $virtualMachine).frame(width: 1024, height: 768, alignment: .top)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(virtualMachine: nil)
    }
}
