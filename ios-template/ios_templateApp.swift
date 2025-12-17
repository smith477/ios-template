//
//  ios_templateApp.swift
//  ios-template
//
//  Created by Dusan Kovacevic on 05/12/2025.
//

import SwiftUI
import CoreData

@main
struct ios_templateApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
