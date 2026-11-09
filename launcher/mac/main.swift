// SPDX-License-Identifier: MIT
import AppKit
import Foundation

final class BuilderDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!
    let folder = NSTextField(string: "")
    let performance = NSButton(checkboxWithTitle: "Prefer the lighter Zelda performance preset (960×540, upscaled)", target: nil, action: nil)
    let log = NSTextView()
    let status = NSTextField(labelWithString: "Choose a folder containing your own game dump.")
    let build = NSButton(title: "Build My Local Game", target: nil, action: nil)
    let choose = NSButton(title: "Choose Game Folder…", target: nil, action: nil)
    let reveal = NSButton(title: "Show Private Output", target: nil, action: nil)
    var process: Process?
    var output: URL?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        let item = NSMenuItem()
        let appMenu = NSMenu()
        let creditsItem = NSMenuItem(title: "Credits & Licences…", action: #selector(showCredits), keyEquivalent: "")
        creditsItem.target = self
        appMenu.addItem(creditsItem)
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit GreenKid-MV", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.submenu = appMenu
        menu.addItem(item)
        NSApp.mainMenu = menu
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 840, height: 620), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "GreenKid-MV — Local Game Builder"
        window.delegate = self
        window.minSize = NSSize(width: 720, height: 560)
        let title = NSTextField(labelWithString: "GreenKid-MV")
        title.font = .boldSystemFont(ofSize: 25)
        let subtitle = NSTextField(wrappingLabelWithString: "A Mac builder powered by nxnative. No game, console keys, saves or game shaders are included. Your game is built locally and must stay private.")
        folder.placeholderString = "Your game folder stays outside the source repository"
        folder.isEditable = false
        choose.target = self; choose.action = #selector(chooseFolder)
        build.target = self; build.action = #selector(startBuild)
        reveal.target = self; reveal.action = #selector(showOutput); reveal.isEnabled = false
        performance.state = .on
        let row = NSStackView(views: [folder, choose]); row.orientation = .horizontal
        folder.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let buttons = NSStackView(views: [build, reveal]); buttons.orientation = .horizontal
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        log.isEditable = false; log.isSelectable = true
        log.frame = NSRect(x: 0, y: 0, width: 780, height: 240)
        log.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        log.autoresizingMask = [.width]; log.isVerticallyResizable = true
        log.textContainer?.widthTracksTextView = true
        scroll.documentView = log
        let credits = NSTextField(wrappingLabelWithString: "Engine: seedds / nxnative · Ocarina fork: cheemu21 / kid-with-sword-remake · Full contributors and licences are included under Documentation.")
        credits.font = .systemFont(ofSize: 11)
        let stack = NSStackView(views: [title, subtitle, row, performance, buttons, status, scroll, credits])
        stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 13
        stack.translatesAutoresizingMaskIntoConstraints = false
        let content = window.contentView!
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -24),
            row.widthAnchor.constraint(equalTo: stack.widthAnchor),
            scroll.widthAnchor.constraint(equalTo: stack.widthAnchor),
            scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 240),
            subtitle.widthAnchor.constraint(equalTo: stack.widthAnchor),
            credits.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
        window.center(); window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true; panel.canChooseFiles = false
        panel.canCreateDirectories = false; panel.allowsMultipleSelection = false
        panel.message = "Choose your own dump folder, outside any Git repository."
        if panel.runModal() == .OK, let url = panel.url { folder.stringValue = url.path }
    }

    func append(_ text: String) {
        log.textStorage?.append(NSAttributedString(string: text, attributes: [.foregroundColor: NSColor.textColor, .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)]))
        log.scrollToEndOfDocument(nil)
    }

    @objc func startBuild() {
        guard process == nil else { return }
        guard !folder.stringValue.isEmpty else { status.stringValue = "Choose your game folder first."; return }
        guard let resources = Bundle.main.resourceURL else { status.stringValue = "The app resources are missing."; return }
        let script = resources.appendingPathComponent("engine/scripts/greenkid_build.sh")
        guard FileManager.default.fileExists(atPath: script.path) else { status.stringValue = "Builder files are missing; use a complete release archive."; return }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = [script.path, "--build", folder.stringValue, performance.state == .on ? "performance" : "normal"]
        let pipe = Pipe()
        task.standardOutput = pipe; task.standardError = pipe
        task.standardInput = FileHandle.nullDevice
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { handle.readabilityHandler = nil; return }
            let text = String(decoding: data, as: UTF8.self)
            DispatchQueue.main.async { self?.append(text) }
        }
        task.terminationHandler = { [weak self] finished in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.process = nil; self.build.isEnabled = true; self.choose.isEnabled = true
                self.status.stringValue = finished.terminationStatus == 0 ? "Local build ready. Keep the resulting game app private." : "Build stopped. The log above explains what to fix."
                self.reveal.isEnabled = self.output.map { FileManager.default.fileExists(atPath: $0.path) } ?? false
            }
        }
        output = URL(fileURLWithPath: folder.stringValue).appendingPathComponent("GreenKid-MV-local")
        log.string = ""; status.stringValue = "Building from your files. The first full build can take a long time."
        build.isEnabled = false; choose.isEnabled = false; reveal.isEnabled = false
        do { try task.run(); process = task } catch {
            build.isEnabled = true; choose.isEnabled = true
            status.stringValue = "Could not start the builder: \(error.localizedDescription)"
        }
    }

    @objc func showOutput() { if let url = output { NSWorkspace.shared.open(url) } }
    @objc func showCredits() {
        if let url = Bundle.main.resourceURL?.appendingPathComponent("Documentation/CREDITS.md") { NSWorkspace.shared.open(url) }
    }
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if process != nil { _ = applicationShouldTerminate(NSApp); return false }
        return true
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard process != nil else { return .terminateNow }
        let alert = NSAlert()
        alert.messageText = "A local build is still running"
        alert.informativeText = "Keep GreenKid-MV open until it finishes. Closing the window does not cancel the engine's compiler jobs."
        alert.addButton(withTitle: "Keep Building")
        alert.runModal()
        return .terminateCancel
    }
}

if CommandLine.arguments.contains("--self-check") {
    let resources = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Resources")
    let required = ["engine/LICENSE", "engine/UPSTREAM-REVISION", "engine/scripts/greenkid_build.sh", "engine/scripts/build_ipa_from_nsp.py", "Documentation/CREDITS.md"]
    let missing = required.filter { !FileManager.default.fileExists(atPath: resources.appendingPathComponent($0).path) }
    if !missing.isEmpty { fputs("Missing builder resources: \(missing.joined(separator: ", "))\n", stderr); exit(1) }
    print("GreenKid-MV builder resources verified; no game is required for this check.")
    exit(0)
}
let application = NSApplication.shared
let delegate = BuilderDelegate()
application.setActivationPolicy(.regular)
application.delegate = delegate
application.run()
