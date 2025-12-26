//
//  SafetyLiveActivityView.swift
//  SanctuaryWidget
//
//  Live Activity UI for lock screen safety monitoring display
//

import ActivityKit
import SwiftUI
import WidgetKit

struct SafetyLiveActivityView: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SafetyActivityAttributes.self) { context in
            // Lock screen / banner view
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        statusIcon(for: context.state.status)
                            .font(.system(.title2, design: .rounded))
                        
                        Text(context.state.status.displayText)
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.status == .monitoring || context.state.status == .panic {
                        Button(intent: CheckInIntent()) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(.title2, design: .rounded))
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 16) {
                        if context.state.status == .monitoring {
                            Button(intent: PanicButtonIntent()) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text("PANIC")
                                }
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.red)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Button(intent: StopMonitoringIntent()) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Stop")
                            }
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.5))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            } compactLeading: {
                statusIcon(for: context.state.status)
                    .foregroundStyle(statusColor(for: context.state.status))
            } compactTrailing: {
                Text(context.state.status == .panic ? "SOS" : "ON")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(statusColor(for: context.state.status))
            } minimal: {
                statusIcon(for: context.state.status)
                    .foregroundStyle(statusColor(for: context.state.status))
            }
        }
    }
    
    private func statusIcon(for status: MonitoringStatus) -> some View {
        Image(systemName: status.icon)
    }
    
    private func statusColor(for status: MonitoringStatus) -> Color {
        switch status {
        case .idle: return .green
        case .monitoring: return .safetyOrange
        case .panic: return .red
        case .resolved: return .green
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<SafetyActivityAttributes>
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Status indicator
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: context.state.status.icon)
                        .font(.system(.title2, design: .rounded))
                        .foregroundStyle(statusColor)
                    
                    Text(context.state.status.displayText)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                
                // Duration
                Text("Started \(context.state.startedAt, style: .relative) ago")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.gray)
                
                // Custom message if any
                if let message = context.state.customMessage {
                    Text(message)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Right: Action buttons
            VStack(spacing: 8) {
                if context.state.status == .monitoring {
                    // Check In button
                    Button(intent: CheckInIntent()) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                    
                    // Panic button
                    Button(intent: PanicButtonIntent()) {
                        Text("SOS")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                } else if context.state.status == .panic {
                    // Escalation timer
                    if let escalationTime = context.state.escalationTime {
                        VStack {
                            Text("Auto 911 in")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.red)
                            
                            Text(escalationTime, style: .timer)
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(.red)
                        }
                    }
                    
                    // Cancel panic
                    Button(intent: StopMonitoringIntent()) {
                        Text("I'm Safe")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color.black)
    }
    
    private var statusColor: Color {
        switch context.state.status {
        case .idle: return .green
        case .monitoring: return .safetyOrange
        case .panic: return .red
        case .resolved: return .green
        }
    }
}

