//
//  SafetyWidgetBundle.swift
//  SanctuaryWidget
//
//  Widget bundle containing safety widget and Live Activity
//

import WidgetKit
import SwiftUI

@main
struct SanctuaryWidgetBundle: WidgetBundle {
    var body: some Widget {
        SanctuaryWidget()
        SafetyLiveActivityView()
    }
}
