import 'dart:typed_data';

/// #243/#244: builds a well-formed single-message GRIB2 byte stream for
/// tests — Grid Definition Template 3.0, Product Definition Template 4.0,
/// Data Representation Template 5.0 (simple packing), no bit-map. Every
/// byte offset matches `grib_parser_service.dart`'s own offset map, which
/// was independently verified against NOAA/ECMWF/WMO documentation before
/// any parsing code was written — see that file's doc comment.
List<int> _u16(int v) => [(v >> 8) & 0xFF, v & 0xFF];
List<int> _u32(int v) => [
      (v >> 24) & 0xFF,
      (v >> 16) & 0xFF,
      (v >> 8) & 0xFF,
      v & 0xFF,
    ];
List<int> _signMag16(int v) => _u16(v < 0 ? (v.abs() | 0x8000) : v.abs());
List<int> _signMag32(int v) => _u32(v < 0 ? (v.abs() | 0x80000000) : v.abs());
List<int> _float32Bytes(double v) {
  final bd = ByteData(4);
  bd.setFloat32(0, v, Endian.big);
  return bd.buffer.asUint8List();
}

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
    ..._u32(21), 1,
    ..._u16(0), ..._u16(0),
    2, 0, 0,
    ..._u16(2026), 8, 4, 0, 0, 0,
    0, 1,
  ];

  final s3Body = <int>[
    3,
    0,
    ..._u32(ni * nj),
    0, 0,
    ..._u16(0),
    6,
    0, ..._u32(0),
    0, ..._u32(0),
    0, ..._u32(0),
    ..._u32(ni),
    ..._u32(nj),
    ..._u32(0),
    ..._u32(0),
    ..._signMag32((la1 * 1e6).round()),
    ..._u32((lo1 * 1e6).round()),
    0,
    ..._signMag32((la2 * 1e6).round()),
    ..._u32((lo2 * 1e6).round()),
    ..._u32(0),
    ..._u32(0),
    0x00,
  ];
  final s3 = <int>[..._u32(s3Body.length + 4), ...s3Body];

  final s4Body = <int>[
    4,
    ..._u16(0),
    ..._u16(0),
    parameterCategory,
    parameterNumber,
    0,
    0,
    0,
    ..._u16(0), 0,
    0,
    ..._u32(0),
    1, 0, ..._u32(10),
    255, 0, ..._u32(0),
  ];
  final s4 = <int>[..._u32(s4Body.length + 4), ...s4Body];

  final s5Body = <int>[
    5,
    ..._u32(ni * nj),
    ..._u16(0),
    ..._float32Bytes(refValue),
    ..._signMag16(binaryScale),
    ..._signMag16(decimalScale),
    bitCount,
    0,
  ];
  final s5 = <int>[..._u32(s5Body.length + 4), ...s5Body];

  final s6 = <int>[..._u32(6), 6, 255];

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
  final s7 = <int>[..._u32(s7Body.length + 4), ...s7Body];

  final sections = [...s1, ...s3, ...s4, ...s5, ...s6, ...s7];
  final totalLength = 16 + sections.length + 4;

  final message = <int>[
    0x47, 0x52, 0x49, 0x42,
    0, 0,
    0,
    2,
    ...List.filled(4, 0), ..._u32(totalLength),
    ...sections,
    0x37, 0x37, 0x37, 0x37,
  ];
  return Uint8List.fromList(message);
}
