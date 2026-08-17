//
//  LandingView.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

import SwiftUI

struct LandingView: View {
    var onFinished: () -> Void

    @State private var query = ""
    @State private var isWorking = false
    @State private var message = ""
    @State private var leagues: [LeagueSummary] = []
    @State private var foundUser: SleeperUser?

    private let controller = LeaguesController()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Draft")
                            .font(.largeTitle.weight(.bold))
                        Text("Enter a Sleeper username or paste a league ID. If you just want to look around, browse Wizards 2026.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)

                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Username or league ID", text: $query)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(.username)
                            .submitLabel(.go)
                            .onSubmit {
                                Task { await continueWithQuery() }
                            }
                            .padding(16)
                            .draftGlass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .accessibilityLabel("Sleeper username or league ID")

                        Button {
                            Task { await continueWithQuery() }
                        } label: {
                            Text("Continue")
                                .frame(maxWidth: .infinity)
                        }
                        .draftProminentButton()
                        .disabled(trimmedQuery.isEmpty || isWorking)
                        .accessibilityHint("Looks up this Sleeper username or league ID.")

                        Button("Browse Wizards 2026") {
                            browseDefault()
                        }
                        .frame(maxWidth: .infinity)
                        .disabled(isWorking)
                        .accessibilityHint("Opens the default Wizards league without signing in.")
                    }

                    if !leagues.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Choose a league")
                                .font(.headline)
                            ForEach(leagues) { league in
                                Button {
                                    finish(league: league)
                                } label: {
                                    leagueRow(league)
                                }
                                .disabled(isWorking)
                                .accessibilityLabel("\(league.name), \(league.season), \(league.statusLabel), \(league.totalRosters) teams")
                            }
                        }
                    }

                    if !message.isEmpty {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(24)
            }
            .background(Color(.systemBackground))
            .scrollDismissesKeyboard(.interactively)
            .overlay {
                if isWorking {
                    ProgressView()
                        .controlSize(.large)
                        .padding(20)
                        .draftGlass(in: Circle(), interactive: true)
                }
            }
        }
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func leagueRow(_ league: LeagueSummary) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(league.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("\(league.season) · \(league.statusLabel) · \(league.totalRosters) teams")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .draftGlass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func continueWithQuery() async {
        let trimmed = trimmedQuery
        guard !trimmed.isEmpty else { return }

        isWorking = true
        message = ""
        leagues = []
        foundUser = nil

        if let user = try? await controller.fetchUser(trimmed), !user.userID.isEmpty {
            foundUser = user
            SleeperConfig.remember(user)
        }

        do {
            let found = try await controller.searchLeagues(query: trimmed)
            if found.count == 1 {
                finish(league: found[0])
                return
            } else if found.isEmpty {
                message = foundUser == nil
                    ? "No leagues found. Use a Sleeper username, paste a league ID, or browse Wizards 2026."
                    : "No NFL leagues for that account in the last few seasons. Choose Wizards 2026 to browse, or paste a league ID."
            } else {
                leagues = found
                message = "Pick the league to open."
            }
        } catch {
            message = "Could not reach Sleeper. Try again, or browse Wizards 2026."
        }

        isWorking = false
    }

    private func browseDefault() {
        finish(
            league: LeagueSummary(
                leagueID: SleeperConfig.defaultLeagueID,
                name: "Wizards",
                season: "2026"
            )
        )
    }

    private func finish(league: LeagueSummary) {
        SavedLeagues.remember(league)
        if let foundUser {
            SleeperConfig.remember(foundUser)
        }
        SleeperConfig.completeOnboarding(leagueID: league.leagueID)
        onFinished()
    }
}

#Preview("Landing light") {
    LandingView(onFinished: {})
}

#Preview("Landing dark") {
    LandingView(onFinished: {})
        .preferredColorScheme(.dark)
}

#Preview("Landing large type") {
    LandingView(onFinished: {})
        .dynamicTypeSize(.accessibility2)
}