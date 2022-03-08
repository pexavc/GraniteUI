//
//  File.swift
//  
//
//  Created by 0xZala on 1/16/22.
//

import Foundation

public protocol GraniteSatellite: GraniteConnection {
    func share(_ relay: GraniteBaseRelay?)
    func request(_ event: GraniteEvent)
    func listen(to satellite: GraniteSatellite, contact: GraniteContact.Rule)
    func attach(to satellite: GraniteSatellite)
    func tell(_ event: GraniteEvent?)
    func contact(_ input: GraniteEvent)
    func commit()
}
