/*
 * Zmanim Java API
 * Copyright (C) 2011-2020 Eliyahu Hershfeld
 *
 * This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General
 * Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option)
 * any later version.
 *
 * This library is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
 * details.
 * You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA,
 * or connect to: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
 */

import 'dart:core';
import 'package:kosher_dart/src/hebrewcalendar/daf.dart';
import 'package:kosher_dart/src/hebrewcalendar/jewish_calendar.dart';

/// This class calculates the Daf Yomi Bavli page (daf) for a given date. To calculate Daf Yomi Yerushalmi
/// use the {@link YerushalmiYomiCalculator}. The library may cover Mishna Yomi etc. at some point in the future.
///
/// @author &copy; Bob Newell (original C code)
/// @author &copy; Eliyahu Hershfeld 2011 - 2020
class YomiCalculator {
  static final DateTime _dafYomiStartDay =
      DateTime(1923, DateTime.september, 11);

  /// The start date of the first Daf Yomi Bavli cycle in the Julian calendar. Used internally for claculations.
  static final int _dafYomiJulianStartDay = _getJulianDay(_dafYomiStartDay);

  ///The date that the pagination for the Daf Yomi <em>Maseches Shekalim</em> changed to use the commonly used Vilna
  ///Shas pagination from the no longer commonly available Zhitomir / Slavuta Shas used by Rabbi Meir Shapiro.
  static final DateTime _shekalimChangeDay = DateTime(1975, DateTime.june, 24);

  ///  The Julian date that the cycle for Shekalim changed.
  /// @see #getDafYomiBavli(JewishCalendar) for details.
  static final int shekalimJulianChangeDay = _getJulianDay(_shekalimChangeDay);

  /// Returns the <a href="http://en.wikipedia.org/wiki/Daf_yomi">Daf Yomi</a> <a
  /// href="http://en.wikipedia.org/wiki/Talmud">Bavli</a> {@link Daf} for a given date. The first Daf Yomi cycle
  /// started on Rosh Hashana 5684 (September 11, 1923) and calculations prior to this date will result in an
  /// IllegalArgumentException thrown. For historical calculations (supported by this method), it is important to note
  /// that a change in length of the cycle was instituted starting in the eighth Daf Yomi cycle beginning on June 24,
  /// 1975. The Daf Yomi Bavli cycle has a single masechta of the Talmud Yerushalmi - Shekalim as part of the cycle.
  /// Unlike the Bavli where the number of daf per masechta was standardized since the original <a
  /// href="http://en.wikipedia.org/wiki/Daniel_Bomberg">Bomberg Edition</a> published from 1520 - 1523, there is no
  /// uniform page length in the Yerushalmi. The early cycles had the Yerushalmi Shekalim length of 13 days following the
  /// <a href=
  /// "https://he.wikipedia.org/wiki/%D7%93%D7%A4%D7%95%D7%A1_%D7%A1%D7%9C%D7%90%D7%95%D7%95%D7%99%D7%98%D7%90">Slavuta/Zhytomyr</a>
  /// Shas used by <a href="http://en.wikipedia.org/wiki/Meir_Shapiro">Rabbi Meir Shapiro</a>. With the start of the eighth Daf Yomi
  /// cycle beginning on June 24, 1975 the length of the Yerushalmi Shekalim was changed from 13 to 22 daf to follow
  /// the <a href="https://en.wikipedia.org/wiki/Vilna_Edition_Shas">Vilna Shas</a> that is in common use today.
  ///
  /// @param jewishCalendar
  ///            The JewishCalendar date for calculation. TODO: this can be changed to use a regular GregorianCalendar since
  ///            there is nothing specific to the JewishCalendar in this class.
  /// @return the {@link Daf}.
  ///
  /// @throws IllegalArgumentException
  ///             if the date is prior to the September 11, 1923 start date of the first Daf Yomi cycle
  static Daf getDafYomiBavli(JewishCalendar jewishCalendar) {
    /*
		 * The number of daf per masechta. Since the number of blatt in Shekalim changed on the 8th Daf Yomi cycle
		 * beginning on June 24, 1975 from 13 to 22, the actual calculation for blattPerMasechta[4] will later be
		 * adjusted based on the cycle.
		 */
    List<int> blattPerMasechta = [
      64,
      157,
      105,
      121,
      22,
      88,
      56,
      40,
      35,
      31,
      32,
      29,
      27,
      122,
      112,
      91,
      66,
      49,
      90,
      82,
      119,
      119,
      176,
      113,
      24,
      49,
      76,
      14,
      120,
      110,
      142,
      61,
      34,
      34,
      28,
      22,
      4,
      9,
      5,
      73
    ];
    DateTime dateTime = jewishCalendar.getGregorianCalendar();

    Daf dafYomi = Daf(0, 0);
    int julianDay = _getJulianDay(dateTime);
    int cycleNo = 0;
    int dafNo = 0;
    if (dateTime.isBefore(_dafYomiStartDay)) {
      // TODO: should we return a null or throw an IllegalArgumentException?
      throw ArgumentError(dateTime.toString() +
          " is prior to organized Daf Yomi Bavli cycles that started on " +
          _dafYomiStartDay.toString());
    }
    if (dateTime.isAtSameMomentAs(_shekalimChangeDay) ||
        dateTime.isAfter(_shekalimChangeDay)) {
      cycleNo = 8 + ((julianDay - shekalimJulianChangeDay) ~/ 2711);
      dafNo = ((julianDay - shekalimJulianChangeDay) % 2711);
    } else {
      cycleNo = 1 + ((julianDay - _dafYomiJulianStartDay) ~/ 2702);
      dafNo = ((julianDay - _dafYomiJulianStartDay) % 2702);
    }

    int total = 0;
    int masechta = -1;
    int blatt = 0;

    // Fix Shekalim for old cycles.
    if (cycleNo <= 7) {
      blattPerMasechta[4] = 13;
    } else {
      blattPerMasechta[4] =
          22; // correct any change that may have been changed from a prior calculation
    }
    // Finally find the daf.
    for (int j = 0; j < blattPerMasechta.length; j++) {
      masechta++;
      total = total + blattPerMasechta[j] - 1;
      if (dafNo < total) {
        blatt = 1 + blattPerMasechta[j] - (total - dafNo);
        // Fiddle with the weird ones near the end.
        if (masechta == 36) {
          blatt += 21;
        } else if (masechta == 37) {
          blatt += 24;
        } else if (masechta == 38) {
          blatt += 32;
        }
        dafYomi = Daf(masechta, blatt);
        break;
      }
    }

    return dafYomi;
  }

  /// Return the <a href="http://en.wikipedia.org/wiki/Julian_day">Julian day</a> from a Java Calendar.
  ///
  /// @param calendar
  ///            The Java Calendar of the date to be calculated
  /// @return the Julian day number corresponding to the date
  static int _getJulianDay(DateTime dateTime) {
    int year = dateTime.year;
    int month = dateTime.month;
    int day = dateTime.day;
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    int a = year ~/ 100;
    int b = 2 - a + a ~/ 4;
    return ((365.25 * (year + 4716)).floor() +
            (30.6001 * (month + 1)).floor() +
            day +
            b -
            1524.5)
        .toInt();
  }
}
