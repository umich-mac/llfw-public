import Foundation
import ArgumentParser

let configPath = "/Library/Application Support/llfw"
let disabledFlagPath = configPath + "/doNotLoadLLFWRules"

@main
struct LLFW: ParsableCommand {

    static var configuration = CommandConfiguration(
        abstract: "Low Level Firewall",
        discussion: "Manages the low-level on-device firewall.",
        version: "0.9",

        subcommands: [
            Enable.self,
            Disable.self,
            Engage.self
        ]
    )

    public func run() throws {
        print(LLFW.helpMessage())
    }

    static func isDisabled() -> Bool {
        return FileManager.default.fileExists(atPath: disabledFlagPath)
    }

    static func isEnabled() -> Bool {
        return !isDisabled()
    }

    static func requireRoot() throws {
        guard geteuid() == 0 else {
            print("llfw: sorry, must be root")
            throw ExitCode.init(1)
        }
    }
}

extension LLFW {
    struct Enable: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "enable",
            abstract: "Enables firewall.",
            shouldDisplay: true)

        func run() throws {
            try requireRoot()

            if isDisabled() {
                try FileManager.default.removeItem(atPath: disabledFlagPath)
            }

            print("llfw: enabled but not loaded - use `llfw engage` to load now")
        }
    }
}

extension LLFW {
    struct Disable: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "disable",
            abstract: "Disables firewall.",
            shouldDisplay: true)

        func run() throws {
            try requireRoot()
            try removeIncludeFromPfConf()
            try reloadPfRules() // remove our rules
            try releasePf()     // remove our retain on pf

            if isEnabled() {
                FileManager.default.createFile(atPath: disabledFlagPath, contents: nil)
            }

            print("llfw: disabled")
        }
    }
}

extension LLFW {
    struct Engage: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "engage",
            abstract: "Loads LLFW rules into pf.",
            shouldDisplay: true)

        func run() throws {
            if isDisabled() {
                print("llfw: disabled; won't load. use `llfw enable` to re-enable.")
                return
            }

            try requireRoot()
            try writePfRules()
            try addIncludeToPfConf()
            try retainPf()
            try reloadPfRules()

            print("llfw: engaged")
        }
    }
}

