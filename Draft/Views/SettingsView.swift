//
//  SettingsView.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var manager: ContentViewController
    @AppStorage("sleeperAlertsEnabled", store: AppGroup.defaults) private var alertsEnabled = false

    var body: some View {
        Form {
            Section {
                NavigationLink {
                    LeaguesView(manager: manager)
                } label: {
                    settingsRow(
                        title: "Leagues",
                        detail: manager.name.isEmpty ? SleeperConfig.leagueID : manager.name
                    )
                }
                .accessibilityLabel("Leagues")
                .accessibilityValue(manager.name.isEmpty ? SleeperConfig.leagueID : manager.name)
            } header: {
                Text("League")
            }

            Section {
                NavigationLink {
                    FeedbackSettingsView()
                } label: {
                    settingsRow(title: "Feedback", detail: "Bugs and enhancements")
                }
                .accessibilityHint("Opens the form to send a bug or enhancement.")

                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    settingsRow(title: "Notifications", detail: alertsEnabled ? "On" : "Off")
                }
                .accessibilityValue(alertsEnabled ? "On" : "Off")
            }

            Section("About") {
                LabeledContent("Version", value: FeedbackRequest.appVersion)
                LabeledContent("League") {
                    Text(SleeperConfig.leagueID)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    private func settingsRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct FeedbackSettingsView: View {
    @State private var kind: FeedbackKind = .bug
    @State private var title = ""
    @State private var details = ""
    @Environment(\.openURL) private var openURL

    private var request: FeedbackRequest {
        FeedbackRequest(kind: kind, title: title, details: details)
    }

    private var canCompose: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canSubmit: Bool {
        canCompose && FeedbackRequest.hasDestination
    }

    var body: some View {
        Form {
            Section {
                Picker("Type", selection: $kind) {
                    ForEach(FeedbackKind.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Feedback type")

                TextField("Title", text: $title)
                    .textInputAutocapitalization(.sentences)
                    .accessibilityLabel("Feedback title")

                TextField("What happened, or what you want", text: $details, axis: .vertical)
                    .lineLimit(5...12)
                    .textInputAutocapitalization(.sentences)
                    .accessibilityLabel("Feedback details")
            } footer: {
                Text(
                    FeedbackRequest.hasDestination
                        ? "Submit opens Mail to the Draft feedback address. Share sends the same text in Messages, Mail, or elsewhere."
                        : "Submit is off until a feedback email is added. Share still works if you want to send this another way."
                )
            }

            Section {
                Button("Submit") {
                    if let url = request.mailURL {
                        openURL(url)
                    }
                }
                .disabled(!canSubmit)
                .accessibilityHint(
                    FeedbackRequest.hasDestination
                        ? "Opens Mail with this \(kind.title.lowercased())."
                        : "Feedback email is not set up yet."
                )

                ShareLink(item: request.shareText) {
                    Label("Share feedback", systemImage: "square.and.arrow.up")
                }
                .disabled(!canCompose)
            }
        }
        .navigationTitle("Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
    }
}

private struct NotificationSettingsView: View {
    @AppStorage("sleeperAlertsEnabled", store: AppGroup.defaults) private var alertsEnabled = false

    private var alertsBinding: Binding<Bool> {
        Binding(
            get: { alertsEnabled },
            set: { newValue in
                if newValue {
                    Task {
                        let allowed = await LeagueAlerts.requestAccess()
                        alertsEnabled = allowed
                    }
                } else {
                    alertsEnabled = false
                }
            }
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle("League alerts", isOn: alertsBinding)
            } footer: {
                Text("Local notifications when your team wins or a rostered player’s injury status changes. Turn this on and allow alerts. Remote push from a server needs a current Apple Developer membership.")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum FeedbackKind: String, CaseIterable, Identifiable {
    case bug
    case enhancement

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bug: return "Bug"
        case .enhancement: return "Enhancement"
        }
    }
}

struct FeedbackRequest {
    var kind: FeedbackKind
    var title: String
    var details: String

    /// Set this to a real inbox when one exists. Empty keeps Submit inactive.
    static let destinationEmail = ""

    static var hasDestination: Bool {
        !destinationEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDetails: String {
        details.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var shareText: String {
        var lines = ["[\(kind.title)] \(trimmedTitle)"]
        if !trimmedDetails.isEmpty {
            lines.append("")
            lines.append(trimmedDetails)
        }
        lines.append("")
        lines.append(contentsOf: environmentLines)
        return lines.joined(separator: "\n")
    }

    var mailURL: URL? {
        guard Self.hasDestination else { return nil }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Self.destinationEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "[\(kind.title)] \(trimmedTitle)"),
            URLQueryItem(name: "body", value: shareText)
        ]
        return components.url
    }

    private var environmentLines: [String] {
        [
            "Draft \(Self.appVersion)",
            ProcessInfo.processInfo.operatingSystemVersionString,
            "League \(SleeperConfig.leagueID)"
        ]
    }
}

#Preview("Settings light") {
    NavigationStack {
        SettingsView(manager: ContentViewController())
    }
}

#Preview("Settings dark") {
    NavigationStack {
        SettingsView(manager: ContentViewController())
    }
    .preferredColorScheme(.dark)
}

#Preview("Settings large type") {
    NavigationStack {
        SettingsView(manager: ContentViewController())
    }
    .dynamicTypeSize(.accessibility2)
}
