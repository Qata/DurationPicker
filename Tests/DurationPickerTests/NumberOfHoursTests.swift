/// MIT License
///
/// Copyright (c) 2023 Mac Gallagher
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.

@testable import DurationPicker
import XCTest

/// Coverage for `DurationPicker.numberOfHours` — the configurable upper
/// bound on the hour wheel. Default behavior (24) must remain unchanged
/// for backwards compatibility; raising it must let the picker accept
/// durations longer than a day; lowering it must clamp accordingly.
final class NumberOfHoursTests: XCTestCase {

  private var durationPicker: DurationPicker!

  override func setUp() {
    super.setUp()
    durationPicker = DurationPicker()
  }

  // MARK: - Default behavior

  /// A freshly initialized picker keeps the historical 24-hour cap so
  /// existing call sites are unaffected by the new property.
  func testDefaultNumberOfHoursIsTwentyFour() {
    XCTAssertEqual(durationPicker.numberOfHours, 24)
  }

  /// Setting a duration of 24h on a default picker clamps to 23:59:59
  /// (the legacy absolute maximum).
  func testDefaultPickerClampsAtTwentyThreeFiftyNineFiftyNine() {
    durationPicker.pickerMode = .hourMinuteSecond
    durationPicker.duration = TimeInterval(twentyFourHoursInt)
    XCTAssertEqual(
      durationPicker.duration,
      TimeInterval(
        TimeUtils.seconds(fromHours: 23, minutes: 59, seconds: 59)))
  }

  // MARK: - Raising the cap

  /// Raising `numberOfHours` to 48 lets the picker store and read back a
  /// duration past the 24-hour mark.
  func testRaisingNumberOfHoursAcceptsLongerDuration() {
    durationPicker.pickerMode = .hourMinuteSecond
    durationPicker.numberOfHours = 48
    let target = TimeUtils.seconds(fromHours: 30, minutes: 15, seconds: 5)
    durationPicker.duration = TimeInterval(target)
    XCTAssertEqual(durationPicker.duration, TimeInterval(target))
  }

  /// 1 week (168h) — exercises a much larger upper bound to confirm
  /// nothing relies on the hour count being small.
  func testNumberOfHoursOneWeek() {
    durationPicker.pickerMode = .hour
    durationPicker.numberOfHours = 168
    let target = TimeUtils.seconds(fromHours: 167)
    durationPicker.duration = TimeInterval(target)
    XCTAssertEqual(durationPicker.duration, TimeInterval(target))
  }

  /// With a raised cap, a duration just above 24h round-trips intact
  /// instead of getting silently clamped to 23:59:59.
  func testRaisingNumberOfHoursDoesNotClampAtTwentyFour() {
    durationPicker.pickerMode = .hourMinuteSecond
    durationPicker.numberOfHours = 48
    let target = TimeUtils.seconds(fromHours: 24, minutes: 0, seconds: 1)
    durationPicker.duration = TimeInterval(target)
    XCTAssertEqual(durationPicker.duration, TimeInterval(target))
  }

  // MARK: - Lowering the cap

  /// Lowering `numberOfHours` to 12 clamps any duration ≥ 12h down to
  /// the new absolute maximum of 11:59:59.
  func testLoweringNumberOfHoursClampsExistingDuration() {
    durationPicker.pickerMode = .hourMinuteSecond
    durationPicker.duration = TimeInterval(thirteenHoursInt)
    durationPicker.numberOfHours = 12
    XCTAssertEqual(
      durationPicker.duration,
      TimeInterval(
        TimeUtils.seconds(fromHours: 11, minutes: 59, seconds: 59)))
  }

  /// Setting a duration above the new ceiling clamps to that ceiling.
  func testLowerCeilingClampsNewDuration() {
    durationPicker.pickerMode = .hourMinuteSecond
    durationPicker.numberOfHours = 6
    durationPicker.duration = TimeInterval(twentyThreeHoursInt)
    XCTAssertEqual(
      durationPicker.duration,
      TimeInterval(
        TimeUtils.seconds(fromHours: 5, minutes: 59, seconds: 59)))
  }

  // MARK: - Clamping the property itself

  /// Non-positive values are clamped to 1 — the picker always has at
  /// least one hour row to render.
  func testNumberOfHoursIsClampedToAtLeastOne() {
    durationPicker.numberOfHours = 0
    XCTAssertEqual(durationPicker.numberOfHours, 1)

    durationPicker.numberOfHours = -10
    XCTAssertEqual(durationPicker.numberOfHours, 1)
  }

  // MARK: - hourInterval interaction

  /// `hourInterval = 24` is rejected on a default picker (interval >
  /// numberOfHours / 2) but valid once `numberOfHours = 48`.
  func testHourIntervalValidationUsesNumberOfHours() {
    durationPicker.pickerMode = .hour

    durationPicker.hourInterval = 24
    XCTAssertEqual(
      durationPicker.hourInterval, 1,
      "Default picker (numberOfHours=24): interval=24 is invalid (> 24/2), should fall back to 1")

    durationPicker.numberOfHours = 48
    durationPicker.hourInterval = 24
    XCTAssertEqual(
      durationPicker.hourInterval, 24,
      "With numberOfHours=48: interval=24 is valid (<= 48/2 and 48.isMultiple(of: 24))")
  }

  /// `hourInterval = 12` should remain valid across both default and
  /// raised configurations (since 24/2 ≥ 12 and 48/2 ≥ 12).
  func testHourIntervalTwelveValidAtBothCaps() {
    durationPicker.pickerMode = .hour

    durationPicker.hourInterval = 12
    XCTAssertEqual(durationPicker.hourInterval, 12)

    durationPicker.numberOfHours = 48
    XCTAssertEqual(durationPicker.hourInterval, 12)
  }

  // MARK: - Idempotency

  /// Setting `numberOfHours` to its current value is a no-op (no
  /// duration mutation, no spurious refresh).
  func testSettingSameNumberOfHoursIsNoOp() {
    durationPicker.pickerMode = .hourMinuteSecond
    durationPicker.duration = TimeInterval(thirteenHoursInt)
    let before = durationPicker.duration
    durationPicker.numberOfHours = 24
    XCTAssertEqual(durationPicker.duration, before)
  }
}
