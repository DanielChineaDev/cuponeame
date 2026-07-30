import SwiftUI

/// Historial de canjeos agrupado por día, del más reciente al más antiguo.
struct HistoryScreen: View {
    @Environment(CouponStore.self) private var store

    private var grouped: [(day: Date, items: [Redemption])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: store.redemptions) {
            calendar.startOfDay(for: $0.date)
        }
        return groups
            .map { (day: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        Group {
            if store.redemptions.isEmpty {
                VStack(spacing: 14) {
                    BrandMark(width: 130)
                        .padding(.bottom, 10)
                    Text("Sin canjes todavía")
                        .font(.title3.bold())
                    Text("Cuando canjees un cupón aparecerá aquí.")
                        .font(.subheadline)
                        .foregroundStyle(CuponColors.subtleText)
                }
            } else {
                List {
                    Section {
                        Label("**\(store.redemptions.count)** momentos canjeados 💜",
                              systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                LinearGradient(colors: [CuponColors.brandPurple, CuponColors.brandPink],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: RoundedRectangle(cornerRadius: 20))
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                    ForEach(grouped, id: \.day) { group in
                        Section(Self.dayTitle(for: group.day)) {
                            ForEach(group.items) { redemption in
                                row(for: redemption)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Historial de canjes")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(for redemption: Redemption) -> some View {
        HStack(spacing: 12) {
            Image(systemName: redemption.categoryIcon)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(CuponColors.brandGradient, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(redemption.title)
                    .font(.body.weight(.medium))
                Text(redemption.category)
                    .font(.caption)
                    .foregroundStyle(CuponColors.subtleText)
            }

            Spacer()

            Text(redemption.date.formatted(date: .omitted, time: .shortened))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(CuponColors.subtleText)
        }
    }

    static func dayTitle(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Hoy" }
        if calendar.isDateInYesterday(day) { return "Ayer" }
        return day.formatted(date: .complete, time: .omitted)
    }
}
