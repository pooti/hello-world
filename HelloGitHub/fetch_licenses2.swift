#!/usr/bin/env xcrun swift

import UIKit

extension String {
    func stringByDeletingLastPathComponent() -> String {
        let transformString: NSString = NSString(string: self)
        return transformString.stringByDeletingLastPathComponent
    }
    func stringByAppendingPathComponent(str: String) -> String {
        let transformString: NSString = NSString(string: self)
        return transformString.stringByAppendingPathComponent(str)
    }
}

func projectDirectory() -> String {
    let sourceDirectory = Process.arguments[1]
    return sourceDirectory
}

func carthageDirectory() -> String {
    let path = projectDirectory()
    let carthagePath = path.stringByAppendingPathComponent("Carthage")
    return carthagePath
}

func podsDirectory() -> String {
    let path = projectDirectory()
    let carthagePath = path.stringByAppendingPathComponent("Pods")
    return carthagePath
}

func podsLicenseFile() -> String {
    let podsDir = podsDirectory()
    let podsLicenseFile = podsDir.stringByAppendingPathComponent("Target Support Files/Pods/Pods-acknowledgements.plist")
    return podsLicenseFile
}

func carthageCheckoutsItems() throws -> [String] {
    let carthagePath = carthageDirectory()
    let checkoutsPath = carthagePath.stringByAppendingPathComponent("Checkouts")
    let fileManager = NSFileManager.defaultManager()
    let directories = try fileManager.contentsOfDirectoryAtPath(checkoutsPath)
    return directories
}

func licensesPlist() -> String {
    let outputDirectory = projectDirectory()
    let fileName = (outputDirectory as NSString).stringByAppendingPathComponent("Licenses.plist")
    let fileManager = NSFileManager.defaultManager()
    if !fileManager.fileExistsAtPath(fileName) {
        fileManager.createFileAtPath(fileName, contents: nil, attributes: nil)
    }
    return fileName
}

func licenseStrings() -> [String] {
    return ["LICENSE", "License.txt", "LICENSE.txt", "LICENSE.md"]
}

func licenseFileNameInDirectory(path: String) -> String? {
    let licensePaths: [String] = licenseStrings().map { path.stringByAppendingPathComponent($0) }
    var licensePath: String?
    let fileManager = NSFileManager.defaultManager()
    for filePath in licensePaths {
        if fileManager.fileExistsAtPath(filePath) {
            licensePath = filePath
            break
        }
    }
    return licensePath
}

func tidyPodsLicenses(licenses: [Dictionary<String,String>]) -> [Dictionary<String,String>] {
    var podsLicenses: [Dictionary<String,String>] = Array()
    for dict in licenses {
        var dictionary: Dictionary<String,String> = dict
        dictionary.removeValueForKey("Type")
        podsLicenses.append(dictionary)
    }
    return podsLicenses
}

func podsLicenses() -> [Dictionary<String,String>] {
    var licenses: [Dictionary<String,String>] = Array()
    let podsFile = podsLicenseFile()
    let fileManager = NSFileManager.defaultManager()
    if fileManager.fileExistsAtPath(podsFile) {
        if let podsDictionary = NSDictionary(contentsOfFile: podsFile) {
            var podsArray: [Dictionary<String,String>] = podsDictionary.valueForKey("PreferenceSpecifiers") as! Array
            if podsArray.count > 2 {
                podsArray.removeFirst()
                podsArray.removeLast()
                licenses = tidyPodsLicenses(podsArray)
            }
        } else {
            print("Error: faile to get contents of file \(podsFile)")
        }
    } else {
        print("Warning: Project do not have a Pods directory!")
    }
    return licenses
}

func carthageLicenses() -> [Dictionary<String,String>] {
    var licenses: [Dictionary<String,String>] = Array()
    do {
        let items: Array = try carthageCheckoutsItems()
        
        for itemPath in items {
            let checkoutsPath = carthageDirectory().stringByAppendingPathComponent("Checkouts")
            let filePath = checkoutsPath.stringByAppendingPathComponent(itemPath)
            
            if let licensePath = licenseFileNameInDirectory(filePath) {
                let content: String = try String(contentsOfFile:licensePath)
                let licenseDic = ["Title": itemPath, "FooterText": content]
                licenses.append(licenseDic)
            } else {
                print("Warning: \(itemPath) do not have a license file!")
            }
        }

    } catch {
        print("Warning: Carthage Checkouts directory doesn't exists!")
    }
    return licenses
}

if Process.arguments.count == 2 {
    let fileName = licensesPlist()
    
    let carthageLicense = carthageLicenses()
    let podsLicense = podsLicenses()
    print("")
    if carthageLicense.count > 0 {
        if (carthageLicense as NSArray).writeToFile(fileName, atomically: true) {
            print("Success! Your carthage licenses are at \(fileName) 👏")
        } else {
            print("Failed to write carthage licenses at \(fileName) ")
        }
    }
    if podsLicense.count > 0 {
        if (podsLicense as NSArray).writeToFile(fileName, atomically: true) {
            print("Success! Your pods licenses are at \(fileName) 👏")
        } else {
            print("Failed to write pods licenses at \(fileName) ")
        }
    }
    
} else {
    print("USAGE: ./fetch_licenses projectDirectory/ ")
}