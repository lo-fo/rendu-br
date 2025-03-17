//
//  HomeView.swift
//  br-TechnicalTest
//
//  Created by Louis Fournier on 3/13/25.
//

import SwiftUI
import Combine

struct CircleItem: View {
    var color: Color
    var id: Int
    var hasRedRing: Bool
    
    var body: some View {
        ZStack {
            // Main circle
            Circle()
                .fill(color)
                .frame(width: 52, height: 52) // Slightly smaller to accommodate the ring
            
            // Ring
            Circle()
                .stroke(hasRedRing ? Color.red : Color.gray, lineWidth: 3)
                .frame(width: 60, height: 60)
        }
        .frame(width: 60, height: 60) // Keep overall size the same
        .padding(.horizontal, 4)
    }
}

struct HomeView: View {
    // Environment object for the data service
    @EnvironmentObject private var dataService: StoryDataService
    
    // ViewModel to manage our stories
    @StateObject private var viewModel = StoriesViewModel(dataService: StoryDataService())
    
    // Create a wrapper for UUID that conforms to Identifiable
    struct IdentifiableUUID: Identifiable {
        let id: UUID
    }
    
    @State private var showingStory = false
    @State private var selectedStoryId: IdentifiableUUID? = nil
    
    var body: some View {
        VStack {
            // Scrollable bar of circular elements at the top
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(viewModel.storyCircles) { storyCircle in
                        CircleItem(
                            color: storyCircle.userColor,
                            id: storyCircle.id.hashValue,
                            hasRedRing: !storyCircle.isFullySeen
                        )
                        .id(storyCircle.id)
                        .onTapGesture {
                            // First set the ID, then trigger the sheet presentation
                            // Use DispatchQueue to ensure state updates are processed in order
                            DispatchQueue.main.async {
                                self.selectedStoryId = IdentifiableUUID(id: storyCircle.id)
                                self.showingStory = true
                            }
                        }
                        .onAppear {
                            // Load more stories when we reach near the end
                            if storyCircle.id == viewModel.storyCircles.last?.id {
                                viewModel.loadMoreStories()
                            }
                        }
                    }
                    
                    // Loading spinner at the end
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(width: 60, height: 60)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 4) // Same padding as inter-item spacing
            }
            .frame(height: 80)
            
            Spacer() // Pushes everything to the top
        }
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 0) // Ensures content starts at the top of safe area
        }
        // Use item-based presentation which can be more reliable
        .fullScreenCover(item: $selectedStoryId) { identifiableUUID in
            StoryView(storyId: identifiableUUID.id)
                .environmentObject(dataService)
        }
        .onAppear {
            // Update the view model with the environment data service
            viewModel.updateDataService(dataService)
        }
    }
}

// Model for our story circle items in the scrollview
struct StoryCircleModel: Identifiable {
    let id: UUID // Story ID
    let userColor: Color
    let isFullySeen: Bool
    
    init(id: UUID, userColor: Color, isFullySeen: Bool) {
        self.id = id
        self.userColor = userColor
        self.isFullySeen = isFullySeen
    }
}

// ViewModel to handle stories in the horizontal scrollview
class StoriesViewModel: ObservableObject {
    @Published var storyCircles: [StoryCircleModel] = []
    @Published var isLoading = false
    
    private var dataService: StoryDataService
    private var cancellables = Set<AnyCancellable>()
    
    init(dataService: StoryDataService) {
        self.dataService = dataService
        
        // Convert initial stories to view models
        updateStoryCircles()
        
        // Subscribe to loading state changes
        dataService.$isLoadingStories
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                self.isLoading = isLoading
                
                if !isLoading {
                    self.updateStoryCircles()
                }
            }
            .store(in: &cancellables)
        
        // Load initial batch of stories if needed
        if dataService.stories.isEmpty {
            loadMoreStories()
        }
    }
    
    // Method to update the data service reference
    func updateDataService(_ newDataService: StoryDataService) {
        
        // Cancel all existing subscriptions
        cancellables.removeAll()
        
        // Update the data service reference
        self.dataService = newDataService
        
        // Update UI with current stories
        updateStoryCircles()
        
        // Subscribe to loading state changes with the new data service
        dataService.$isLoadingStories
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                self.isLoading = isLoading
                
                if !isLoading {
                    self.updateStoryCircles()
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to changes in the stories array
        dataService.$stories
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] stories in
                self?.updateStoryCircles()
            }
            .store(in: &cancellables)
    }
    
    func updateStoryCircles() {
        // Map stories from data service to view models
        storyCircles = dataService.stories.map { story in
            let isFullySeen = dataService.isStoryFullySeen(storyId: story.id)
            
            return StoryCircleModel(
                id: story.id,
                userColor: story.userColor,
                isFullySeen: isFullySeen
            )
        }
    }
    
    func loadMoreStories() {
        // Don't load more if already loading
        guard !isLoading else { 
            return 
        }
        
        // Request more stories from the data service
        dataService.fetchMoreStories()
        // No need to set isLoading here as it's bound to dataService.isLoadingStories
    }
    
    func getStory(id: UUID) -> Story? {
        return dataService.stories.first(where: { $0.id == id })
    }
}

#Preview {
    HomeView()
}
