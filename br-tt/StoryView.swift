//
//  StoryView.swift
//  br-TechnicalTest
//
//  Created by Louis Fournier on 3/13/25.
//

import SwiftUI
import Combine

// ViewModel for StoryView
class StoryViewModel: ObservableObject {
    // Data service
    private var dataService: StoryDataService
    
    // Published properties
    @Published var currentStoryIndex: Int
    @Published var currentItemIndex: Int = 0
    @Published var isLiked: Bool = false
    
    // Computed properties
    var stories: [Story] { dataService.stories }
    
    var currentStory: Story? {
        guard currentStoryIndex >= 0 && currentStoryIndex < stories.count else { return nil }
        return stories[currentStoryIndex]
    }
    
    var currentItem: StoryItem? {
        guard let story = currentStory,
              currentItemIndex >= 0 && currentItemIndex < story.items.count else { return nil }
        return story.items[currentItemIndex]
    }
    
    var currentColor: Color {
        currentItem?.color ?? .gray
    }
    
    var currentRatio: String {
        guard let story = currentStory else { return "0/0" }
        return "\(currentItemIndex + 1)/\(story.items.count)"
    }
    
    var canGoToPreviousItem: Bool {
        // Can go to previous item if either:
        // 1. We're not at the first item of the current story
        // 2. We're at the first item but there's a previous story
        return (currentItemIndex > 0) || (currentItemIndex == 0 && currentStoryIndex > 0)
    }
    
    var canGoToNextItem: Bool {
        // Can go to next item if either:
        // 1. We're not at the last item of the current story
        // 2. We're at the last item but there's a next story
        guard let story = currentStory else { return false }
        return (currentItemIndex < story.items.count - 1) || 
               (currentItemIndex == story.items.count - 1 && currentStoryIndex < stories.count - 1)
    }
    
    var canGoToPreviousStory: Bool {
        return currentStoryIndex > 0
    }
    
    var canGoToNextStory: Bool {
        return currentStoryIndex < stories.count - 1
    }
    
    // Initialize with a specific story index
    init(dataService: StoryDataService, initialStoryIndex: Int) {
        self.dataService = dataService
        self.currentStoryIndex = initialStoryIndex
        
        // Initialize item index based on seen cursor
        if let story = dataService.stories[safe: initialStoryIndex] {
            let seenCursor = dataService.getCursorPosition(for: story.id)
            
            // Start at the next unseen item or at the beginning if all are seen
            if seenCursor < story.items.count - 1 {
                self.currentItemIndex = seenCursor + 1
            } else {
                self.currentItemIndex = 0
            }
            
            // Initialize like status
            if let item = story.items[safe: currentItemIndex] {
                self.isLiked = item.isLiked
            }
        }
    }
    
    // Navigation methods
    func goToNextItem() {
        guard let story = currentStory else { 
            return 
        }
        
        if currentItemIndex < story.items.count - 1 {
            // Move to next item in current story
            currentItemIndex += 1
            updateLikeStatus()
            
            // Update seen cursor if we're advancing beyond it
            let seenCursor = dataService.getCursorPosition(for: story.id)
            if currentItemIndex > seenCursor {
                dataService.advanceCursor(for: story.id)
            }
        } else {
            // Move to next story if available
            goToNextStory()
        }
    }
    
    func goToPreviousItem() {
        guard let story = currentStory else { 
            return 
        }
        
        if currentItemIndex > 0 {
            // Move to previous item in current story
            currentItemIndex -= 1
            updateLikeStatus()
        } else {
            // Move to previous story if available
            goToPreviousStory()
        }
    }
    
    func goToNextStory() {
        if canGoToNextStory {
            currentStoryIndex += 1
            resetItemIndex()
            updateLikeStatus()
        }
    }
    
    func goToPreviousStory() {
        if canGoToPreviousStory {
            currentStoryIndex -= 1
            // Go to the last item of the previous story
            if let story = currentStory {
                currentItemIndex = story.items.count - 1
                updateLikeStatus()
            }
        }
    }
    
    // Reset item index when changing stories
    private func resetItemIndex() {
        guard let story = currentStory else { return }
        
        let seenCursor = dataService.getCursorPosition(for: story.id)
        
        // Start at the next unseen item or at the beginning if all are seen
        if seenCursor < story.items.count - 1 {
            currentItemIndex = seenCursor + 1
        } else {
            currentItemIndex = 0
        }
    }
    
    // Update like status based on current item
    private func updateLikeStatus() {
        if let item = currentItem {
            isLiked = item.isLiked
        } else {
            isLiked = false
        }
    }
    
    // Toggle like status for current item
    func toggleLike() {
        guard let story = currentStory, let item = currentItem else { 
            return 
        }
        
        // Toggle in view model
        isLiked.toggle()
        
        // Update in data service
        dataService.toggleLike(storyId: story.id, itemId: item.id)
    }
    
    // Update the data service and story index
    func updateDataService(_ newDataService: StoryDataService, storyId: UUID? = nil) {
        self.dataService = newDataService
        
        // Find the story index if a storyId is provided
        if let storyId = storyId, 
           let index = newDataService.stories.firstIndex(where: { $0.id == storyId }) {
            self.currentStoryIndex = index
            
            // Reset item index based on seen cursor
            if let story = newDataService.stories[safe: index] {
                let seenCursor = newDataService.getCursorPosition(for: story.id)
                
                // Start at the next unseen item or at the beginning if all are seen
                if seenCursor < story.items.count - 1 {
                    self.currentItemIndex = seenCursor + 1
                } else {
                    self.currentItemIndex = 0
                }
                
                // Update like status
                if let item = story.items[safe: currentItemIndex] {
                    self.isLiked = item.isLiked
                }
            }
        }
    }
}

// Extension to safely access array elements
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct StoryView: View {
    // Environment object for the data service
    @EnvironmentObject private var dataService: StoryDataService
    
    // ViewModel
    @StateObject private var viewModel: StoryViewModel
    
    // State for the heart button
    @State private var isLiked: Bool = false
    
    // Environment variable to dismiss the view
    @Environment(\.dismiss) private var dismiss
    
    // Initialize with a story ID
    init(storyId: UUID) {
        // Create a temporary data service
        let tempDataService = StoryDataService()
        
        // Initialize with index 0, we'll update it in onAppear
        self._viewModel = StateObject(wrappedValue: StoryViewModel(dataService: tempDataService, initialStoryIndex: 0))
        
        // Store the storyId for later use
        self._storyId = State(initialValue: storyId)
    }
    
    // Add this property to StoryView
    @State private var storyId: UUID
    
    // Backward compatibility initializer
    init(backgroundColor: Color) {
        let tempDataService = StoryDataService()
        self._viewModel = StateObject(wrappedValue: StoryViewModel(dataService: tempDataService, initialStoryIndex: 0))
        // Initialize storyId with a placeholder UUID since it's required
        self._storyId = State(initialValue: UUID())
    }
    
    var body: some View {
        ZStack {
            // Full screen background color based on current item
            viewModel.currentColor
                .ignoresSafeArea()
            
            // Side arrow buttons
            HStack {
                // Left arrow button - only show if we can navigate left
                if viewModel.canGoToPreviousItem {
                    Button(action: {
                        // Navigate to previous item
                        viewModel.goToPreviousItem()
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .resizable()
                            .frame(width: 44, height: 44)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                } else {
                    // Empty spacer to maintain layout
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                // Right arrow button - only show if we can navigate right
                if viewModel.canGoToNextItem {
                    Button(action: {
                        // Navigate to next item
                        viewModel.goToNextItem()
                    }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .resizable()
                            .frame(width: 44, height: 44)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                } else {
                    // Empty spacer to maintain layout
                    Color.clear
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 20)
            
            // Heart button at bottom right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        // Toggle like state
                        viewModel.toggleLike()
                    }) {
                        Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                            .resizable()
                            .frame(width: 30, height: 28)
                            .foregroundColor(viewModel.isLiked ? .red : .white)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            
            // Top bar with ratio and close button
            VStack {
                HStack {
                    Spacer()
                    
                    // Ratio indicator in the middle
                    Text(viewModel.currentRatio)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(16)
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    // Close button at top right
                    Button(action: {
                        // Dismiss the view
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 15, height: 15)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                Spacer()
            }
        }
        .onAppear {
            // Update the view model with the environment data service and the story ID
            viewModel.updateDataService(dataService, storyId: storyId)
        }
    }
}

#Preview {
    StoryView(backgroundColor: .purple)
}
