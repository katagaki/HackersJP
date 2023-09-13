# HackersJP

![Banner image depicting the Hackers app showing lists of stories and comments.](github/banner.png?raw=true "Hackers")

A Hacker News app for Japanese readers.

**Download: [App Store](https://apps.apple.com/app/id6463075798)**

## Development

### What works
- Viewing top 30 stories
- Viewing Jobs and Show HN articles
- Support for other HN sorts
- Support for viewing comments
- Opening story URLs
- Sharing story and HN URLs
- Automatic translation of story titles to Japanese using Google's ML Kit

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
