import 'dart:math';

import 'package:cupertino_calendar_picker/src/src.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

typedef RangeChangedCallback = void Function(DateTime start, DateTime end);

class CupertinoRangeCalendar extends StatefulWidget {
  CupertinoRangeCalendar({
    required this.startMinimumDateTime,
    required this.endMaximumDateTime,
    required this.startDateTime,
    required this.endDateTime,
    this.mainColor = CupertinoColors.systemRed,
    this.mode = CupertinoCalendarMode.date,
    this.type = CupertinoCalendarType.inline,
    this.onDateTimeChanged,
    this.onDateSelected,
    this.selectableDayPredicate,
    this.currentDateTime,
    this.onDisplayedMonthChanged,
    this.weekdayDecoration,
    this.monthPickerDecoration,
    this.headerDecoration,
    this.footerDecoration,
    this.timeLabel,
    this.minuteInterval = 1,
    this.maxWidth = double.infinity,
    this.use24hFormat,
    this.firstDayOfWeekIndex,
    this.actions,
    this.isRangePicker = false,
    this.onRangeSelected,
    super.key,
  }) {
    // ignore: prefer_asserts_in_initializer_lists
    assert(
      !endDateTime.isBefore(startDateTime),
      'endDateTime $endDateTime must be on or after startDateTime $startDateTime.',
    );
    assert(
      !startDateTime.isBefore(startMinimumDateTime),
      'startDateTime $startDateTime must be on or after startMinimumDateTime $startMinimumDateTime.',
    );
    assert(
      !endDateTime.isAfter(endMaximumDateTime),
      'endDateTime $endDateTime must be on or before endMaximumDateTime $endMaximumDateTime.',
    );
    if (actions != null) {
      assert(
        actions!.isNotEmpty,
        'The actions list must not be empty.',
      );
      assert(
        actions!.length <= 2,
        'The actions list must contain at most two actions.',
      );
      assert(
        type == CupertinoCalendarType.compact,
        'Actions are only available in the compact calendar type.',
      );
    }
  }

  /// The initially selected start [DateTime] that the calendar should display.
  ///
  /// This date is highlighted in the picker and the default date when the picker
  /// is first displayed.
  final DateTime startDateTime;

  /// The initially selected end [DateTime] that the calendar should display.
  ///
  /// This date is highlighted in the picker and the default date when the picker
  /// is first displayed.
  final DateTime endDateTime;

  /// The earliest selectable [DateTime] in the picker.
  ///
  /// This date must be on or before the [endDateTime].
  final DateTime startMinimumDateTime;

  /// The latest selectable [DateTime] in the picker.
  ///
  /// This date must be on or after the [startDateTime].
  final DateTime endMaximumDateTime;

  /// A predicate that determines whether a day is selectable.
  final SelectableDayPredicate? selectableDayPredicate;

  /// The current date (i.e., today's date).
  final DateTime? currentDateTime;

  /// A callback that is triggered whenever the selected [DateTime] changes
  /// in the calendar.
  final ValueChanged<DateTime>? onDateTimeChanged;

  /// A callback that is triggered when the user selects a date in the calendar.
  final ValueChanged<DateTime>? onDateSelected;

  /// A callback that is triggered when the user navigates to a different month in the calendar.
  final ValueChanged<DateTime>? onDisplayedMonthChanged;

  /// Custom decoration for the weekdays' row in the calendar.
  final CalendarWeekdayDecoration? weekdayDecoration;

  /// Custom decoration for the month picker view.
  final CalendarMonthPickerDecoration? monthPickerDecoration;

  /// Custom decoration for the header of the calendar.
  final CalendarHeaderDecoration? headerDecoration;

  /// Custom decoration for the footer of the calendar.
  ///
  /// Applied for the [dateTime] mode only.
  final CalendarFooterDecoration? footerDecoration;

  /// The primary color used in the calendar picker, typically for highlighting
  /// the selected date and other important elements.
  ///
  /// The default color is [CupertinoColors.systemRed].
  final Color mainColor;

  /// The mode in which the picker operates.
  ///
  /// This defines whether the picker allows selection of just the date or both date and time.
  final CupertinoCalendarMode mode;

  /// The type of the calendar, which may define specific behaviors or appearances.
  /// The default type is [CupertinoCalendarType.inline].
  final CupertinoCalendarType type;

  /// The maximum width of the calendar widget.
  ///
  /// The default value is [double.infinity], meaning the widget can expand
  /// to fill available space.
  ///
  /// minWidth is [320].
  final double maxWidth;

  /// An optional label to be displayed when the calendar is in a mode that includes time selection.
  ///
  /// This label typically indicates what the selected time is for or provides additional context.
  final String? timeLabel;

  /// The interval of minutes that the time picker should allow, applicable
  /// when the calendar is in a mode that includes time selection.
  final int minuteInterval;

  /// For 24h format being used or not, results in AM/PM being shown or hidden in the widget.
  /// Setting to `true` or `false` will force 24h format to be on or off.
  /// The default value is null, which calls [MediaQuery.alwaysUse24HourFormatOf].
  ///
  /// Displayed only when the calendar is in a mode that includes time selection.
  final bool? use24hFormat;

  /// The index of the first day of the week, where 0 represents Sunday.
  ///
  /// The default value is based on the locale.
  final int? firstDayOfWeekIndex;

  /// A list of actions that will be displayed at the bottom of the calendar picker.
  ///
  /// Available actions are [CancelCupertinoCalendarAction], [ConfirmCupertinoCalendarAction].
  ///
  /// Displayed only when the calendar is in the [CupertinoCalendarType.compact] mode.
  final List<CupertinoCalendarAction>? actions;

  /// Whether the calendar is a range picker.
  ///
  /// If true, the calendar will allow the user to select a range of dates.
  /// The default value is false.
  final bool isRangePicker;

  /// A callback that is triggered when the user selects a range of dates in the calendar.
  /// The callback is called with the start and end dates of the selected range.
  final RangeChangedCallback? onRangeSelected;

  @override
  State<CupertinoRangeCalendar> createState() => _CupertinoRangeCalendarState();
}

class _CupertinoRangeCalendarState extends State<CupertinoRangeCalendar> {
  late DateTime _currentlyDisplayedMonthDate;
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _initializeInitialDate();
  }

  @override
  void didUpdateWidget(CupertinoRangeCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDateTime != widget.startDateTime ||
        oldWidget.endDateTime != widget.endDateTime) {
      _initializeInitialDate();
    }
  }

  void _initializeInitialDate() {
    final DateTime initialDateTime = widget.startDateTime;
    _currentlyDisplayedMonthDate =
        PackageDateUtils.monthDateOnly(initialDateTime);
    _selectedDateTime = widget.endDateTime;
  }

  void _handleCalendarDateChange(DateTime date) {
    final DateTime dateTime = date.copyWith(
      hour: _selectedDateTime.hour,
      minute: _selectedDateTime.minute,
    );
    final int year = dateTime.year;
    final int month = dateTime.month;
    final int daysInMonth = DateUtils.getDaysInMonth(year, month);
    int selectedDay = _selectedDateTime.day;

    if (daysInMonth < selectedDay) {
      selectedDay = daysInMonth;
    }
    DateTime newDate = dateTime.copyWith(day: selectedDay);

    final bool exceedMinimumDateTime =
        newDate.isBefore(widget.startMinimumDateTime);
    final bool exceedMaximumDateTime =
        newDate.isAfter(widget.endMaximumDateTime);
    if (exceedMinimumDateTime) {
      newDate = widget.startMinimumDateTime;
    } else if (exceedMaximumDateTime) {
      newDate = widget.endMaximumDateTime;
    }
    _handleCalendarMonthChange(newDate);
    _handleCalendarDayChange(newDate);
  }

  void _handleCalendarMonthChange(DateTime newMonthDate) {
    final DateTime displayedMonth = PackageDateUtils.monthDateOnly(
      _currentlyDisplayedMonthDate,
    );
    final bool monthChanged = !DateUtils.isSameMonth(
      displayedMonth,
      newMonthDate,
    );
    if (monthChanged) {
      _currentlyDisplayedMonthDate = PackageDateUtils.monthDateOnly(
        newMonthDate,
      );
      widget.onDisplayedMonthChanged?.call(_currentlyDisplayedMonthDate);
    }
  }

  void _handleCalendarDayChange(DateTime date) {
    setState(() {
      _selectedDateTime = date;
      widget.onDateTimeChanged?.call(_selectedDateTime);
    });
  }

  // Removed unused single-date change handler; range handler is used instead.

  void _onRangeChanged(DateTime start, DateTime end) {
    _handleCalendarDayChange(end);
    widget.onRangeSelected?.call(start, end);
  }

  void _onTimeChanged(DateTime dateTime) {
    _handleCalendarDayChange(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    double height = switch (widget.mode) {
      CupertinoCalendarMode.date => calendarDatePickerHeight,
      CupertinoCalendarMode.dateTime => calendarDateTimePickerHeight,
    };
    final List<CupertinoCalendarAction>? actions = widget.actions;
    final bool withActions = actions != null && actions.isNotEmpty;
    if (withActions) {
      height += calendarActionsHeight;
    }

    const double minWidth = calendarWidth;
    final double maxWidth = max(widget.maxWidth, minWidth);

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: height,
        maxHeight: height,
        minWidth: calendarWidth,
        maxWidth: maxWidth,
      ),
      child: CupertinoRangeCalendarPicker(
        initialMonth: _currentlyDisplayedMonthDate,
        currentDateTime: widget.currentDateTime ?? DateTime.now(),
        minimumDateTime: widget.startMinimumDateTime,
        maximumDateTime: widget.endMaximumDateTime,
        selectedStartDate: widget.startDateTime,
        selectedEndDate: widget.endDateTime,
        selectableDayPredicate: widget.selectableDayPredicate,
        firstDayOfWeekIndex: widget.firstDayOfWeekIndex,
        onRangeChanged: _onRangeChanged,
        onDisplayedMonthChanged: _handleCalendarMonthChange,
        onYearPickerChanged: _handleCalendarDateChange,
        onTimeChanged: _onTimeChanged,
        mainColor: widget.mainColor,
        weekdayDecoration: widget.weekdayDecoration ??
            CalendarWeekdayDecoration.withDynamicColor(context),
        monthPickerDecoration: widget.monthPickerDecoration ??
            CalendarMonthPickerDecoration.withDynamicColor(
              context,
              mainColor: widget.mainColor,
            ),
        headerDecoration: widget.headerDecoration ??
            CalendarHeaderDecoration.withDynamicColor(
              context,
              mainColor: widget.mainColor,
            ),
        footerDecoration: widget.footerDecoration ??
            CalendarFooterDecoration.withDynamicColor(context),
        mode: widget.mode,
        type: widget.type,
        timeLabel: widget.timeLabel,
        minuteInterval: widget.minuteInterval,
        use24hFormat: widget.use24hFormat ?? context.alwaysUse24hFormat,
        actions: widget.actions,
      ),
    );
  }
}
