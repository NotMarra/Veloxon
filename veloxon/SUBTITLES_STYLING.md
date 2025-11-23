# Subtitle Styling - Documentation

## Overview

The Veloxon player now automatically recognizes and applies subtitle styling based on their format:

- **ASS/SSA subtitles**: Use custom styling defined in `.ass` or `.ssa` files
- **SRT subtitles**: Use uniform, preset styling

## Implementation

### 1. ASS Parser (`lib/utils/ass_parser.dart`)

Parser for ASS/SSA subtitles that extracts the following styling information:

- **Font name**
- **Font size**
- **Color** - conversion from ASS format `&HAABBGGRR` to Flutter Color
- **Alignment** - conversion from numpad notation (1-9) to TextAlign
- **Padding** - based on vertical position (top/middle/bottom)

#### Usage example:

```dart
final assContent = await File('subtitles.ass').readAsString();
final assStyle = AssParser.parseStyle(assContent);

// Use in TextStyle
final textStyle = assStyle.toTextStyle();
```

### 2. Automatic Subtitle Format Detection

The player automatically detects subtitle format based on:

- File extension in the name (`.ass`, `.ssa`)
- Subtitle track name
- Subtitle track language
- Subtitle track ID

### 3. Loading ASS Files

For ASS subtitles, the system tries to find the corresponding file according to these patterns:

```
video.mkv
├── video.ass              # Same name as video
├── video.ssa              # Same name as video (SSA format)
├── video.en.ass           # With language code
├── video.en.ssa           # With language code (SSA format)
└── [track title].ass      # Based on track name
```

### 4. Default (Uniform) Styling for SRT

For SRT and other formats, preset styling is used:

```dart
TextStyle(
  fontSize: 32,
  color: Colors.white,
  fontWeight: FontWeight.bold,
  shadows: [
    Shadow(offset: Offset(1.5, 1.5), blurRadius: 4.0, color: Colors.black),
    Shadow(offset: Offset(-1.5, -1.5), blurRadius: 4.0, color: Colors.black),
  ],
)
```

With default padding:

```dart
EdgeInsets.only(left: 40, right: 40, bottom: 80)
```

## How It Works

1. **Video Loading**: When a video is loaded, the media file path is recorded
2. **Subtitle Selection**: When a subtitle track is selected:
   - Format is detected (ASS vs SRT)
   - For ASS: `.ass` file is searched for and its styling is parsed
   - For SRT: Uniform styling is applied
3. **Style Application**: Styling is passed to the `Video` widget via `SubtitleViewConfiguration`

## ASS Styling Example

### ASS file:

```ass
[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, ...
Style: Default,Arial,48,&H00FFFFFF,...,Alignment:2
```

### Resulting Flutter styling:

```dart
TextStyle(
  fontFamily: 'Arial',
  fontSize: 48,
  color: Colors.white,
  fontWeight: FontWeight.bold,
  shadows: [...]
)
```

## Notes

- ASS files must be in the same folder as the video
- Parser supports ASS format with both `[V4+ Styles]` and `[V4 Styles]` sections
- If ASS loading fails, default uniform styling is used
- For asset files (e.g., `asset:///assets/test.mkv`), loading external ASS files is not supported

## Testing

To test with ASS subtitles:

1. Prepare a video file (e.g., `video.mkv`)
2. Create an ASS file (e.g., `video.ass` or `video.en.ass`)
3. Place both files in the same folder
4. Load the video in the player using `file:///` URI
5. Select ASS subtitles in the player menu

To test with SRT subtitles, simply select an SRT track - uniform styling will be automatically applied.
