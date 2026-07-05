import SwiftUI

struct HomeView: View {
    @State private var showStartReview = false
    @State private var showConsumeBottle = false
    @StateObject private var statsViewModel = HomeStatsViewModel()

    private let columns = [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        NavigationLink {
                            WineListView()
                        } label: {
                            HomeTile(title: "My Wine Cellar", systemImage: "wineglass.fill", color: .accentColor)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showConsumeBottle = true
                        } label: {
                            HomeTile(title: "Drink a Bottle", systemImage: "wineglass", color: .red)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showStartReview = true
                        } label: {
                            HomeTile(title: "Start a Review", systemImage: "star.fill", color: .orange)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            WineSearchView()
                        } label: {
                            HomeTile(title: "Wine Search", systemImage: "magnifyingglass", color: .indigo)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ReviewOverviewView()
                        } label: {
                            HomeTile(title: "Review Overview", systemImage: "list.bullet.rectangle.portrait", color: .teal)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            StatisticsView()
                        } label: {
                            HomeTile(title: "Statistics", systemImage: "chart.bar.fill", color: .green)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                }

                statsBar
            }
            .navigationTitle("Wine Cellar")
            .sheet(isPresented: $showStartReview) {
                StartReviewView {}
            }
            .sheet(isPresented: $showConsumeBottle) {
                ConsumeBottleView {
                    Task { await statsViewModel.load() }
                }
            }
            .task {
                await statsViewModel.load()
            }
        }
    }

    private var statsBar: some View {
        HStack(spacing: 0) {
            HomeStatItem(
                value: "\(statsViewModel.totalBottles)",
                label: "Bottles in stock",
                systemImage: "wineglass.fill",
                color: .accentColor
            )
            Divider().frame(height: 36)
            HomeStatItem(
                value: "\(statsViewModel.drunkLast30Days)",
                label: "Drunk (30 days)",
                systemImage: "calendar",
                color: .orange
            )
        }
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
    }
}

private struct HomeStatItem: View {
    let value: String
    let label: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 20, weight: .bold))
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct HomeTile: View {
    let title: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 64, height: 64)
                Image(systemName: systemImage)
                    .font(.system(size: 26))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.95, contentMode: .fill)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(color.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}

#Preview {
    HomeView()
}
