//
//  TableViewController.swift
//  OhanaContactsTest
//
//  Created by Conner Simmons on 10/29/16.
//  Copyright © 2016 The Blue Book Network. All rights reserved.
//

import UIKit
import Ohana

class TableViewController: UITableViewController, OHCNContactsDataProviderDelegate {
    
    let collation = UILocalizedIndexedCollation.current()
    var alphaSections: [[OHContact]] = []
    var blueBookContacts : [OHContact] = []
    
    var dataSource: OHContactsDataSource!
    
    let sortOrder = "fullName"
    
    override func viewDidLoad() {
        let alphabeticalSortProcessor : OHAlphabeticalSortPostProcessor!
        if sortOrder == "lastName" {
            alphabeticalSortProcessor = OHAlphabeticalSortPostProcessor(sortMode: .lastName)
        } else if sortOrder == "firstName" {
            alphabeticalSortProcessor = OHAlphabeticalSortPostProcessor(sortMode: .firstName)
        } else {
            alphabeticalSortProcessor = OHAlphabeticalSortPostProcessor(sortMode: .fullName)
        }
        
        let phoneNumberRequiredProcessor = OHRequiredFieldPostProcessor(fieldType: .phoneNumber)
        
        var dataProvider: OHContactsDataProviderProtocol
        let contactsDataProvider = OHCNContactsDataProvider(delegate: self)
        contactsDataProvider.loadThumbnailImage = true
        dataProvider = contactsDataProvider
        
        dataSource = OHContactsDataSource(dataProviders: NSOrderedSet(objects: dataProvider), postProcessors: NSOrderedSet(objects: phoneNumberRequiredProcessor, alphabeticalSortProcessor))
        
        dataSource.onContactsDataSourceReadySignal.addObserver(self, callback: { [weak self] (observer) in
            if let contacts = self?.dataSource.contacts {
                
                if let alphaContacts = self?.getContactsAlpha(contacts) {
                    self?.alphaSections = alphaContacts
                }
                
                //                for contactSections in (self?.alphaSections)! {
                //                    for c in contactSections {
                //                        print(c.fullName ?? "NO NAME")
                //                    }
                //                    print()
                //                }
                
                if let bbContacts = self?.getBlueBookContacts(contacts) {
                    self?.blueBookContacts = bbContacts
                }
                
                //                for contact in (self?.blueBookContacts)! {
                //                    print(contact.fullName ?? "NO NAME")
                //                }
                
                
            }
            self?.tableView?.reloadData()
        })
        
        dataSource.loadContacts()
    }
    
    func getContactsAlpha(_ contacts : NSOrderedSet) -> [[OHContact]] {
        var alphaSections: [[OHContact]] = []
        let sectionCount = collation.sectionTitles.count
        let selector: Selector = NSSelectorFromString(sortOrder)
        alphaSections = Array(repeating: [], count: sectionCount)
        
        for object in contacts {
            let contact = object as! OHContact
            let sectionNumber = collation.section(for: contact, collationStringSelector: selector)
            
            var canAddContact = true
            for c in alphaSections[sectionNumber] {
//                if c.isEqual(to: contact) {
//                    print("THEY'RE EQUAL")
//                    print(c.fullName)
//                    print(contact.fullName)
//                    print()
//                    canAddContact = false
//                    break
//                }
                if c.firstName == contact.firstName && c.lastName == contact.lastName && c.organizationName == contact.organizationName {
//                    print("THEY'RE EQUAL")
//                    print(c.fullName)
//                    print(contact.fullName)
//                    print()
                    canAddContact = false
                    break
                }
            }
            
            if canAddContact {
                alphaSections[sectionNumber].append(contact)

            }
        }
        
        return alphaSections
    }
    
    func getBlueBookContacts(_ contacts : NSOrderedSet) -> [OHContact]{
        var bbContacts = [OHContact]()
        
        for contact in contacts {
            let c = contact as! OHContact
            for field in getContactPhoneNumbers(c.contactFields!) {
                if (field.label.contains("Blue Book")) {
                    bbContacts.append(c)
                    break
                }
            }
        }
        
        bbContacts.sort { (c1, c2) -> Bool in
            return c1.fullName! < c2.fullName!
        }
        
        return bbContacts
    }
    
    func getContactPhoneNumbers(_ contactFields : NSOrderedSet) -> [OHContactField] {
        var phoneNumbers = [OHContactField]()
        
        for contactField in contactFields {
            let field = contactField as! OHContactField
            if displayLabelForContactField(field.type) == "Phone Number" {
                phoneNumbers.append(field)
            }
        }
        
        return phoneNumbers
    }
    
    // MARK: OHCNContactsDataProviderDelegate
    @available(iOS 9.0, *)
    func dataProviderDidHitContactsAuthenticationChallenge(_ dataProvider: OHCNContactsDataProvider) {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { (granted, error) in
            if granted {
                dataProvider.loadContacts()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        var sections = Int()
        if !alphaSections.isEmpty {
            sections = alphaSections.count
        }
        return sections
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title = String()
        if alphaSections[section].count > 0 {
            title = collation.sectionTitles[section]
        }
        return title
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        var titles = [String]()
        if alphaSections.count > 0 {
            titles = collation.sectionIndexTitles
        }
        return titles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return collation.section(forSectionIndexTitle: index)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        var rows = Int()
        if alphaSections.isEmpty {
            rows = 0
        } else {
            rows = alphaSections[section].count
        }
        return rows
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        
        //        if let contact = self.dataSource.contacts?.object(at: indexPath.row) as? OHContact {
        let contact = alphaSections[indexPath.section][indexPath.row]
        cell.textLabel?.text = displayTitleForContact(contact)
        
        cell.imageView?.image = contact.thumbnailPhoto
        
        if dataSource.selectedContacts.contains(contact) {
            cell.backgroundColor = UIColor(red: 210.0 / 255.0, green: 241.0 / 255.0, blue: 247.0 / 255.0, alpha: 1.0)
        } else {
            cell.backgroundColor = UIColor.white
        }
        //        } else {
        //            cell.textLabel?.text = "No contacts access, open Settings app to fix this"
        //        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //        if let contact = self.dataSource.contacts?.object(at: indexPath.row) as? OHContact {
        let contact = alphaSections[indexPath.section][indexPath.row]
        //            if dataSource.selectedContacts.contains(contact) {
        //                dataSource.deselectContacts(NSOrderedSet(object: contact))
        //            } else {
        //                dataSource.selectContacts(NSOrderedSet(object: contact))
        //            }
        print("FN: \(contact.firstName!)")
        print("LN: \(contact.lastName!)")
        print("FULL: \(contact.fullName!)")
        print("ORG: \(contact.organizationName!)")
        if let contactFields = contact.contactFields {
            for field in contactFields {
                let f = field as! OHContactField
                print("\(displayLabelForContactField(f.type)): \(f.label) - \(f.value)")
            }
        }
        
        print()
        //        }
        tableView.reloadData()
    }
    
    // MARK: Private
    fileprivate func displayTitleForContact(_ contact: OHContact) -> String? {
        if contact.fullName?.characters.count ?? 0 > 0 {
            return contact.fullName
        } else if contact.contactFields?.count ?? 0 > 0 {
            return (contact.contactFields?.object(at: 0) as? OHContactField)?.value
        } else {
            return "(Unnamed Contact)"
        }
    }
    
    fileprivate func displayLabelForContactField(_ contactFieldType: OHContactFieldType) -> String {
        switch contactFieldType.rawValue {
        case 0 :
            return "Phone Number"
        case 1 :
            return "Email Address"
        case 2 :
            return "URL"
        default:
            return "Other"
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
