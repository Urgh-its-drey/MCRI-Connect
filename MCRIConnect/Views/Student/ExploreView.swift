import SwiftUI

struct ExploreView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = ExploreViewModel()

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            filterStrip

            ScrollView {
                LazyVStack(spacing: MCRITheme.Spacing.s3) {
                    resultsHeader
                    results
                }
                .padding(.horizontal, MCRITheme.Spacing.screenMargin)
                .padding(.bottom, MCRITheme.Spacing.s6)
            }
            .scrollIndicators(.hidden)
        }
        .mcriScreen()
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: store.searchToRun) { _, search in
            guard let search else { return }
            viewModel.apply(search)
            store.searchToRun = nil
        }
    }

    private var searchBar: some View {
        VStack(spacing: MCRITheme.Spacing.s3) {
            MCRISearchBar(text: $viewModel.query, onSubmit: { viewModel.filtersOpen = false })

            HStack(spacing: MCRITheme.Spacing.s2) {
                MCRIFilterChip(title: "Filters",
                               symbol: viewModel.filtersOpen ? "line.3.horizontal.decrease.circle.fill"
                                                             : "line.3.horizontal.decrease.circle",
                               isSelected: viewModel.hasFilters,
                               trailingCount: viewModel.hasFilters ? viewModel.activeFilterCount : nil) {
                    withAnimation(.easeOut(duration: 0.2)) { viewModel.filtersOpen.toggle() }
                }

                Picker("Sort", selection: $viewModel.sort) {
                    ForEach(InternshipSort.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .tint(MCRITheme.textSecondary)
                .font(.mcriCaption)
                .fixedSize()
                .frame(height: MCRITheme.Metrics.minTapTarget)

                Spacer(minLength: MCRITheme.Spacing.s2)

                MCRILinkButton(title: "Saved (\(viewModel.savedCount))", symbol: "bookmark") {
                    router.go(.savedSearches)
                }
                .fixedSize()
            }
        }
        .padding(.horizontal, MCRITheme.Spacing.screenMargin)
        .padding(.top, MCRITheme.Spacing.s2)
        .padding(.bottom, MCRITheme.Spacing.s3)
        .background(MCRITheme.background)
    }

    @ViewBuilder private var filterStrip: some View {
        if viewModel.filtersOpen {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MCRITheme.Spacing.s2) {
                        ForEach(WorkMode.allCases) { mode in
                            MCRIFilterChip(title: mode.label, symbol: mode.symbol,
                                           isSelected: viewModel.workModes.contains(mode)) {
                                viewModel.toggle(mode)
                            }
                        }
                        MCRIFilterChip(title: "Paid", symbol: "banknote",
                                       isSelected: viewModel.paidOnly) {
                            viewModel.paidOnly.toggle()
                        }
                        MCRIFilterChip(title: "Easy Apply", symbol: "bolt.fill",
                                       isSelected: viewModel.easyApplyOnly) {
                            viewModel.easyApplyOnly.toggle()
                        }
                    }
                    .padding(.horizontal, MCRITheme.Spacing.screenMargin)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MCRITheme.Spacing.s2) {
                        ForEach(SkillCategory.allCases) { category in
                            MCRIFilterChip(title: category.label,
                                           isSelected: viewModel.categories.contains(category)) {
                                viewModel.toggle(category)
                            }
                        }
                        if viewModel.hasFilters {
                            Button("Clear all") { viewModel.reset() }
                                .font(.mcriCaption.weight(.semibold))
                                .foregroundStyle(MCRITheme.blocked)
                                .frame(height: MCRITheme.Metrics.minTapTarget)
                                .padding(.horizontal, MCRITheme.Spacing.s3)
                        }
                    }
                    .padding(.horizontal, MCRITheme.Spacing.screenMargin)
                }
            }
            .padding(.bottom, MCRITheme.Spacing.s3)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    @ViewBuilder private var resultsHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(viewModel.results.count) roles")
                .font(.mcriSection)
                .foregroundStyle(MCRITheme.textPrimary)
            Spacer()
            if viewModel.hasFilters {
                MCRILinkButton(title: "Save search", symbol: "bell.fill") {
                    viewModel.saveCurrentSearch()
                }
            }
        }
        .padding(.top, MCRITheme.Spacing.s2)
    }

    @ViewBuilder private var results: some View {
        if store.isLoading && store.internships.isEmpty {
            MCRICardSkeleton(rows: 3).padding(.top, MCRITheme.Spacing.s2)
        } else if viewModel.results.isEmpty {
            MCRIEmptyState(symbol: "magnifyingglass",
                           title: "No role matches that yet",
                           message: "Widen the filters, or save this search and we will alert you the "
                               + "moment a matching role is posted.",
                           actionTitle: "Save this search") {
                viewModel.saveCurrentSearch()
                viewModel.filtersOpen = false
            }
            .padding(.top, MCRITheme.Spacing.s6)
        } else {
            ForEach(viewModel.results) { role in
                MCRIInternshipCard(role: role,
                                   isSaved: viewModel.isSaved(role.id),
                                   showsApply: false) {
                    router.go(.internship(role.id))
                } onSave: {
                    viewModel.toggleSave(role.internship)
                }
            }
        }
    }
}

struct SavedSearchesView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router

    var body: some View {
        MCRIPage {
            MCRISectionHeader(title: "Saved searches",
                              subtitle: "You get alerted when a new role fits these filters")
            if store.savedSearches.isEmpty {
                MCRIEmptyState(symbol: "bell.slash",
                               title: "Nothing saved",
                               message: "Set filters in Explore and save them here.")
            } else {
                ForEach(store.savedSearches) { search in
                    MCRICard {
                        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(search.label)
                                        .font(.mcriCardTitle)
                                        .foregroundStyle(MCRITheme.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    FlowingChips {
                                        ForEach(search.filters, id: \.self) { filter in
                                            MCRISkillChip(name: filter)
                                        }
                                    }
                                }
                                Spacer(minLength: MCRITheme.Spacing.s2)
                            }

                            Toggle(isOn: Binding(
                                get: { search.alertsEnabled },
                                set: { enabled in
                                    var updated = search
                                    updated.alertsEnabled = enabled
                                    store.saveSearch(updated)
                                })) {
                                HStack(spacing: 6) {
                                    Image(systemName: "bell.fill")
                                        .font(.caption)
                                        .foregroundStyle(MCRITheme.primaryAction)
                                    Text("Daily alerts").font(.mcriCaption)
                                        .foregroundStyle(MCRITheme.textSecondary)
                                }
                            }
                            .tint(MCRITheme.primaryAction)

                            HStack(spacing: MCRITheme.Spacing.s2) {
                                MCRISecondaryButton(title: "Delete", symbol: "trash",
                                                    fullWidth: false, compact: true,
                                                    isDestructive: true) {
                                    store.deleteSearch(search)
                                }
                                Spacer()
                                MCRIButton(title: "Run search", symbol: "magnifyingglass",
                                           fullWidth: false) {
                                    store.searchToRun = search
                                    router.select(tab: 1)
                                }
                            }
                        }
                    }
                }
            }
        }
        .mcriScreen(title: "Saved searches")
    }
}

private struct ExploreViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen { ExploreView() }
}
}

private struct ExploreViewPreview2: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen { SavedSearchesView() }
}
}
