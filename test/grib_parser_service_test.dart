import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/grib_parser_service.dart';

import 'test_helpers/grib_test_fixtures.dart';

/// #243: GRIB2 parser core. No maintained Dart GRIB package exists
/// (confirmed via a live pub.dev search before implementing), and a
/// suitably small, scope-fitting real-world sample wasn't reliably
/// available without downloading and inspecting an unknown file — the
/// issue's own acceptance criteria explicitly sanctions a hand-constructed
/// fixture as the fallback. Every byte offset used by [buildGrib2] (shared
/// with #244's viewer tests — see test_helpers/grib_test_fixtures.dart)
/// was independently verified against NOAA/ECMWF/WMO documentation before
/// any parser code was written (see grib_parser_service.dart's own doc
/// comment) — this test exercises the real section layout, real IEEE754
/// float encoding, real WMO sign-and-magnitude convention, and real
/// MSB-first bit-packing, just not data from a live model run.
void main() {
  group('parseGrib2 — a hand-constructed but byte-correct message', () {
    test('recovers exact physical wind-speed values from a small regular '
        'grid (simple packing, 8-bit)', () {
      // 3 columns x 2 rows. R=50.0, E=0, D=1 -> Y=(R+X)/10.
      // Row0 (la=10.0): 5.0, 6.0, 7.0 m/s -> X = 0, 10, 20
      // Row1 (la=9.0):  8.0, 9.0, 10.0 m/s -> X = 30, 40, 50
      final bytes = buildGrib2(
        ni: 3,
        nj: 2,
        la1: 10.0,
        lo1: 20.0,
        la2: 9.0,
        lo2: 21.0,
        packedValues: [0, 10, 20, 30, 40, 50],
        refValue: 50.0,
        binaryScale: 0,
        decimalScale: 1,
        bitCount: 8,
      );

      final grid = parseGrib2(bytes);

      expect(grid.ni, 3);
      expect(grid.nj, 2);
      expect(grid.la1, closeTo(10.0, 1e-6));
      expect(grid.lo1, closeTo(20.0, 1e-6));
      expect(grid.la2, closeTo(9.0, 1e-6));
      expect(grid.lo2, closeTo(21.0, 1e-6));
      expect(grid.values, hasLength(6));
      expect(grid.valueAt(0, 0), closeTo(5.0, 1e-6));
      expect(grid.valueAt(0, 1), closeTo(6.0, 1e-6));
      expect(grid.valueAt(0, 2), closeTo(7.0, 1e-6));
      expect(grid.valueAt(1, 0), closeTo(8.0, 1e-6));
      expect(grid.valueAt(1, 1), closeTo(9.0, 1e-6));
      expect(grid.valueAt(1, 2), closeTo(10.0, 1e-6));
      expect(grid.parameterCategory, 2);
      expect(grid.parameterNumber, 2);
    });

    test('latForRow/lonForCol interpolate correctly across the grid', () {
      final bytes = buildGrib2(
        ni: 3,
        nj: 2,
        la1: 10.0,
        lo1: 20.0,
        la2: 9.0,
        lo2: 21.0,
        packedValues: [0, 10, 20, 30, 40, 50],
        refValue: 50.0,
        binaryScale: 0,
        decimalScale: 1,
        bitCount: 8,
      );
      final grid = parseGrib2(bytes);
      expect(grid.latForRow(0), closeTo(10.0, 1e-6));
      expect(grid.latForRow(1), closeTo(9.0, 1e-6));
      expect(grid.lonForCol(0), closeTo(20.0, 1e-6));
      expect(grid.lonForCol(1), closeTo(20.5, 1e-6));
      expect(grid.lonForCol(2), closeTo(21.0, 1e-6));
    });

    test('a negative binary scale factor round-trips correctly (exercises '
        'the sign-and-magnitude decode for a real negative value, not '
        'just the always-positive default case)', () {
      // E=-2 halves the packed step twice: Y=(R+X*2^-2)/10^0=(R+X/4).
      final bytes = buildGrib2(
        ni: 2,
        nj: 1,
        la1: 0.0,
        lo1: 0.0,
        la2: 0.0,
        lo2: 1.0,
        packedValues: [0, 8],
        refValue: 10.0,
        binaryScale: -2,
        decimalScale: 0,
        bitCount: 8,
      );
      final grid = parseGrib2(bytes);
      expect(grid.valueAt(0, 0), closeTo(10.0, 1e-6)); // (10 + 0/4)
      expect(grid.valueAt(0, 1), closeTo(12.0, 1e-6)); // (10 + 8/4)
    });

    test('a bit-depth that crosses byte boundaries (12-bit) unpacks '
        'correctly — proves the bit reader, not just byte-aligned cases',
        () {
      // 4 points, 12 bits each = 6 bytes total, deliberately misaligned.
      final bytes = buildGrib2(
        ni: 2,
        nj: 2,
        la1: 0.0,
        lo1: 0.0,
        la2: -1.0,
        lo2: 1.0,
        packedValues: [0, 1000, 2000, 4095],
        refValue: 0.0,
        binaryScale: 0,
        decimalScale: 2,
        bitCount: 12,
      );
      final grid = parseGrib2(bytes);
      expect(grid.valueAt(0, 0), closeTo(0.0, 1e-6));
      expect(grid.valueAt(0, 1), closeTo(10.0, 1e-6));
      expect(grid.valueAt(1, 0), closeTo(20.0, 1e-6));
      expect(grid.valueAt(1, 1), closeTo(40.95, 1e-6));
    });

    test('bitCount=0 (constant field) returns the reference value at '
        'every point with no packed data', () {
      final bytes = buildGrib2(
        ni: 2,
        nj: 2,
        la1: 0.0,
        lo1: 0.0,
        la2: -1.0,
        lo2: 1.0,
        packedValues: const [],
        refValue: 42.0,
        binaryScale: 0,
        decimalScale: 0,
        bitCount: 0,
      );
      final grid = parseGrib2(bytes);
      expect(grid.values, everyElement(closeTo(42.0, 1e-6)));
    });
  });

  group('parseGrib2 — malformed/unsupported input fails clearly', () {
    Uint8List validMessage() => buildGrib2(
          ni: 2,
          nj: 2,
          la1: 1.0,
          lo1: 1.0,
          la2: 0.0,
          lo2: 2.0,
          packedValues: [0, 1, 2, 3],
          refValue: 0.0,
          binaryScale: 0,
          decimalScale: 0,
          bitCount: 8,
        );

    test('rejects a buffer with no "GRIB" magic', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      expect(() => parseGrib2(bytes), throwsA(isA<GribParseException>()));
    });

    test('rejects a non-GRIB2 edition byte', () {
      final bytes = validMessage();
      bytes[7] = 1; // claim GRIB1
      expect(() => parseGrib2(bytes), throwsA(isA<GribParseException>()));
    });

    test('rejects a truncated message (cut off mid-section)', () {
      final bytes = validMessage();
      final truncated = Uint8List.sublistView(bytes, 0, bytes.length - 20);
      expect(
          () => parseGrib2(truncated), throwsA(isA<GribParseException>()));
    });

    test('rejects a missing "7777" end marker', () {
      final bytes = validMessage();
      bytes[bytes.length - 1] = 0x00; // corrupt the end marker
      expect(() => parseGrib2(bytes), throwsA(isA<GribParseException>()));
    });

    test('never crashes reading past the buffer on a bogus declared '
        'message length', () {
      final bytes = validMessage();
      // Claim a total length far larger than the actual buffer.
      final bd = ByteData.sublistView(bytes);
      bd.setUint64(8, 999999, Endian.big);
      expect(() => parseGrib2(bytes), throwsA(isA<GribParseException>()));
    });
  });
}
