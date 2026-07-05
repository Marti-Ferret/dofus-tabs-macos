import SwiftUI

struct SettingsView: View {
    let windowManager: DofusWindowManager
    let hotkeyStore: HotkeyPreferencesStore
    let onArrangeNow: () -> Void
    let onChanged: () -> Void

    private let languageStore = LanguagePreferenceStore()

    @State private var rows: [DofusWindow] = []
    @State private var launchAtLogin: Bool = LaunchAtLoginManager.isEnabled
    @State private var selectedLanguage: AppLanguage = LanguagePreferenceStore().current
    @State private var showRestartAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            globalHotkeysSection

            Divider()

            languageSection

            Divider()

            Text(L10n.settingsCharactersDetected)
                .font(.headline)

            if rows.isEmpty {
                Text(L10n.settingsNoWindows)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List {
                    ForEach(Array(rows.enumerated()), id: \.element.characterName) { index, window in
                        row(for: window, at: index)
                    }
                }
                .listStyle(.inset)
            }

            Divider()

            Toggle(L10n.settingsLaunchAtLogin, isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { newValue in
                    LaunchAtLoginManager.setEnabled(newValue)
                }

            HStack {
                Button(L10n.settingsArrangeNow) {
                    onArrangeNow()
                }
                Button(L10n.settingsResetHotkeys) {
                    hotkeyStore.resetToDefaults()
                    onChanged()
                }
            }

            Text(L10n.settingsFooterNote)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 400, height: 520)
        .onAppear(perform: reload)
        .alert(L10n.languageRestartTitle, isPresented: $showRestartAlert) {
            Button(L10n.languageRestartNow) {
                languageStore.relaunch()
            }
            Button(L10n.languageRestartLater, role: .cancel) {}
        } message: {
            Text(L10n.languageRestartMessage)
        }
    }

    private var languageSection: some View {
        HStack {
            Text(L10n.settingsLanguageSection)
            Spacer()
            Picker("", selection: $selectedLanguage) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.nativeName).tag(language)
                }
            }
            .labelsHidden()
            .frame(width: 200)
            .onChange(of: selectedLanguage) { newValue in
                languageStore.apply(newValue)
                showRestartAlert = true
            }
        }
    }

    private var globalHotkeysSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.settingsGlobalHotkeys)
                .font(.headline)

            HStack {
                Text(L10n.settingsCycleHotkeyLabel)
                Spacer()
                HotkeyRecorderView(binding: cycleBindingProxy())
            }
            HStack {
                Text(L10n.settingsArrangeHotkeyLabel)
                Spacer()
                HotkeyRecorderView(binding: arrangeBindingProxy())
            }
        }
    }

    private func row(for window: DofusWindow, at index: Int) -> some View {
        let activeIndex = rows
            .filter { !windowManager.isExcluded($0) }
            .firstIndex(where: { $0.characterName == window.characterName })

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(window.characterName)
                if windowManager.isExcluded(window) {
                    Text(L10n.settingsExcludedFromRotation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let activeIndex, activeIndex < 9 {
                HotkeyRecorderView(binding: directBindingProxy(at: activeIndex))
            }

            VStack(spacing: 2) {
                Button(action: { moveUp(index) }) {
                    Image(systemName: "chevron.up")
                }
                .disabled(index == 0)

                Button(action: { moveDown(index) }) {
                    Image(systemName: "chevron.down")
                }
                .disabled(index == rows.count - 1)
            }
            .buttonStyle(.borderless)

            Toggle("", isOn: bindingForActive(window))
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }

    private func reload() {
        windowManager.refresh()
        rows = windowManager.windows
    }

    private func moveUp(_ index: Int) {
        guard index > 0 else { return }
        rows.swapAt(index, index - 1)
        persistOrder()
    }

    private func moveDown(_ index: Int) {
        guard index < rows.count - 1 else { return }
        rows.swapAt(index, index + 1)
        persistOrder()
    }

    private func persistOrder() {
        windowManager.setOrder(rows.map { $0.characterName })
        onChanged()
    }

    private func bindingForActive(_ window: DofusWindow) -> Binding<Bool> {
        Binding(
            get: { !windowManager.isExcluded(window) },
            set: { isActive in
                windowManager.setExcluded(!isActive, for: window)
                onChanged()
            }
        )
    }

    private func cycleBindingProxy() -> Binding<HotkeyBinding> {
        Binding(
            get: { hotkeyStore.cycleBinding },
            set: { newValue in
                hotkeyStore.cycleBinding = newValue
                onChanged()
            }
        )
    }

    private func arrangeBindingProxy() -> Binding<HotkeyBinding> {
        Binding(
            get: { hotkeyStore.arrangeBinding },
            set: { newValue in
                hotkeyStore.arrangeBinding = newValue
                onChanged()
            }
        )
    }

    private func directBindingProxy(at index: Int) -> Binding<HotkeyBinding> {
        Binding(
            get: { hotkeyStore.directBinding(at: index) },
            set: { newValue in
                hotkeyStore.setDirectBinding(newValue, at: index)
                onChanged()
            }
        )
    }
}
