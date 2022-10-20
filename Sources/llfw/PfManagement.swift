//
//  pf management tools
//
//  Created by Jim Zajkowski on 8/24/22.
//

import Foundation
import ArgumentParser

let tokenPath = configPath + "/pfReferenceToken"

let pfConfigFile = "/etc/pf.conf"
let pfctl = "/sbin/pfctl"

extension LLFW {

    static func reloadPfRules() throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: pfctl)
        task.arguments = ["-f", pfConfigFile]

        try task.run()
        task.waitUntilExit()
    }

    static func retainPf() throws {
        // first try a release
        try releasePf()

        let task = Process()
        task.executableURL = URL(fileURLWithPath: pfctl)
        task.arguments = ["-E"]

        let outPipe = Pipe()
        task.standardError = outPipe

        try task.run()
        task.waitUntilExit()

        // process the output, we're looking for the Token : [digits] line.
        let fileHandle = outPipe.fileHandleForReading
        let data = fileHandle.readDataToEndOfFile()
        guard let outputString = String(data: data, encoding: .utf8) else {
            print("llfw: pf enabled, but unable to decode output to find the retain token")
            throw ExitCode(-1)
        }

        guard let startColon = outputString.range(of: " : ") else {
            print("llfw: pf enabled, but unable to find ' : ' in output")
            print("llfw: actual output received was: ")
            print(outputString)
            throw ExitCode(-1)
        }

        let tokenCode = outputString[startColon.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)

        // save the token code
        try tokenCode.write(toFile: tokenPath, atomically: true, encoding: .utf8)
    }

    static func releasePf() throws {
        guard let token = try retainToken() else {
            print("No token file \(tokenPath), nothing to release.")
            return
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: pfctl)
        task.arguments = ["-X", token]

        try task.run()
        task.waitUntilExit()

        try FileManager.default.removeItem(atPath: tokenPath)
    }

    static func retainToken() throws -> String? {
        if FileManager.default.fileExists(atPath: tokenPath) == false {
            return nil
        }

        let tokenCode = try String(contentsOfFile: tokenPath)

        return tokenCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func addIncludeToPfConf(verbose: Bool = false) throws {
        let includeLine = "include \"\(anchorFile)\""

        // read pf config file
        guard var pfConf = try? String.init(contentsOfFile: pfConfigFile) else {
            print("Couldn't read \(pfConfigFile)")
            throw ExitCode.init(1)
        }

        // see if our conf file even exists
        guard FileManager.default.fileExists(atPath: anchorFile) else {
            print("llfw: edu.umich.pf.conf missing")
            throw ExitCode.init(1)
        }

        if pfConf.contains(includeLine) {
            if verbose {
                print("llfw: \(pfConfigFile) already has \(includeLine) - done")
            }
            return
        } else {
            pfConf.append("# umich.edu low level firewall\n")
            pfConf.append(includeLine + "\n")
        }

        do {
            try pfConf.write(toFile: pfConfigFile, atomically: true, encoding: .utf8)
        } catch {
            print("couldn't write: \(error)")
            throw ExitCode.init(2)
        }
    }

    static func removeIncludeFromPfConf(verbose: Bool = false) throws {

        // read pf config file
        guard let pfConf = try? String.init(contentsOfFile: pfConfigFile) else {
            print("Couldn't read \(pfConfigFile)")
            throw ExitCode.init(1)
        }

        // split it out
        var lines = pfConf.components(separatedBy: "\n")

        // find our guard
        let includeLine = "include \"\(anchorFile)\""
        if let includeIndex = lines.firstIndex(of: includeLine) {
            lines.remove(at: includeIndex)
        }

        // also remove any header line
        let guardLine = "# umich.edu low level firewall"
        if let headerLine = lines.firstIndex(of: guardLine) {
            lines.remove(at: headerLine)
        }

        // put humpty dumpy back together
        let newContents = lines.joined(separator: "\n")

        do {
            try newContents.write(toFile: pfConfigFile, atomically: true, encoding: .utf8)
        } catch {
            print("couldn't write: \(error)")
            throw ExitCode.init(2)
        }
    }

}
