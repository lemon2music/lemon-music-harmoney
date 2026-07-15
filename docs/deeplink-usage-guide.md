# Lemon Music Deeplink Usage Guide

## Overview

Lemon Music supports deep linking, allowing external sources (websites, QR codes, other apps) to directly play songs in the app.

## URI Scheme Format

```
mymusic://play?song=<song_name>
```

### Parameters

- `song` (required): The name of the song to play
  - Must be URL-encoded if contains special characters
  - Must match exactly (case-sensitive) with song names in the app

## Examples

### Valid Examples

1. **Chinese Song Name**
   ```
   mymusic://play?song=起风了
   ```

2. **English Song Name**
   ```
   mymusic://play?song=Catch My Breath
   ```

3. **URL Encoded (recommended for spaces)**
   ```
   mymusic://play?song=Catch%20My%20Breath
   ```

### Invalid Examples

1. **Missing Parameter**
   ```
   mymusic://play
   ```
   → Error: "Invalid deeplink format"

2. **Empty Song Name**
   ```
   mymusic://play?song=
   ```
   → Error: "Invalid deeplink format"

3. **Malformed URI**
   ```
   mymusic://invalid
   ```
   → Error: "Invalid deeplink format"

## Behavior

### Successful Playback
1. App launches or comes to foreground
2. Searches playlist for matching song
3. If found: plays the song
4. If not found: falls back to first song
5. Navigates to Playnow page with full player UI

### Error Handling
- Invalid URI format: Shows error toast, navigates to main page
- Song not found: Silently plays first song (no error message)
- Playlist empty: Shows error toast, navigates to main page
- Navigation failure: Shows error toast, stays on current page

## Integration Examples

### HTML Link
```html
<a href="mymusic://play?song=起风了">Play Song in Lemon Music</a>
```

### QR Code Generation
Use any QR code generator with the deeplink as the data:
```
mymusic://play?song=起风了
```

### From Another App
```typescript
// Example: Opening from another HarmonyOS app
const want = {
  action: 'ohos.want.action.viewData',
  uri: 'mymusic://play?song=起风于'
};
// Start the ability with this want
```

### From Web/Browser
Create HTML links with the custom scheme:
```html
<!DOCTYPE html>
<html>
<body>
  <a href="mymusic://play?song=起风了">Play 起风了</a>
</body>
</html>
```

## Testing

Use the included test files:
- `test_deeplinks.html` - Comprehensive test page with all scenarios
- `test-deeplink-qr.html` - QR code test page for scanning

## Available Songs

Current playlist includes:
- 起风了
- 篝火旁
- 室内系的
- 在你的身边
- 春娇与志明
- 青丝
- 你从未离去
- 烟火里的尘埃
- 画离弦 (坐骑版)
- 偏爱
- 褪黑素
- 悬溺
- 唯一
- 大雪
- Catch My Breath
- 此生不换

## Troubleshooting

### Deeplink Not Working
1. Ensure app is installed
2. Check URI format is correct
3. Verify song name matches exactly (case-sensitive)
4. Check device logs for error messages

### App Crashes
- Check device/emulator logs using `hdc shell hilog`
- Look for error messages with [DeeplinkHandler] or [AVPlayerManager] tags

### Song Not Playing
- Verify song exists in current playlist
- Check network connection for online songs
- Ensure AVPlayer initialized successfully

## Developer Notes

For implementation details, see:
- Design: `docs/superpowers/specs/2025-01-13-deeplink-design.md`
- Implementation Plan: `docs/superpowers/plans/2025-01-13-deeplink-implementation.md`
