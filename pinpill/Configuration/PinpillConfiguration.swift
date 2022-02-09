//
//  File.swift
//  pinpill
//
//  Created by Mansfield Mark on 6/15/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation

class PinpillConfiguration: Codable {
    enum PinpillConfigurationError: Error {
        case missingRequiredConfig(String)
        case invalidConfig(String)
    }

    static let kDefaultHeadless = true
    let headless: Bool
    let maxSims: Int
    static let kDefaultMaxRetries = 2
    let maxRetries: Int
    static let kDefaultNumTestRuns = 1
    let numTestRuns: Int
    let device: String
    let runtime: String
    let testTasks: [TestTaskConfig]
    let environment: [String: String]
    let urls: PinpillURLs
    static let kDefaultRecordVideo = true
    let recordVideo: Bool
    static let kDefaultKeepPassingTestVideos = false
    let keepPassingTestVideos: Bool
    static let kDefaultRecordScreenshot = true
    let recordScreenshot: Bool
    static let kDefaultTaskTimeoutSeconds = 300
    let taskTimeoutSeconds: Int

    static func fromRawConfig(baseConfig: PinpillArguments?, overrideConfig: PinpillArguments) throws -> PinpillConfiguration {
        let headless = baseConfig?.headless ?? overrideConfig.headless ?? kDefaultHeadless
        let recordVideo = baseConfig?.recordVideo ?? overrideConfig.recordVideo ?? kDefaultRecordVideo
        let keepPassingTestVideos = baseConfig?.keepPassingTestVideos ?? overrideConfig.keepPassingTestVideos ?? kDefaultKeepPassingTestVideos
        let recordScreenshot = baseConfig?.recordScreenshot ?? overrideConfig.recordScreenshot ?? kDefaultRecordScreenshot
        let maxRetries = overrideConfig.maxRetries ?? baseConfig?.maxRetries ?? kDefaultMaxRetries
        let numTestRuns = overrideConfig.numTestRuns ?? baseConfig?.numTestRuns ?? kDefaultNumTestRuns
        let taskTimeoutSeconds = overrideConfig.taskTimeoutSeconds ?? baseConfig?.taskTimeoutSeconds ?? kDefaultTaskTimeoutSeconds
        
        guard let maxSims = overrideConfig.maxSims ?? baseConfig?.maxSims else {
            throw PinpillConfigurationError.missingRequiredConfig("max sims")
        }

        guard let device = overrideConfig.device ?? baseConfig?.device else {
            throw PinpillConfigurationError.missingRequiredConfig("device")
        }

        guard let runtime = overrideConfig.runtime ?? baseConfig?.runtime else {
            throw PinpillConfigurationError.missingRequiredConfig("runtime")
        }

        guard let testTasks = overrideConfig.testTasks ?? baseConfig?.testTasks else {
            throw PinpillConfigurationError.missingRequiredConfig("test tasks")
        }

        let environment = (baseConfig?.environment ?? [:]).merging(overrideConfig.environment ?? [:]) {
            Logger.warning(msg: "Found environment conflict between config and CLI: \($0) and \($1). Preferring CLI: \($1)")
            return $1
        }

        guard let appPath = overrideConfig.appPath ?? baseConfig?.appPath else {
            throw PinpillConfigurationError.missingRequiredConfig("app path")
        }

        guard let testAppPath = overrideConfig.testAppPath ?? baseConfig?.testAppPath else {
            throw PinpillConfigurationError.missingRequiredConfig("test app path")
        }

        guard let xcTestRunPath = overrideConfig.xcTestRunPath ?? baseConfig?.xcTestRunPath else {
            throw PinpillConfigurationError.missingRequiredConfig("xctestrun path")
        }

        guard let bpPath = overrideConfig.bpPath ?? baseConfig?.bpPath else {
            throw PinpillConfigurationError.missingRequiredConfig("bp path")
        }

        guard let outputPath = overrideConfig.outputPath ?? baseConfig?.outputPath else {
            throw PinpillConfigurationError.missingRequiredConfig("output path")
        }

        guard let simulatorPreferencesPath = overrideConfig.simulatorPreferencesPath ?? baseConfig?.simulatorPreferencesPath else {
            throw PinpillConfigurationError.missingRequiredConfig("simulator preferences path")
        }

        let appBundleURL = URL(fileURLWithPath: appPath)
        let testBundleURL = URL(fileURLWithPath: testAppPath)
        let xcTestRunURL = URL(fileURLWithPath: xcTestRunPath)
        let bpURL = URL(fileURLWithPath: bpPath)
        let outputURL = URL(fileURLWithPath: outputPath)
        let simulatorPreferencesURL = URL(fileURLWithPath: simulatorPreferencesPath)

        let shell = Shell()
        let xcodeTask = shell.launchWaitAndGetOutput(cmd: Shell.kBinXCodeSelect, args: ["-print-path"])
        Logger.verbose(msg: "Found xcode path: \(xcodeTask.stdOut)")
        let xcodeURL = URL(fileURLWithPath: xcodeTask.stdOut.trimmingCharacters(in: .whitespacesAndNewlines))

        let urls = try PinpillURLs(
            fileManager: FileManager.default,
            testBundleURL: testBundleURL,
            appBundleURL: appBundleURL,
            xcTestRunURL: xcTestRunURL,
            xcodeURL: xcodeURL,
            bpURL: bpURL,
            outputURL: outputURL,
            simulatorPreferencesURL: simulatorPreferencesURL
        )
        return try PinpillConfiguration(
            headless: headless,
            maxSims: maxSims,
            maxRetries: maxRetries,
            numTestRuns: numTestRuns,
            device: device,
            runtime: runtime,
            testTasks: testTasks,
            environment: environment,
            urls: urls,
            recordVideo: recordVideo,
            keepPassingTestVideos: keepPassingTestVideos,
            recordScreenshot: recordScreenshot,
            taskTimeoutSeconds: taskTimeoutSeconds
        )
    }

    init(
        headless: Bool,
        maxSims: Int,
        maxRetries: Int,
        numTestRuns: Int,
        device: String,
        runtime: String,
        testTasks: [TestTaskConfig],
        environment: [String: String],
        urls: PinpillURLs,
        recordVideo: Bool,
        keepPassingTestVideos: Bool,
        recordScreenshot: Bool,
        taskTimeoutSeconds: Int
    ) throws {
        self.headless = headless
        if (maxSims <= 0) {
            throw PinpillConfigurationError.invalidConfig("maxSims must be a positive integer. Got \(maxSims)")
        }
        self.maxSims = maxSims
        
        if (maxRetries < 0) {
            throw PinpillConfigurationError.invalidConfig("numTestRuns must be a non-negative integer. Got \(maxRetries)")
        }
        self.maxRetries = maxRetries
        
        if (numTestRuns <= 0) {
            throw PinpillConfigurationError.invalidConfig("numTestRuns must be a positive integer. Got \(numTestRuns)")
        }
        
        if (taskTimeoutSeconds <= 0) {
            throw PinpillConfigurationError.invalidConfig("taskTimeoutSeconds must be positive")
        }
        self.taskTimeoutSeconds = taskTimeoutSeconds
        
        self.numTestRuns = numTestRuns
        self.device = device
        self.runtime = runtime
        
        if (testTasks.isEmpty) {
            throw PinpillConfigurationError.invalidConfig("testTasks must be non-empty.")
        }
        self.testTasks = testTasks
        
        self.environment = environment
        self.urls = urls
        self.recordVideo = recordVideo
        self.keepPassingTestVideos = keepPassingTestVideos
        self.recordScreenshot = recordScreenshot
    }
}
