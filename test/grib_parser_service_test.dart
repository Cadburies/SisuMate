import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/grib_parser_service.dart';

/// #243: GRIB2 parser core. No maintained Dart GRIB package exists
/// (confirmed via a live pub.dev search before implementing), and a
/// suitably small, scope-fitting real-world sample wasn't reliably
/// available without downloading and inspecting an unknown file — the
/// issue's own acceptance criteria explicitly sanctions a hand-constructed
/// fixture as the fallback. Every byte offset used to build [_buildGrib2]
/// below was independently verified against NOAA/ECMWF/WMO documentation
/// before any parser code was written (see grib_parser_service.dart's own
/// doc comment) — this test exercises the real section layout, real
/// IEEE754 float encoding, real WMO sign-and-magnitude convention, and
/// real MSB-first bit-packing, just not data from a live model run.
void main() {
  List<int> u16(int v) => [(v >> 8) & 0xFF, v & 0xFF];
  List<int> u32(int v) => [
        (v >> 24) & 0xFF,
        (v >> 16) & 0xFF,
        (v >> 8) & 0xFF,
        v & 0xFF,
      ];
  List<int> signMag16(int v) =>
      u16(v < 0 ? (v.abs() | 0x8000) : v.abs());
  List<int> signMag32(int v) =>
      u32(v < 0 ? (v.abs() | 0x80000000) : v.abs());
  List<int> float32Bytes(double v) {
    final bd = ByteData(4);
    bd.setFloat32(0, v, Endian.big);
    return bd.buffer.asUint8List();
  }

  /// Builds a well-formed single-message GRIB2 byte stream: Grid
  /// Definition Template 3.0, Product Definition Template 4.0, Data
  /// Representation Template 5.0 (simple packing), no bit-map.
  Uint8List buildGrib2({
    required int ni,
    required int nj,
    required double la1,
    required double lo1,
    required double la2,
    required double lo2,
    required List<int> packedValues,
    required double refValue,
    required int binaryScale,
    required int decimalScale,
    required int bitCount,
    int parameterCategory = 2,
    int parameterNumber = 2,
  }) {
    final s1 = <int>[
      ...u32(21), 1, // length, section#
      ...u16(0), ...u16(0), // center, subcenter
      2, 0, 0, // master table, local table, significance
      ...u16(2026), 8, 4, 0, 0, 0, // year, month, day, h, m, s
      0, 1, // production status, data type
    ];

    final s3Body = <int>[
      3, // section#
      0, // source of grid definition
      ...u32(ni * nj), // number of data points
      0, 0, // octets for list, interpretation
      ...u16(0), // grid definition template number (3.0)
      6, // shape of earth
      0, ...u32(0), // scale + scaled radius
      0, ...u32(0), // scale + scaled major
      0, ...u32(0), // scale + scaled minor
      ...u32(ni),
      ...u32(nj),
      ...u32(0), // basic angle
      ...u32(0), // subdivisions
      ...signMag32((la1 * 1e6).round()),
      ...u32((lo1 * 1e6).round()),
      0, // resolution/component flags
      ...signMag32((la2 * 1e6).round()),
      ...u32((lo2 * 1e6).round()),
      ...u32(0), // Di (unused by this parser)
      ...u32(0), // Dj (unused by this parser)
      0x00, // scanning mode
    ];
    final s3 = <int>[...u32(s3Body.length + 4), ...s3Body];

    final s4Body = <int>[
      4, // section#
      ...u16(0), // number of coordinate values
      ...u16(0), // product definition template number (4.0)
      parameterCategory,
      parameterNumber,
      0, // type of generating process
      0, // background generating process
      0, // analysis/forecast generating process
      ...u16(0), 0, // hours/minutes cutoff
      0, // indicator of unit of time range
      ...u32(0), // forecast time
      1, 0, ...u32(10), // type/scale/value of first fixed surface (10m)
      255, 0, ...u32(0), // type/scale/value of second fixed surface (none)
    ];
    final s4 = <int>[...u32(s4Body.length + 4), ...s4Body];

    final s5Body = <int>[
      5, // section#
      ...u32(ni * nj), // number of data points
      ...u16(0), // data representation template number (5.0)
      ...float32Bytes(refValue),
      ...signMag16(binaryScale),
      ...signMag16(decimalScale),
      bitCount,
      0, // type of original field values (floating point)
    ];
    final s5 = <int>[...u32(s5Body.length + 4), ...s5Body];

    final s6 = <int>[...u32(6), 6, 255]; // no bit-map

    // Pack packedValues (each < 2^bitCount) MSB-first into bytes.
    final packedBits = <int>[];
    var acc = 0;
    var accBits = 0;
    for (final x in packedValues) {
      acc = (acc << bitCount) | x;
      accBits += bitCount;
      while (accBits >= 8) {
        final shift = accBits - 8;
        packedBits.add((acc >> shift) & 0xFF);
        accBits -= 8;
        acc &= (1 << accBits) - 1;
      }
    }
    if (accBits > 0) {
      packedBits.add((acc << (8 - accBits)) & 0xFF);
    }
    final s7Body = <int>[7, ...packedBits];
    final s7 = <int>[...u32(s7Body.length + 4), ...s7Body];

    final sections = [...s1, ...s3, ...s4, ...s5, ...s6, ...s7];
    final totalLength = 16 + sections.length + 4;

    final message = <int>[
      0x47, 0x52, 0x49, 0x42, // "GRIB"
      0, 0, // reserved
      0, // discipline
      2, // edition
      ...List.filled(4, 0), ...u32(totalLength), // 8-byte total length
      ...sections,
      0x37, 0x37, 0x37, 0x37, // "7777"
    ];
    return Uint8List.fromList(message);
  }

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
