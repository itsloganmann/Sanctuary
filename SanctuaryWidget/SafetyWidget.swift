//
//  SafetyWidget.swift
//  SanctuaryWidget
//
//  Interactive widget for quick safety access from lock screen and home screen
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Timeline Provider

struct SafetyWidgetProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> SafetyWidgetEntry {
        SafetyWidgetEntry(
            date: Date(),
            isMonitoring: false,
            lastCheckIn: nil
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SafetyWidgetEntry) -> Void) {
        let entry = SafetyWidgetEntry(
            date: Date(),
            isMonitoring: UserDefaults.shared.bool(forKey: "isMonitoringActive"),
            lastCheckIn: UserDefaults.shared.object(forKey: "lastCheckInTime") as? Date
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SafetyWidgetEntry>) -> Void) {
        let entry = SafetyWidgetEntry(
            date: Date(),
            isMonitoring: UserDefaults.shared.bool(forKey: "isMonitoringActive"),
            lastCheckIn: UserDefaults.shared.object(forKey: "lastCheckInTime") as? Date
        )
        
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Entry

struct SafetyWidgetEntry: TimelineEntry {
    let date: Date
    let isMonitoring: Bool
    let lastCheckIn: Date?
}

// MARK: - Widget Views

struct SafetyWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: SafetyWidgetEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallSafetyWidget(entry: entry)
        case .systemMedium:
            MediumSafetyWidget(entry: entry)
        case .accessoryCircular:
            CircularSafetyWidget(entry: entry)
        case .accessoryRectangular:
            RectangularSafetyWidget(entry: entry)
        default:
            SmallSafetyWidget(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallSafetyWidget: View {
    let entry: SafetyWidgetEntry
    
    var body: some View {
        ZStack {
            // Background
            ContainerRelativeShape()
                .fill(Color.black)
            
            VStack(spacing: 12) {
                // Status indicator
                if entry.isMonitoring {
                    PulsingRadar()
                } else {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.green)
                }
                
                Text(entry.isMonitoring ? "Active" : "Ready")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(entry.isMonitoring ? Color.safetyOrange : .green)
            }
            .padding()
        }
        .widgetURL(URL(string: "sanctuary://widget-tap"))
    }
}

// MARK: - Medium Widget

struct MediumSafetyWidget: View {
    let entry: SafetyWidgetEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color.black)
            
            HStack(spacing: 20) {
                // Left: Status
                VStack(alignment: .leading, spacing: 8) {
                    if entry.isMonitoring {
                        PulsingRadar()
                            .frame(width: 50, height: 50)
                    } else {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.green)
                    }
                    
                    Text(entry.isMonitoring ? "Monitoring" : "Safe")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white)
                    
                    if let lastCheckIn = entry.lastCheckIn {
                        Text("Last check-in: \(lastCheckIn.formatted(date: .omitted, time: .shortened))")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.gray)
                    }
                }
                
                Spacer()
                
                // Right: Action buttons
                VStack(spacing: 8) {
                    Button(intent: ToggleSafetyMonitoringIntent()) {
                        Label(
                            entry.isMonitoring ? "Stop" : "Start",
                            systemImage: entry.isMonitoring ? "stop.fill" : "play.fill"
                        )
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(entry.isMonitoring ? Color.red.opacity(0.8) : Color.safetyOrange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    
                    if entry.isMonitoring {
                        Button(intent: CheckInIntent()) {
                            Label("Check In", systemImage: "checkmark.circle")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.8))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 100)
            }
            .padding()
        }
    }
}

// MARK: - Lock Screen Circular Widget

struct CircularSafetyWidget: View {
    let entry: SafetyWidgetEntry
    
    var body: some View {
        ZStack {
            if entry.isMonitoring {
                // Pulsing indicator for active monitoring
                Circle()
                    .stroke(Color.safetyOrange, lineWidth: 2)
                
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.safetyOrange)
            } else {
                // Shield for idle state
                Circle()
                    .stroke(Color.green, lineWidth: 2)
                
                Image(systemName: "shield.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.green)
            }
        }
        .widgetURL(URL(string: "sanctuary://widget-tap"))
    }
}

// MARK: - Lock Screen Rectangular Widget

struct RectangularSafetyWidget: View {
    let entry: SafetyWidgetEntry
    
    var body: some View {
        HStack {
            if entry.isMonitoring {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .foregroundStyle(Color.safetyOrange)
            } else {
                Image(systemName: "shield.fill")
                    .foregroundStyle(.green)
            }
            
            VStack(alignment: .leading) {
                Text("Sanctuary")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.semibold)
                
                Text(entry.isMonitoring ? "Monitoring Active" : "Tap to activate")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .widgetURL(URL(string: "sanctuary://widget-tap"))
    }
}

// MARK: - Pulsing Radar Animation

struct PulsingRadar: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Outer pulse rings
            ForEach(0..<3) { index in
                Circle()
                    .stroke(Color.safetyOrange.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                    .scaleEffect(isAnimating ? 1.0 + CGFloat(index) * 0.3 : 0.8)
                    .opacity(isAnimating ? 0 : 1)
            }
            
            // Center icon
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 24))
                .foregroundStyle(Color.safetyOrange)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Widget Configuration

struct SanctuaryWidget: Widget {
    let kind: String = "SanctuaryWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SafetyWidgetProvider()) { entry in
            SafetyWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Safety Monitor")
        .description("Quick access to safety monitoring controls")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    SanctuaryWidget()
} timeline: {
    SafetyWidgetEntry(date: .now, isMonitoring: false, lastCheckIn: nil)
    SafetyWidgetEntry(date: .now, isMonitoring: true, lastCheckIn: Date())
}
