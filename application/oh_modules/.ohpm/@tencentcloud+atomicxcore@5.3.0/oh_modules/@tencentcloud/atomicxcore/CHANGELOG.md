# Changelog

All notable changes to the AtomicXCore HarmonyOS module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [5.3.0] - 2026-10-29
* Optimized the playback logic of `AtomicLiveView`.
* Fixed an issue where widgets covered the mixed-stream video of on-seat audience members under layout template 601.

## [5.2.2] - 2026-10-22
* Added live streaming APIs: `AtomicPusher`, `AtomicPlayer`, and `AtomicLiveView` with `AtomicLiveController`.
* Added live scenario stores: `LiveListStore`, `LiveAudienceStore`, `LiveSeatStore`, `LiveSummaryStore`, `CoHostStore`, `CoGuestStore`, `BattleStore`, and `LikeStore`.
* Fixed some known issues.

## [5.1.0] - 2026-09-15
* Fixed some known issues.

## [5.0.1] - 2026-08-17
* Added the interfaces and implementations for `RoomStore` and `RoomParticipantStore` in the room scenario.
* Fixed some issues.

## [5.0.0] - 2026-07-23
* Optimized the login module.
* Refactored AtomicXCore and added chat-related features to align with other platforms.
* Fixed several issues in call scenarios.

## [4.2.0] - 2026-06-05
* Added `CallStore` to provide call capabilities.
* Due to architecture upgrade, the implementations of `RoomStore` and `RoomParticipantStore` have been temporarily removed. If you need Room scenarios, please lock to version 4.1.0.

## [4.1.0] - 2026-05-06
* Added `RoomStore` and `RoomParticipantStore` to provide support for audio and video room scenarios.

## [1.0.0] - 2025-11-01
* publish release version

## Support and Feedback

If you encounter any issues or have suggestions for improvements, please:

1. Check the documentation and examples
2. Search existing issues in the repository
3. Create a new issue with detailed information
4. Contact our support team for urgent matters

Thank you for using AtomicXCore for HarmonyOS!