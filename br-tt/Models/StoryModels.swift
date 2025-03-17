//
//  StoryModels.swift
//  br-TechnicalTest
//
//  Created by Louis Fournier on 3/13/25.
//

import SwiftUI
import Combine

// MARK: - Data Models

/// Represents a single item within a story
struct StoryItem: Identifiable {
    let id: UUID
    let color: Color
    var isLiked: Bool
    
    init(id: UUID = UUID(), color: Color, isLiked: Bool = false) {
        self.id = id
        self.color = color
        self.isLiked = isLiked
    }
}

/// Represents a collection of story items
struct Story: Identifiable {
    let id: UUID
    var items: [StoryItem]
    let userId: String
    let userColor: Color
    
    init(id: UUID = UUID(), items: [StoryItem] = [], userId: String = "", userColor: Color = .gray) {
        self.id = id
        self.items = items
        self.userId = userId
        self.userColor = userColor
    }
}


// MARK: - Data Service

/// Service responsible for fetching and managing story data
class StoryDataService: ObservableObject {
    // Published properties that views can observe
    @Published private(set) var stories: [Story] = []
    @Published private(set) var storyCursors: [UUID: Int] = [:] // Map story ID to cursor position
    @Published private(set) var isLoadingStories = false
    @Published private(set) var isLoadingItems = false
    
    // MARK: - Data Modification Methods
    
    /// Toggle the like status of a specific story item
    func toggleLike(storyId: UUID, itemId: UUID) {
        guard let storyIndex = stories.firstIndex(where: { $0.id == storyId }),
              let itemIndex = stories[storyIndex].items.firstIndex(where: { $0.id == itemId }) else {
            return
        }
        
        stories[storyIndex].items[itemIndex].isLiked.toggle()
    }
    
    /// Advance the cursor for a specific story
    func advanceCursor(for storyId: UUID) {
        // Find the story to check its item count
        if let storyIndex = stories.firstIndex(where: { $0.id == storyId }) {
            let story = stories[storyIndex]
            let currentPosition = storyCursors[storyId] ?? 0
            
            // Only advance if we're not at the end
            if currentPosition < story.items.count - 1 {
                storyCursors[storyId] = currentPosition + 1
            }
        } else {
            // Story doesn't exist, do nothing
            return
        }
    }
    
    /// Get the current cursor position for a story
    func getCursorPosition(for storyId: UUID) -> Int {
        return storyCursors[storyId] ?? 0
    }
    
    /// Check if a story is fully seen (cursor at the end)
    func isStoryFullySeen(storyId: UUID) -> Bool {
        if let storyIndex = stories.firstIndex(where: { $0.id == storyId }) {
            let story = stories[storyIndex]
            let currentPosition = storyCursors[storyId] ?? 0
            
            return currentPosition >= story.items.count - 1
        }
        return false
    }
    
    // MARK: - Data Fetching Methods
    
    /// Fetch more stories with their initial items
    func fetchMoreStories() {
        guard !isLoadingStories else { return }
        
        isLoadingStories = true
        
        // Simulate network delay on a background queue
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // Generate 5-10 random stories (this work happens on background thread)
            let newStories = self.generateRandomStories(count: Int.random(in: 5...10))
            
            // Switch to main thread only for UI updates
            DispatchQueue.main.async {
                // Append new stories
                self.stories.append(contentsOf: newStories)
                
                // Generate random cursors for some of the stories
                for story in newStories {
                    // Only create cursors for about half of the stories
                    if Bool.random() {
                        let maxIndex = max(0, story.items.count - 1)
                        let randomIndex = Int.random(in: 0...maxIndex)
                        self.storyCursors[story.id] = randomIndex
                    }
                }
                
                self.isLoadingStories = false
            }
        }
    }
    
    /// Fetch more items for a specific story
    func fetchMoreItems(for storyId: UUID) {
        guard !isLoadingItems else { return }
        guard let storyIndex = stories.firstIndex(where: { $0.id == storyId }) else { return }
        
        isLoadingItems = true
        
        // Simulate network delay on a background queue
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // Generate 3-8 random items (this work happens on background thread)
            let newItems = self.generateRandomItems(count: Int.random(in: 3...8))
            
            // Switch to main thread only for UI updates
            DispatchQueue.main.async {
                // Append new items to the story
                self.stories[storyIndex].items.append(contentsOf: newItems)
                self.isLoadingItems = false
            }
        }
    }
    
    // MARK: - Helper Methods for Random Data Generation
    
    private func generateRandomStories(count: Int) -> [Story] {
        return (0..<count).map { index in
            let items = generateRandomItems(count: Int.random(in: 2...5))
            // Generate random user ID and color
            let userId = "user_\(UUID().uuidString.prefix(8))"
            let userColor = randomColor()
            return Story(items: items, userId: userId, userColor: userColor)
        }
    }
    
    private func generateRandomItems(count: Int) -> [StoryItem] {
        return (0..<count).map { _ in
            StoryItem(
                color: randomColor(),
                isLiked: Bool.random()
            )
        }
    }
    
    
    private func randomColor() -> Color {
        let red = Double.random(in: 0...1)
        let green = Double.random(in: 0...1)
        let blue = Double.random(in: 0...1)
        
        return Color(red: red, green: green, blue: blue)
    }
    
    // MARK: - Initialization
    
    init() {
        // Load initial batch of stories
        fetchMoreStories()
    }
}
