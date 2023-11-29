//
//  MainViewModel.swift
//  Notee
//
//  Created by Andrew on 18.02.2023.
//

import Foundation
import CoreData

class MainViewModel: ObservableObject {
    
    @Published var selectedNote: NoteEntity?
    
    
    @Published var notesArray: [NoteEntity] = [] {
        didSet {
            divideArray()
        }
    }
    
    @Published var filteredArray: [NoteEntity] = []
    
    @Published var firstHalf: [NoteEntity] = []
    
    @Published var secondHalf: [NoteEntity] = []
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E HH:mm"
        return formatter
    }
    
    let container = NSPersistentContainer(name: "NotesContainer")
    
    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Error loading Core Data \(error)")
            }
        }
        fetchNotes()
        divideArray()
    }
    
    
    func fetchNotes() {
        let request = NSFetchRequest<NoteEntity>(entityName: "NoteEntity")
        
        let sortDescriptor = NSSortDescriptor(key: "dateModified", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            notesArray = try container.viewContext.fetch(request)
        } catch let error {
            print("Error fetching. \(error)")
        }
    }
    
    
    func divideArray() {
        
        let arrayToDivide = filteredArray.isEmpty ? notesArray : filteredArray
        let midIndex = arrayToDivide.count / 2
        
        if arrayToDivide.count % 2 == 0 {
            firstHalf = Array(arrayToDivide[0..<midIndex])
            secondHalf = Array(arrayToDivide[midIndex..<arrayToDivide.count])
        } else {
            firstHalf = Array(arrayToDivide[0..<midIndex+1])
            secondHalf = Array(arrayToDivide[midIndex+1..<arrayToDivide.count])
        }
        
    }
    
    func updateIfMarked(item: NoteEntity) {
        item.isMarked = !item.isMarked
        saveData()
        fetchNotes()
    }
    
    func updateIfLocked(item: NoteEntity) {
        item.isLocked = !item.isLocked
        saveData()
        fetchNotes()
    }
    
    func updateIfFlaged(item: NoteEntity) {
        item.isFlagged = !item.isFlagged
        saveData()
        fetchNotes()
    }
    
    func makeFirst(item: NoteEntity) {
        updateDate(item: item)
        saveData()
        fetchNotes()
    }
    
    func updateDate(item: NoteEntity) {
        item.dateModified = Date()
    }
    
    
    func updateNote(item: NoteEntity, textTitle: String, textBody: String, textType: String) {
        if let context = item.managedObjectContext {
            context.perform { [self] in
                item.title = textTitle
                item.textBody = textBody
                item.type = textType
                self.saveData()
            }
        }
    }
    
    func deleteNote(note: NoteEntity) {
        container.viewContext.delete(note)
        filteredArray = []
        divideArray()
        saveData()
        fetchNotes()
        
    }
    
    func saveData() {
        do {
            try container.viewContext.save()
            
        } catch let error {
            print("Error saving \(error)")
        }
    }
    
    func createNote() {
        let newNote = NoteEntity(context: container.viewContext)
        newNote.title = ""
        newNote.textBody = ""
        newNote.type = ""
        newNote.isFlagged = false
        newNote.isLocked = false
        newNote.isMarked = false
        
        saveData()
        
        selectedNote = newNote
    }
    
    
    func filterNotes(by searchText: String) -> [NoteEntity] {
        guard !searchText.isEmpty else { return notesArray }
        
        filteredArray = notesArray.filter { note in
            let titleMatch = note.title?.range(of: searchText, options: .caseInsensitive)
            let bodyMatch = note.textBody?.range(of: searchText, options: .caseInsensitive)
            let typeMatch = note.type?.range(of: searchText, options: .caseInsensitive)
            
            return titleMatch != nil || bodyMatch != nil || typeMatch != nil
        }
        divideArray()
        return filteredArray
    }
    
    
    
    
}


