import WidgetKit
import SwiftUI

@main
struct CuponWidgetBundle: WidgetBundle {
    var body: some Widget {
        CuponWidget()
    }
}

struct CuponWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CuponWidget", provider: Provider()) { entry in
            CuponWidgetView(entry: entry)
        }
        .configurationDisplayName("Próximo cupón")
        .description("El siguiente cupón listo para canjear.")
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryCircular, .accessoryRectangular])
    }
}

struct Entry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        Entry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: .now, snapshot: WidgetSnapshot.load() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        // La app recarga el timeline en cada cambio; esto es solo el respaldo
        // para que los cooldowns que venzan se reflejen sin abrir la app.
        let entry = Entry(date: .now, snapshot: WidgetSnapshot.load() ?? .placeholder)
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(1800))))
    }
}

extension WidgetSnapshot {
    static let placeholder = WidgetSnapshot(
        updated: .now, total: 11, available: 9,
        next: NextCoupon(title: "Beso", category: "Romance",
                         categoryIcon: "heart.fill", remainingUses: 3))
}

struct CuponWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: Entry

    // Gradiente de marca (mismos hex que CuponColors en la app).
    private let brand = LinearGradient(
        colors: [Color(red: 0xAF / 255, green: 0x52 / 255, blue: 0xDE / 255),
                 Color(red: 0xFF / 255, green: 0x2D / 255, blue: 0x55 / 255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing)

    var body: some View {
        switch family {
        case .accessoryCircular:
            // Pantalla de bloqueo: anillo con los cupones disponibles.
            Gauge(value: Double(entry.snapshot.available),
                  in: 0...Double(max(entry.snapshot.total, 1))) {
                Image(systemName: "ticket.fill")
            } currentValueLabel: {
                Text("\(entry.snapshot.available)")
                    .font(.headline.bold())
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .containerBackground(for: .widget) { Color.clear }

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Label("Próximo cupón", systemImage: "ticket.fill")
                    .font(.caption2)
                Text(entry.snapshot.next?.title ?? "Nada que canjear")
                    .font(.headline)
                    .lineLimit(1)
                Text("\(entry.snapshot.available) de \(entry.snapshot.total) disponibles")
                    .font(.caption2)
                    .opacity(0.8)
            }
            .containerBackground(for: .widget) { Color.clear }

        default:
            content
                .foregroundStyle(.white)
                .containerBackground(for: .widget) { brand }
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "ticket.fill")
                    .font(.callout)
                Text("Cuponéame")
                    .font(.caption2.bold())
                    .opacity(0.9)
                Spacer()
                if let next = entry.snapshot.next {
                    Image(systemName: next.categoryIcon)
                        .font(.callout)
                        .opacity(0.9)
                }
            }

            Spacer(minLength: 0)

            if let next = entry.snapshot.next {
                Text("Próximo cupón")
                    .font(.caption2)
                    .opacity(0.85)
                Text(next.title)
                    .font(family == .systemSmall ? .headline : .title3.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                if family != .systemSmall {
                    Text("\(next.category) · \(next.remainingUses) usos restantes")
                        .font(.caption)
                        .opacity(0.85)
                }
            } else {
                Text("Nada que canjear")
                    .font(.headline)
                Text("Todo en espera o agotado")
                    .font(.caption2)
                    .opacity(0.85)
            }

            Spacer(minLength: 0)

            Text("\(entry.snapshot.available) de \(entry.snapshot.total) disponibles")
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.white.opacity(0.22), in: Capsule())
        }
    }
}
