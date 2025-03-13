# BeReal Technical Test

## ⚠️ DISCLAIMER ⚠️
**This code was completed in 3 hours instead of the allocated 4 hours.**

## What I've Implemented

- A horizontal scrollable list of story circles at the top of the screen
- Story viewing functionality with navigation between items and stories
- Like/unlike functionality for story items
- Visual indicators for seen/unseen stories (red ring around unseen stories)
- Progress tracking for each story (cursor position)

At the time of concluding my work, I was still iterating on the inter-story navigation logic, particularly with taking into account the seen story items.

## What I Decided Not to Implement

Given the time constraints, I made strategic decisions to focus on core functionality:

1. **Local Caching of Data**: I did not implement persistence or local caching of story data between app sessions.

2. **UX Shortcut for Story Navigation**: I did not add a shortcut to skip directly to the next story (as opposed to navigating through all items in the current story).

3. **Minimal UI Design**: I kept the UI elements to a bare minimum as there was already significant work required for the business logic implementation.

4. **Animations**: I did not implement animations for transitions between stories or items.

5. **Error Handling**: The error handling is basic and could be more robust in a production app.


## Future Improvements

With more time, I would:
- Add proper animations for transitions
- Implement local caching using Core Data or similar
- Add more comprehensive error handling
- Improve the UI with better visual design
- Add unit and UI tests
