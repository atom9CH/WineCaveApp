import SwiftUI

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading statistics…")
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        overviewCard
                        consumptionCard

                        if !viewModel.bottlesByType.isEmpty {
                            breakdownCard(
                                title: "By Type",
                                items: viewModel.bottlesByType.map { (.init($0.type.displayName, $0.count, typeColor($0.type))) }
                            )
                        }

                        if !viewModel.bottlesByStorage.isEmpty {
                            breakdownCard(
                                title: "By Storage",
                                items: viewModel.bottlesByStorage.map {
                                    .init($0.location == .cellar ? "Cellar" : "Home", $0.count, $0.location == .cellar ? .teal : .purple)
                                }
                            )
                        }

                        if !viewModel.topRatedWines.isEmpty {
                            topRatedCard
                        }
                    }
                    .padding(16)
                }
                .background(Color("AppBackground"))
            }
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    private func typeColor(_ type: WineType) -> Color {
        switch type {
        case .red: return .red
        case .white: return .yellow
        case .rose: return .pink
        case .sparkling: return .cyan
        }
    }

    private var overviewCard: some View {
        StatCard(title: "Overview") {
            HStack(spacing: 12) {
                StatTile(value: "\(viewModel.totalBottlesInStock)", label: "Bottles", icon: "wineglass.fill", color: .accentColor)
                StatTile(value: "\(viewModel.totalWinesInStock)", label: "Wines", icon: "square.stack.fill", color: .indigo)
                if let avg = viewModel.averageRating {
                    StatTile(value: String(format: "%.1f", avg), label: "Avg Rating", icon: "star.fill", color: .yellow)
                }
            }
        }
    }

    private var consumptionCard: some View {
        StatCard(title: "Consumption") {
            HStack(spacing: 12) {
                StatTile(value: "\(viewModel.consumedLast30Days)", label: "Last 30 days", icon: "calendar", color: .orange)
                StatTile(value: "\(viewModel.consumedAllTime)", label: "All time", icon: "clock.arrow.circlepath", color: .brown)
            }
        }
    }

    private func breakdownCard(title: String, items: [BreakdownItem]) -> some View {
        StatCard(title: title) {
            VStack(spacing: 10) {
                ForEach(items) { item in
                    HStack {
                        Circle()
                            .fill(item.color)
                            .frame(width: 10, height: 10)
                        Text(item.label)
                            .font(.subheadline)
                        Spacer()
                        Text("\(item.count)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var topRatedCard: some View {
        StatCard(title: "Top Rated") {
            VStack(spacing: 10) {
                ForEach(Array(viewModel.topRatedWines.enumerated()), id: \.element.id) { index, wine in
                    HStack {
                        Text("\(index + 1)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 18)
                        Text(wine.name)
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f ★", wine.rating))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.yellow)
                    }
                }
            }
        }
    }
}

private struct BreakdownItem: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
    let color: Color

    init(_ label: String, _ count: Int, _ color: Color) {
        self.label = label
        self.count = count
        self.color = color
    }
}

private struct StatCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct StatTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 18))
            }
            Text(value)
                .font(.system(size: 18, weight: .bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
