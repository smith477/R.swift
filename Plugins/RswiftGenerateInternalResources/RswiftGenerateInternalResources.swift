//
//  RswiftGenerateInternalResources.swift
//  
//
//  Created by Tom Lokhorst on 2022-10-19.
//

import Foundation
import PackagePlugin

@main
struct RswiftGenerateInternalResources: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }

        let outputDirectoryPath = URL(string: NSTemporaryDirectory())!
            .appendingPathExtension(target.name)

        try FileManager.default.createDirectory(atPath: outputDirectoryPath.absoluteString, withIntermediateDirectories: true)

        let rswiftPath = outputDirectoryPath.appendingPathExtension("R.generated.swift")

        let sourceFiles = target.sourceFiles
            .filter { $0.type == .resource || $0.type == .unknown }
            .map(\.path.string)

        let inputFilesArguments = sourceFiles
            .flatMap { ["--input-files", $0 ] }

        let bundleSource = target.kind == .generic ? "module" : "finder"
        let description = "\(target.kind) module \(target.name)"

        return [
            .buildCommand(
                displayName: "R.swift generate resources for \(description)",
                executable: try context.tool(named: "rswift").path,
                arguments: [
                    "generate", rswiftPath.absoluteString,
                    "--input-type", "input-files",
                    "--bundle-source", bundleSource,
                ] + inputFilesArguments,
                outputFiles: [Path(rswiftPath.absoluteString)]
            ),
        ]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension RswiftGenerateInternalResources: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {

        let resourcesDirectoryPath = URL(string: NSTemporaryDirectory())!
            .appendingPathExtension(target.displayName)
            .appendingPathExtension("Resource")

        try FileManager.default.createDirectory(atPath: resourcesDirectoryPath.absoluteString, withIntermediateDirectories: true)

        let rswiftPath = resourcesDirectoryPath.appendingPathExtension("R.generated.swift")

        let description: String
        if let product = target.product {
            description = "\(product.kind) \(target.displayName)"
        } else {
            description = target.displayName
        }

        return [
            .buildCommand(
                displayName: "R.swift generate resources for \(description)",
                executable: try context.tool(named: "rswift").path,
                arguments: [
                    "generate", rswiftPath.absoluteString,
                    "--target", target.displayName,
                    "--input-type", "xcodeproj",
                    "--bundle-source", "finder",
                ],
                outputFiles: [Path(rswiftPath.absoluteString)]
            ),
        ]
    }
}

#endif
