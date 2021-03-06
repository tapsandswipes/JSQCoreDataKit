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

import Foundation
import CoreData


public final class Company: NSManagedObject {

    static public let entityName = "Company"

    @NSManaged public var name: String

    @NSManaged public var dateFounded: NSDate

    @NSManaged public var profits: NSDecimalNumber

    @NSManaged public var employees: NSSet

    public init(context: NSManagedObjectContext,
                name: String,
                dateFounded: NSDate,
                profits: NSDecimalNumber) {
        let entity = NSEntityDescription.entityForName(Company.entityName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)

        self.name = name
        self.dateFounded = dateFounded
        self.profits = profits
    }

    public class func newCompany(context: NSManagedObjectContext) -> Company {
        let name = "Company " + String(NSUUID().UUIDString.characters.split { $0 == "-" }.first!)

        return Company(context: context,
                       name: name,
                       dateFounded: NSDate.distantPast(),
                       profits: NSDecimalNumber(unsignedInt: arc4random_uniform(1_000_000)))
    }

    @objc
    private override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
}
