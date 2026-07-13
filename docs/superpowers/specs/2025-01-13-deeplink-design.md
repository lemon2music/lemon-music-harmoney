# Deeplink Feature Design Document

**Date:** 2025-01-13  
**Project:** Lemon Music HarmonyOS App  
**Feature:** Custom URI Scheme Deep Linking for Direct Song Playback

## Overview

The deeplink system will allow users to play songs directly from external sources (web links, QR codes, other apps) using the custom URI scheme `mymusic://play?song=歌曲名称`. When triggered, the app will:

1. Parse the incoming deeplink URI to extract the song name parameter
2. Search the current playlist for a matching song
3. If found, play that song; if not found, fall back to the first song
4. Navigate to the Playnow page to show the full player UI

The system uses a centralized `DeeplinkHandler` service that processes incoming URIs and coordinates with the existing `avplayermanager` service for playback.

## Architecture

The deeplink system consists of these components:

**1. EntryAbility (Modified)**
- Receives incoming deeplinks via `onCreate()` (cold start) and `onNewWant()` (warm start)
- Extracts URI from the `Want` object and passes it to `DeeplinkHandler`
- Minimal changes - delegates all deeplink logic to the handler

**2. DeeplinkHandler (New Service)**
- Centralized service for parsing and processing all deeplink URIs
- Handles URI parsing, parameter extraction, and validation
- Coordinates with avplayermanager for playback and router for navigation
- Provides clean API for future deeplink types

**3. AVPlayerManager (Enhanced)**
- Existing service maintains current responsibilities
- New method: `playSongByName(songName: string)` for name-based search and playback
- Implements fallback logic (first song if not found)

**4. Router (Existing)**
- Navigation to Playnow page after initiating playback

The data flow is: External Source → EntryAbility → DeeplinkHandler → AVPlayerManager → Router → Playnow Page

## Components

### DeeplinkHandler Service Structure

```typescript
// services/deeplinkHandler.ets
export class DeeplinkHandler {
  static parseDeeplink(uri: string): DeeplinkAction | null
  static processAction(action: DeeplinkAction): Promise<void>
  private static extractSongName(uri: string): string | null
  private static validateSongName(name: string): boolean
}

interface DeeplinkAction {
  type: 'play_song' | 'unknown'
  songName?: string
}
```

### EntryAbility Changes

- `onCreate()`: Extract URI from `want.parameters`, pass to `DeeplinkHandler`
- `onNewWant()`: Extract URI from `want.parameters`, pass to `DeeplinkHandler`

### AVPlayerManager Enhancement

- New method: `playSongByName(songName: string): Promise<void>`
- Search logic: Find exact match in `playlist`, fallback to `playlist[0]`
- Uses existing `playSongByIndex()` method for actual playback

### module.json5 Configuration

- Add skills configuration for `EntryAbility` to handle `mymusic://` scheme
- Define URI scheme and action patterns

## Data Flow

### Cold Start Flow (App not running)

1. User clicks deeplink: `mymusic://play?song=起风了`
2. HarmonyOS launches app → EntryAbility.onCreate(want)
3. EntryAbility extracts URI from want.parameters
4. EntryAbility calls DeeplinkHandler.processAction(action)
5. DeeplinkHandler extracts songName: "起风了"
6. DeeplinkHandler calls avplayerClass.playSongByName("起风了")
7. AVPlayerManager searches playlist, finds match or uses fallback
8. AVPlayerManager plays the song via existing playSongByIndex()
9. DeeplinkHandler navigates to Playnow page
10. User sees Playnow page with song playing

### Warm Start Flow (App already running)

1. User clicks deeplink while app is in background
2. HarmonyOS brings app to foreground → EntryAbility.onNewWant(want)
3. Same flow as cold start (steps 3-10)

### Fallback Scenario

1. AVPlayerManager.searchPlaylist("起风了") returns -1 (not found)
2. AVPlayerManager defaults to index 0: plays playlist[0]
3. Continues with normal flow

## Error Handling

### URI Parsing Errors
- **Malformed URI:** Log error, show user-friendly toast message, navigate to main page
- **Missing required parameters:** Log warning, navigate to main page with toast

### Song Search Errors
- **Song not found:** Silently fallback to first song (no error shown to user)
- **Empty playlist:** Log error, show toast message, navigate to main page

### Playback Errors
- **Player initialization failures:** Use existing error handling in AVPlayerManager
- **Network download errors:** Use existing retry/fallback logic in AVPlayerManager

### Navigation Errors
- **Playnow page not found:** Log error, keep user on current page, show toast
- **Router failures:** Log error, attempt to stay on current page

### General Approach
- Never crash the app due to deeplink errors
- Always provide user feedback via toast messages
- Graceful degradation: if something fails, fall back to safe default
- Comprehensive logging for debugging

## Testing Strategy

### Manual Testing Scenarios

1. **Valid song name:** `mymusic://play?song=起风了` → Should play "起风了" and show Playnow page
2. **Invalid song name:** `mymusic://play?song=不存在的歌` → Should play first song and show Playnow page
3. **Missing parameter:** `mymusic://play` → Should show toast and navigate to main page
4. **Malformed URI:** `mymusic://invalid` → Should show toast and navigate to main page
5. **Cold start:** App completely closed → Click deeplink → Should start app and play song
6. **Warm start:** App running in background → Click deeplink → Should bring to foreground and play song

### Testing Methods
- Use HarmonyOS simulator's `adb shell am start` commands
- Test from browser by creating HTML links with `mymusic://` scheme
- Test QR code scanning apps that can detect custom URI schemes
- Test from other apps using share sheets

### Edge Cases to Test
- Song names with special characters (spaces, Chinese characters)
- URL encoding scenarios
- Multiple rapid deeplink clicks
- Deeplink during active playback

## Implementation Notes

### Files to Modify
1. `entry/src/main/module.json5` - Add skills configuration for URI scheme
2. `entry/src/main/ets/entryability/EntryAbility.ets` - Add deeplink handling
3. `entry/src/main/ets/services/avplayermanager.ets` - Add playSongByName method

### Files to Create
1. `entry/src/main/ets/services/deeplinkHandler.ets` - New centralized deeplink service

### Backward Compatibility
- No breaking changes to existing functionality
- All existing features continue to work as before
- Deeplink is purely additive functionality

### Future Extensibility
- DeeplinkHandler designed to support additional deeplink types
- Easy to add new actions like `mymusic://playlist?id=123`
- Can extend to support artist-based playback, album playback, etc.

## Success Criteria

- Users can play songs by clicking `mymusic://play?song=<name>` links
- Invalid song names gracefully fallback to first song
- Works reliably in both cold start and warm start scenarios
- No crashes or app instability from malformed deeplinks
- Clean, maintainable code that's easy to extend for future deeplink types
