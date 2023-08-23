# HackersJP

A Hacker News app for Japanese readers.

## Development

### What works
- Viewing top 30 stories
- Opening stories with URLs
- Automatic translation of story titles to Japanese using Google's ML Kit

### What's planned
- Support for other HN sorts
- Support for viewing comments
- Viewing Jobs and Show HN articles
- Paginated scrolling

## Building

### Step 1: Update CocoaPods

You will need to install CocoaPods to build this project.
The below command will clean up and re-install all CocoaPods in the project directory.

```
pod deintegrate
pod update
```

### Step 2: Build with Xcode

Once all CocoaPods have installed without any errors, open Xcode to build the project.
