//
//  LeanAngleWidgetBundle.swift
//  LeanAngleWidget
//
//  Created by Jack on 16/11/2025.
//

import WidgetKit
import SwiftUI

@main
struct LeanAngleWidgetBundle: WidgetBundle {
    var body: some Widget {
        LeanAngleWidget()
        LeanAngleWidgetControl()
        LeanAngleWidgetLiveActivity()
    }
}
