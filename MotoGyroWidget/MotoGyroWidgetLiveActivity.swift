//
//  MotoGyroWidgetLiveActivity.swift
//  MotoGyroWidget
//
//  Created by Jack on 16/11/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MotoGyroWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MotoGyroWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MotoGyroWidgetAttributes.self) { context in
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

extension MotoGyroWidgetAttributes {
    fileprivate static var preview: MotoGyroWidgetAttributes {
        MotoGyroWidgetAttributes(name: "World")
    }
}

extension MotoGyroWidgetAttributes.ContentState {
    fileprivate static var smiley: MotoGyroWidgetAttributes.ContentState {
        MotoGyroWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MotoGyroWidgetAttributes.ContentState {
         MotoGyroWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MotoGyroWidgetAttributes.preview) {
   MotoGyroWidgetLiveActivity()
} contentStates: {
    MotoGyroWidgetAttributes.ContentState.smiley
    MotoGyroWidgetAttributes.ContentState.starEyes
}
