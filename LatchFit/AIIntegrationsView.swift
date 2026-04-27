import SwiftUI

enum AIProvider: String, CaseIterable, Identifiable {
    case none
    case openAI
    case googleGemini

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "None"
        case .openAI: return "ChatGPT (OpenAI API)"
        case .googleGemini: return "Gemini (Google AI Studio)"
        }
    }

    var helperText: String {
        switch self {
        case .none:
            return "LatchFit will keep using built-in AI behavior."
        case .openAI:
            return "Use your OpenAI API key to send prompts and logging actions through your own account."
        case .googleGemini:
            return "Use your Gemini API key from Google AI Studio for prompts and logging actions."
        }
    }
}

struct AIIntegrationsView: View {
    @AppStorage("ai.provider") private var providerRawValue = AIProvider.none.rawValue
    @AppStorage("ai.apiKey") private var apiKey = ""

    private var selectedProvider: AIProvider {
        get { AIProvider(rawValue: providerRawValue) ?? .none }
        nonmutating set { providerRawValue = newValue.rawValue }
    }

    var body: some View {
        Form {
            Section("Provider") {
                Picker("AI Provider", selection: Binding(
                    get: { selectedProvider },
                    set: { selectedProvider = $0 }
                )) {
                    ForEach(AIProvider.allCases) { provider in
                        Text(provider.title).tag(provider)
                    }
                }
                .pickerStyle(.menu)

                Text(selectedProvider.helperText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if selectedProvider != .none {
                Section("Credentials") {
                    SecureField("API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }

            Section("Important") {
                Text("Consumer app subscriptions (like ChatGPT Plus or Gemini Advanced) cannot be linked directly. LatchFit integrations use provider API keys.")
                    .font(.footnote)
            }
        }
        .navigationTitle("AI Integrations")
    }
}
