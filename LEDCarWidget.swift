import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct LEDWidgetEntry: TimelineEntry {
    let date: Date
    let deviceName: String
    let isConnected: Bool
    let brightness: Int
    let currentEffect: String
}

// MARK: - Widget Provider
struct LEDWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LEDWidgetEntry {
        LEDWidgetEntry(
            date: Date(),
            deviceName: "LED CAR 01",
            isConnected: false,
            brightness: 50,
            currentEffect: "Color"
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LEDWidgetEntry) -> ()) {
        let entry = LEDWidgetEntry(
            date: Date(),
            deviceName: "LED CAR 01",
            isConnected: true,
            brightness: 75,
            currentEffect: "Breathing"
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LEDWidgetEntry>) -> ()) {
        let entry = LEDWidgetEntry(
            date: Date(),
            deviceName: "LED CAR 01",
            isConnected: true,
            brightness: 75,
            currentEffect: "Breathing"
        )
        
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Widget Views
struct LEDWidgetView: View {
    let entry: LEDWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (Lock Screen)
struct SmallWidgetView: View {
    let entry: LEDWidgetEntry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Circle()
                    .fill(entry.isConnected ? Color.green : Color.gray)
                    .frame(width: 6, height: 6)
                
                Text("LED CAR 01")
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Brillo", systemImage: "sun.max")
                        .font(.system(size: 10, weight: .semibold))
                    
                    Text("\(entry.brightness)%")
                        .font(.system(size: 14, weight: .bold))
                }
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(.cyan)
            }
        }
        .padding(12)
        .background(Color(#colorLiteral(red: 0.1, green: 0.1, blue: 0.15, alpha: 1)))
        .cornerRadius(10)
    }
}

// MARK: - Medium Widget (Home Screen)
struct MediumWidgetView: View {
    let entry: LEDWidgetEntry
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(entry.isConnected ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        
                        Text(entry.deviceName)
                            .font(.system(size: 14, weight: .bold))
                    }
                    
                    Text(entry.isConnected ? "Conectado" : "Desconectado")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "lightbulb.led")
                    .font(.system(size: 24))
                    .foregroundColor(.cyan)
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Brillo")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack(spacing: 6) {
                        Image(systemName: "sun.max")
                            .font(.system(size: 12))
                        Text("\(entry.brightness)%")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Efecto")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                        Text(entry.currentEffect)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(#colorLiteral(red: 0.1, green: 0.1, blue: 0.15, alpha: 1)))
        .cornerRadius(12)
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: LEDWidgetEntry
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(entry.isConnected ? Color.green : Color.gray)
                            .frame(width: 10, height: 10)
                        
                        Text(entry.deviceName)
                            .font(.system(size: 18, weight: .bold))
                    }
                    
                    Text(entry.isConnected ? "Conectado y listo" : "Desconectado")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "lightbulb.led")
                    .font(.system(size: 32))
                    .foregroundColor(.cyan)
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            VStack(spacing: 12) {
                HStack {
                    Label("Brillo", systemImage: "sun.max")
                        .font(.system(size: 12, weight: .semibold))
                    
                    Spacer()
                    
                    Text("\(entry.brightness)%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.cyan)
                }
                
                ProgressView(value: Double(entry.brightness) / 100)
                    .tint(.cyan)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Label("Efecto Actual", systemImage: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                    
                    Spacer()
                }
                
                Text(entry.currentEffect)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.cyan)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.cyan.opacity(0.1))
                    .cornerRadius(8)
            }
            
            HStack(spacing: 8) {
                Button(intent: OpenAppIntent()) {
                    Label("Abrir", systemImage: "arrow.right")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.cyan)
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(#colorLiteral(red: 0.1, green: 0.1, blue: 0.15, alpha: 1)))
        .cornerRadius(12)
    }
}

// MARK: - Widget Bundle
@main
struct LEDWidgetBundle: WidgetBundle {
    var body: some Widget {
        LEDWidget()
    }
}

struct LEDWidget: Widget {
    let kind: String = "com.ledcar.widget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LEDWidgetProvider()) { entry in
            if #available(iOS 17, *) {
                LEDWidgetView(entry: entry)
                    .containerBackground(.fill, for: .widget)
            } else {
                LEDWidgetView(entry: entry)
                    .padding()
                    .background(Color(#colorLiteral(red: 0.1, green: 0.1, blue: 0.15, alpha: 1)))
            }
        }
        .configurationDisplayName("LED CAR Control")
        .description("Control rápido de tus luces LED del auto")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - App Intent
struct OpenAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Abrir App"
    static var description = IntentDescription("Abre la app LED CAR Control")
    
    func perform() async throws -> some IntentResult {
        // Abrir app
        return .result()
    }
}

#Preview("Small Widget", as: .systemSmall) {
    LEDWidget()
} preview: {
    LEDWidgetView(entry: LEDWidgetEntry(
        date: .now,
        deviceName: "LED CAR 01",
        isConnected: true,
        brightness: 75,
        currentEffect: "Breathing"
    ))
}

#Preview("Medium Widget", as: .systemMedium) {
    LEDWidget()
} preview: {
    LEDWidgetView(entry: LEDWidgetEntry(
        date: .now,
        deviceName: "LED CAR 01",
        isConnected: true,
        brightness: 85,
        currentEffect: "Gradient RGB"
    ))
}

#Preview("Large Widget", as: .systemLarge) {
    LEDWidget()
} preview: {
    LEDWidgetView(entry: LEDWidgetEntry(
        date: .now,
        deviceName: "LED CAR 01",
        isConnected: true,
        brightness: 90,
        currentEffect: "Persecución"
    ))
}
