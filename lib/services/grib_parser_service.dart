import 'dart:math' as math;
import 'dart:typed_data';

/// #243: GRIB2 binary parser — pure, no I/O. No maintained Dart GRIB
/// package exists (confirmed via a live pub.dev search before writing
/// this), so this is a from-scratch, deliberately narrow-scope decoder.
///
/// Byte offsets below were verified octet-by-octet against NOAA's NCEP
/// GRIB2 documentation (nco.ncep.noaa.gov/pmb/docs/grib2/grib2_doc) and
/// ECMWF's GRIB2 regulations (codes.ecmwf.int/grib/format/grib2) before
/// writing any parsing code — not assumed from memory alone, matching this
/// codebase's research discipline for anything with real correctness risk.
///
/// **Supported (v1):**
/// - GRIB Edition 2 only (not GRIB1)
/// - Grid Definition Template 3.0 (regular lat/lon grid) only
/// - Product Definition Template 4.0 (analysis/forecast at a point in time)
/// - Data Representation Template 5.0 (simple packing) only
/// - Scanning mode 0x00 only (+i west-to-east, row-major, non-alternating)
/// - No bit-map (Section 6 indicator must be 255)
/// - The first message in the byte stream only (multi-message files: only
///   the first is parsed)
///
/// **Explicitly out of scope for v1** (each a large addition on its own —
/// see #235/#243's own issue text): GRIB1, non-regular grids (rotated,
/// Gaussian, etc.), JPEG2000/PNG/complex/spectral packing, multi-field
/// files. Any of these fail with a clear [GribParseException], never a
/// silent wrong value.
///
/// GRIB2 encodes "signed" integer fields (binary/decimal scale factor,
/// La1/La2) as **sign-and-magnitude**, not two's complement — WMO
/// Regulation 92.1.5: "negative values shall be indicated by setting the
/// most significant bit to '1'". This is the single most common mistake
/// when hand-rolling a GRIB decoder; [_readSignedInt] implements it
/// explicitly rather than relying on a language's native signed-integer
/// read.
class GribParseException implements Exception {
  final String message;
  const GribParseException(this.message);
  @override
  String toString() => 'GribParseException: $message';
}

/// A parsed single-field GRIB2 grid. [values] is row-major (row 0 = the
/// row at [la1]/[lo1]), length `ni * nj`. [parameterCategory]/
/// [parameterNumber] are GRIB2 Table 4.1/4.2 codes — deliberately left as
/// raw ints rather than interpreted here (a pure parser has no business
/// deciding "this means wind speed"); the caller (viewer UI) maps them to
/// something human-readable.
class GribGrid {
  final int ni;
  final int nj;
  final double la1;
  final double lo1;
  final double la2;
  final double lo2;
  final List<double> values;
  final int parameterCategory;
  final int parameterNumber;
  final int forecastTimeUnit;
  final int forecastTime;

  const GribGrid({
    required this.ni,
    required this.nj,
    required this.la1,
    required this.lo1,
    required this.la2,
    required this.lo2,
    required this.values,
    required this.parameterCategory,
    required this.parameterNumber,
    required this.forecastTimeUnit,
    required this.forecastTime,
  });

  double latForRow(int row) =>
      nj <= 1 ? la1 : la1 + (la2 - la1) * row / (nj - 1);

  double lonForCol(int col) =>
      ni <= 1 ? lo1 : lo1 + _lonDelta() / (ni - 1) * col;

  /// Shortest-path longitude delta from lo1 to lo2 — corrects for the
  /// 0/360 wraparound (e.g. lo1=170, lo2=-170 really means +20, not -340).
  double _lonDelta() {
    var d = lo2 - lo1;
    if (d > 180) d -= 360;
    if (d < -180) d += 360;
    return d;
  }

  double valueAt(int row, int col) => values[row * ni + col];
}

double _normalizeLon(double lon) => ((lon + 180) % 360 + 360) % 360 - 180;

/// GRIB2's sign-and-magnitude convention (WMO Regulation 92.1.5) — the
/// most significant bit is a sign flag, not part of a two's-complement
/// value.
int _readSignedInt(ByteData bd, int offset, int byteLength) {
  switch (byteLength) {
    case 2:
      final raw = bd.getUint16(offset, Endian.big);
      return (raw & 0x8000) != 0 ? -(raw & 0x7FFF) : raw;
    case 4:
      final raw = bd.getUint32(offset, Endian.big);
      return (raw & 0x80000000) != 0 ? -(raw & 0x7FFFFFFF) : raw;
    default:
      throw ArgumentError('unsupported signed field length $byteLength');
  }
}

/// Reads N-bit unsigned values (N = [readBits]'s argument) MSB-first
/// across byte boundaries — the packing convention Section 7 uses.
class _BitReader {
  final Uint8List bytes;
  int _byteIndex = 0;
  int _bitOffset = 0;

  _BitReader(this.bytes);

  int readBits(int n) {
    if (n == 0) return 0;
    var value = 0;
    var remaining = n;
    while (remaining > 0) {
      if (_byteIndex >= bytes.length) {
        throw const GribParseException(
            'Unexpected end of data while unpacking Section 7 values');
      }
      final bitsLeftInByte = 8 - _bitOffset;
      final take = remaining < bitsLeftInByte ? remaining : bitsLeftInByte;
      final shift = bitsLeftInByte - take;
      final mask = (1 << take) - 1;
      final bits = (bytes[_byteIndex] >> shift) & mask;
      value = (value << take) | bits;
      _bitOffset += take;
      remaining -= take;
      if (_bitOffset == 8) {
        _bitOffset = 0;
        _byteIndex++;
      }
    }
    return value;
  }
}

({int ni, int nj, double la1, double lo1, double la2, double lo2})
    _parseSection3(ByteData bd, int s) {
  final templateNumber = bd.getUint16(s + 12, Endian.big);
  if (templateNumber != 0) {
    throw GribParseException(
        'Unsupported grid definition template 3.$templateNumber — only '
        '3.0 (regular lat/lon grid) is supported');
  }
  final basicAngle = bd.getUint32(s + 38, Endian.big);
  final subdivisions = bd.getUint32(s + 42, Endian.big);
  if (basicAngle != 0 || subdivisions != 0) {
    throw const GribParseException(
        'Non-default basic angle/subdivisions not supported');
  }
  final ni = bd.getUint32(s + 30, Endian.big);
  final nj = bd.getUint32(s + 34, Endian.big);
  if (ni == 0 || nj == 0) {
    throw const GribParseException('Grid has zero rows or columns');
  }
  final la1Raw = _readSignedInt(bd, s + 46, 4);
  final lo1Raw = bd.getUint32(s + 50, Endian.big);
  final la2Raw = _readSignedInt(bd, s + 55, 4);
  final lo2Raw = bd.getUint32(s + 59, Endian.big);
  final scanningMode = bd.getUint8(s + 71);
  if (scanningMode != 0x00) {
    throw GribParseException(
        'Unsupported scanning mode 0x${scanningMode.toRadixString(16).padLeft(2, '0')} '
        '— only 0x00 (+i west-to-east, row-major) is supported');
  }
  return (
    ni: ni,
    nj: nj,
    la1: la1Raw / 1e6,
    lo1: _normalizeLon(lo1Raw / 1e6),
    la2: la2Raw / 1e6,
    lo2: _normalizeLon(lo2Raw / 1e6),
  );
}

({int parameterCategory, int parameterNumber, int forecastTimeUnit, int forecastTime})
    _parseSection4(ByteData bd, int s) {
  final templateNumber = bd.getUint16(s + 7, Endian.big);
  if (templateNumber != 0) {
    throw GribParseException(
        'Unsupported product definition template 4.$templateNumber — only '
        '4.0 (analysis/forecast at a point in time) is supported');
  }
  return (
    parameterCategory: bd.getUint8(s + 9),
    parameterNumber: bd.getUint8(s + 10),
    forecastTimeUnit: bd.getUint8(s + 17),
    forecastTime: bd.getUint32(s + 18, Endian.big),
  );
}

({double refValue, int binaryScale, int decimalScale, int bitCount})
    _parseSection5(ByteData bd, int s) {
  final templateNumber = bd.getUint16(s + 9, Endian.big);
  if (templateNumber != 0) {
    throw GribParseException(
        'Unsupported data representation template 5.$templateNumber — only '
        '5.0 (simple packing) is supported');
  }
  return (
    refValue: bd.getFloat32(s + 11, Endian.big),
    binaryScale: _readSignedInt(bd, s + 15, 2),
    decimalScale: _readSignedInt(bd, s + 17, 2),
    bitCount: bd.getUint8(s + 19),
  );
}

List<double> _unpackValues(
  Uint8List data, {
  required int count,
  required int bitCount,
  required double refValue,
  required int binaryScale,
  required int decimalScale,
}) {
  final decScale = math.pow(10, decimalScale).toDouble();
  if (bitCount == 0) {
    // Per WMO: 0 bits per value means every point equals the reference
    // value (a constant field) — no packed data follows in Section 7.
    return List<double>.filled(count, refValue / decScale);
  }
  final binScale = math.pow(2, binaryScale).toDouble();
  final reader = _BitReader(data);
  return List<double>.generate(count, (_) {
    final x = reader.readBits(bitCount);
    return (refValue + x * binScale) / decScale;
  });
}

/// Parses the first GRIB2 message in [bytes]. Throws [GribParseException]
/// for anything malformed, truncated, or outside this parser's supported
/// template set — never a silent wrong value or a crash reading past the
/// buffer.
GribGrid parseGrib2(Uint8List bytes) {
  if (bytes.length < 16) {
    throw const GribParseException('Too short to be a GRIB2 message');
  }
  if (bytes[0] != 0x47 ||
      bytes[1] != 0x52 ||
      bytes[2] != 0x49 ||
      bytes[3] != 0x42) {
    throw const GribParseException(
        'Missing "GRIB" magic bytes at the start of the file');
  }
  final edition = bytes[7];
  if (edition != 2) {
    throw GribParseException(
        'Unsupported GRIB edition $edition — only GRIB2 is supported');
  }

  final bd = ByteData.sublistView(bytes);
  final totalLength = bd.getUint64(8, Endian.big);
  if (totalLength < 16 || totalLength > bytes.length) {
    throw GribParseException(
        'Declared message length ($totalLength) is invalid or exceeds '
        'available data (${bytes.length} bytes)');
  }

  int? ni, nj;
  double? la1, lo1, la2, lo2;
  int? parameterCategory, parameterNumber, forecastTimeUnit, forecastTime;
  double? refValue;
  int? binaryScale, decimalScale, bitCount;
  List<double>? values;

  var pos = 16;
  final sectionsEnd = totalLength - 4; // last 4 octets = "7777" end marker
  while (pos < sectionsEnd) {
    if (pos + 5 > bytes.length) {
      throw const GribParseException(
          'Truncated — not enough bytes for a section header');
    }
    final sectionLength = bd.getUint32(pos, Endian.big);
    if (sectionLength < 5 || pos + sectionLength > bytes.length) {
      throw GribParseException(
          'Invalid section length $sectionLength at offset $pos');
    }
    final sectionNumber = bytes[pos + 4];
    switch (sectionNumber) {
      case 3:
        final r = _parseSection3(bd, pos);
        ni = r.ni;
        nj = r.nj;
        la1 = r.la1;
        lo1 = r.lo1;
        la2 = r.la2;
        lo2 = r.lo2;
      case 4:
        final r = _parseSection4(bd, pos);
        parameterCategory = r.parameterCategory;
        parameterNumber = r.parameterNumber;
        forecastTimeUnit = r.forecastTimeUnit;
        forecastTime = r.forecastTime;
      case 5:
        final r = _parseSection5(bd, pos);
        refValue = r.refValue;
        binaryScale = r.binaryScale;
        decimalScale = r.decimalScale;
        bitCount = r.bitCount;
      case 6:
        final indicator = bytes[pos + 5];
        if (indicator != 255) {
          throw GribParseException(
              'Bit-map section present (indicator $indicator) — not '
              'supported in v1');
        }
      case 7:
        if (ni == null ||
            nj == null ||
            refValue == null ||
            binaryScale == null ||
            decimalScale == null ||
            bitCount == null) {
          throw const GribParseException(
              'Data section (7) encountered before the grid/data-'
              'representation sections it depends on');
        }
        final dataStart = pos + 5;
        final dataEnd = pos + sectionLength;
        values = _unpackValues(
          Uint8List.sublistView(bytes, dataStart, dataEnd),
          count: ni * nj,
          bitCount: bitCount,
          refValue: refValue,
          binaryScale: binaryScale,
          decimalScale: decimalScale,
        );
      default:
        // Sections 1 (Identification) and 2 (Local Use, optional) carry
        // nothing this parser needs — skip via the section's own length.
        break;
    }
    pos += sectionLength;
  }

  if (pos != sectionsEnd) {
    throw const GribParseException(
        'Section boundaries did not align with the declared message '
        'length — the file may be corrupt');
  }
  if (bytes[pos] != 0x37 ||
      bytes[pos + 1] != 0x37 ||
      bytes[pos + 2] != 0x37 ||
      bytes[pos + 3] != 0x37) {
    throw const GribParseException(
        'Missing "7777" end marker — the file may be corrupt or truncated');
  }

  if (ni == null || nj == null || la1 == null || lo1 == null || la2 == null || lo2 == null) {
    throw const GribParseException(
        'Message had no grid definition section (3)');
  }
  if (values == null) {
    throw const GribParseException('Message had no data section (7)');
  }
  if (values.length != ni * nj) {
    throw GribParseException(
        'Unpacked ${values.length} values, expected ${ni * nj}');
  }

  return GribGrid(
    ni: ni,
    nj: nj,
    la1: la1,
    lo1: lo1,
    la2: la2,
    lo2: lo2,
    values: values,
    parameterCategory: parameterCategory ?? -1,
    parameterNumber: parameterNumber ?? -1,
    forecastTimeUnit: forecastTimeUnit ?? -1,
    forecastTime: forecastTime ?? -1,
  );
}
