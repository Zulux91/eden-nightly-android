<h1 align="left">
  <br>
  <b>Unofficial Eden Nightly Release</b>
  <br>
</h1>

[![GitHub Release](https://img.shields.io/github/v/release/Zulux91/eden-nightly-android?label=Current%20Release)](https://github.com/Zulux91/eden-nightly-android/releases/latest)
[![GitHub Downloads](https://img.shields.io/github/downloads/Zulux91/eden-nightly-android/total?logo=github&label=GitHub%20Downloads)](https://github.com/Zulux91/eden-nightly-android/releases/latest)
[![CI Build Status](https://github.com//Zulux91/eden-nightly-android/actions/workflows/build.yml/badge.svg)](https://github.com/Zulux91/eden-nightly-android/releases/latest)

> [!NOTE]  
> This repo uses the code from pflyly's [eden-nightly repo](https://github.com/pflyly/eden-nightly).
---------------------------------------------------------------
## How to add this version to your ES-DE instance
Assuming you already have custom systems do this:
- Search for `EDEN` in your `es_find_rules.xml` file.
- Above `<emulator name="EDEN">` paste: 
```xml
<emulator name="EDEN-NIGHTLY">
		<!-- Nintendo Switch emulator Eden Nightly build -->
		<rule type="androidpackage">			
			<entry>dev.eden.eden_emulator.nightly/org.yuzu.yuzu_emu.activities.EmulationActivity</entry>
		</rule>
	</emulator>
```
- Save the changes.
- Then in your `es_systems.xml` file search for `Eden (Standalone)`.
- Make a new line below the string you just searched and paste:
```xml
<command label="Eden (Standalone-Nightly)">%EMULATOR_EDEN-NIGHTLY% %ACTION%=android.nfc.action.TECH_DISCOVERED %DATA%=%ROMPROVIDER%</command>
```
- Save the changes and you're good to go.

## Release Overview

This repository provides **unofficial nightly releases** of **Eden** only for android.

>[!WARNING]
>**This repository is not affiliated with the official Eden development team. It exists solely to provide an easy way for users to try out the latest features from recent commits.**
>
>**These builds are experimental and may be unstable. Use them at your own risk, and please do not report issues from these builds to the official channels unless confirmed on official releases.**

---------------------------------------------------------------

### 🤖 Android Builds

Eden nightly for Android is available in two versions:

- **Replace** Build
  
Shares the same application ID as the official Eden release. Installing this version will replace the official app on your device. It appears as "**eden**" on the home screen.

- **Coexist** Build
  
Uses a nightly application ID, allowing it to coexist with the official Eden release. It appears as "**eden unofficial**" on the home screen, and "**Eden Unofficial**" on the main screen of eden.

- **Optimised** Build
  
Using com.miHoYo.Yuanshen for application ID to enable device dependent features such as AI frame generation. It appears as "**eden Optimised**" on the home screen.

---------------------------------------------------------------


* [**Latest Nightly Release Here**](https://github.com/Zulux91/eden-nightly-android/releases/latest)


---------------------------------------------------------------
