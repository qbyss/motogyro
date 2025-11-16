//
//  MotoGyroWidgetBundle.swift
//  MotoGyroWidget
//
//  Created by Jack on 16/11/2025.
//

import WidgetKit
import SwiftUI

@main
struct MotoGyroWidgetBundle: WidgetBundle {
    var body: some Widget {
        MotoGyroWidget()
        MotoGyroWidgetControl()
        MotoGyroWidgetLiveActivity()
    }
}
