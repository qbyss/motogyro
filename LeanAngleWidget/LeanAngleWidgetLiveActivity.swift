//
//  LeanAngleWidgetLiveActivity.swift
//  LeanAngleWidget
//
//  Created by Jack on 16/11/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LeanAngleWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct LeanAngleWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LeanAngleWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension LeanAngleWidgetAttributes {
    fileprivate static var preview: LeanAngleWidgetAttributes {
        LeanAngleWidgetAttributes(name: "World")
    }
}

extension LeanAngleWidgetAttributes.ContentState {
    fileprivate static var smiley: LeanAngleWidgetAttributes.ContentState {
        LeanAngleWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: LeanAngleWidgetAttributes.ContentState {
         LeanAngleWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: LeanAngleWidgetAttributes.preview) {
   LeanAngleWidgetLiveActivity()
} contentStates: {
    LeanAngleWidgetAttributes.ContentState.smiley
    LeanAngleWidgetAttributes.ContentState.starEyes
}
