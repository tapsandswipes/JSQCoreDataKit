//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://www.jessesquires.com/JSQCoreDataKit
//
//
//  GitHub
//  https://github.com/jessesquires/JSQCoreDataKit
//
//
//  License
//  Copyright © 2015 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

import CoreData
import Foundation


/**
 Describes a Core Data model file exention type based on the
 [Model File Format and Versions](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/vmModelFormat.html)
 documentation.
 */
public enum ModelFileExtension: String {
    /// The extension for a model bundle, or a `.xcdatamodeld` file package.
    case bundle = "momd"

    /// The extension for a versioned model file, or a `.xcdatamodel` file.
    case versionedFile = "mom"

    /// The extension for a mapping model file, or a `.xcmappingmodel` file.
    case mapping = "cdm"

    /// The extension for a sqlite store.
    case sqlite = "sqlite"
}


/**
 An instance of `CoreDataModel` represents a Core Data model — a `.xcdatamodeld` file package.
 It provides the model and store URLs as well as methods for interacting with the store.
 */
public struct CoreDataModel: CustomStringConvertible, Equatable {

    // MARK: Properties

    /// The name of the Core Data model resource.
    public let name: String

    /// The bundle in which the model is located.
    public let bundle: NSBundle

    /// The type of the Core Data persistent store for the model.
    public let storeType: StoreType

    /// The name of the Core Data persistent store file for the model.
    public let storeFileName: String?

    /**
     The file URL specifying the full path to the store.

     - note: If the store is in-memory, then this value will be `nil`.
     */
    public var storeURL: NSURL? {
        get {
            return storeType.storeDirectory()?.URLByAppendingPathComponent(databaseFileName)
        }
    }

    /// The file URL specifying the model file in the bundle specified by `bundle`.
    public var modelURL: NSURL {
        get {
            guard let url = bundle.URLForResource(name, withExtension: ModelFileExtension.bundle.rawValue) else {
                fatalError("*** Error loading model URL for model named \(name) in bundle: \(bundle)")
            }
            return url
        }
    }

    /// The database file name for the store.
    public var databaseFileName: String {
        get {
            switch storeType {
            case .sqlite: return (storeFileName ?? name) + "." + ModelFileExtension.sqlite.rawValue
            default: return (storeFileName ?? name)
            }
        }
    }

    /// The managed object model for the model specified by `name`.
    public var managedObjectModel: NSManagedObjectModel {
        get {
            guard let model = NSManagedObjectModel(contentsOfURL: modelURL) else {
                fatalError("*** Error loading managed object model at url: \(modelURL)")
            }
            return model
        }
    }

    /**
     Queries the meta data for the persistent store specified by the receiver
     and returns whether or not a migration is needed.

     - returns: `true` if the store requires a migration, `false` otherwise.
     */
    public var needsMigration: Bool {
        get {
            guard let storeURL = storeURL else { return false }

            do {
                let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(storeType.type,
                                                                                                 URL: storeURL,
                                                                                                 options: nil)
                return !managedObjectModel.isConfiguration(nil, compatibleWithStoreMetadata: metadata)
            }
            catch {
                debugPrint("*** Error checking persistent store coordinator meta data: \(error)")
                return false
            }
        }
    }


    // MARK: Initialization

    /**
     Constructs a new `CoreDataModel` instance with the specified name and bundle.

     - parameter name:      The name of the Core Data model.
     - parameter bundle:    The bundle in which the model is located. The default is the main bundle.
     - parameter storeType: The store type for the Core Data model. The default is `.sqlite`, with the user's documents directory.

     - returns: A new `CoreDataModel` instance.
     */
    public init(name: String, bundle: NSBundle = .mainBundle(), storeType: StoreType = .sqlite(defaultDirectoryURL()), storeFileName: String? = nil ) {
        self.name = name
        self.bundle = bundle
        self.storeType = storeType
        self.storeFileName = storeFileName
    }


    // MARK: Methods

    /**
     Removes the existing model store specfied by the receiver.

     - throws: If removing the store fails or errors, then this function throws an `NSError`.
     */
    public func removeExistingStore() throws {
        let fm = NSFileManager.defaultManager()
        if let storePath = storeURL?.path where fm.fileExistsAtPath(storePath) {
            try fm.removeItemAtPath(storePath)

            let writeAheadLog = storePath.stringByAppendingString("-wal")
            _ = try? fm.removeItemAtPath(writeAheadLog)

            let sharedMemoryfile = storePath.stringByAppendingString("-shm")
            _ = try? fm.removeItemAtPath(sharedMemoryfile)
        }
    }


    // MARK: CustomStringConvertible

    /// :nodoc:
    public var description: String {
        get {
            return "<\(CoreDataModel.self): name=\(name); storeType=\(storeType); needsMigration=\(needsMigration); "
                + "modelURL=\(modelURL); storeURL=\(storeURL)>"
        }
    }
    
}
