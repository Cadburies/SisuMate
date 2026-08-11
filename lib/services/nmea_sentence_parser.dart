/// #263 — pure NMEA 0183 sentence parser for YDWG-style gateways.
///
/// Parses common boat-instrument sentences into numeric fields used by
/// [PredictWindBoatData]. Invalid checksums / malformed lines are skipped
/// (never throw). Talker prefix is ignored (`$GPGGA` / `$IIGGA` / …).
class NmeaFix {
  double? latitude;
  double? longitude;
  double? sogKt;
  /// Speed through water (kn) from VHW / VBW.
  double? stwKt;
  double? cogDeg;
  double? windSpeedKt;
  double? windDirectionDeg;
  bool windIsTrue = true;
  double? depthMeters;
  /// Engine shaft RPM by engine instance (1 → port, 2 → stbd) when RPM/ERRPM seen.
  double? enginePortRpm;
  double? engineStbdRpm;
  /// Air temperature (°C) from MTA.
  double? airTempC;
  /// Water/sea temperature (°C) from MTW.
  double? waterTempC;
  DateTime? observedAt;

  bool get hasPosition => latitude != null && longitude != null;
}

class NmeaSentenceParser {
  final NmeaFix fix = NmeaFix();

  /// Feed one full sentence including `$` and `*CS` (or without checksum).
  void feed(String line) {
    final t = line.trim();
    if (t.isEmpty) return;
    if (!t.startsWith(r'$') && !t.startsWith(r'!')) return;
    final body = t.startsWith(r'$') || t.startsWith(r'!') ? t.substring(1) : t;
    final star = body.indexOf('*');
    final payload = star >= 0 ? body.substring(0, star) : body;
    if (star >= 0 && !_checksumOk(payload, body.substring(star + 1))) {
      return;
    }
    final parts = payload.split(',');
    if (parts.isEmpty || parts[0].length < 3) return;
    final type = parts[0].substring(parts[0].length - 3).toUpperCase();
    switch (type) {
      case 'GGA':
        _parseGga(parts);
      case 'RMC':
        _parseRmc(parts);
      case 'VTG':
        _parseVtg(parts);
      case 'MWV':
        _parseMwv(parts);
      case 'MWD':
        _parseMwd(parts);
      case 'DBT':
        _parseDbt(parts);
      case 'DPT':
        _parseDpt(parts);
      case 'RPM':
        _parseRpm(parts);
      case 'VHW':
        _parseVhw(parts);
      case 'VBW':
        _parseVbw(parts);
      case 'MTA':
        _parseMta(parts);
      case 'MTW':
        _parseMtw(parts);
    }
  }

  void feedLines(String chunk) {
    for (final line in chunk.split(RegExp(r'[\r\n]+'))) {
      feed(line);
    }
  }

  static bool _checksumOk(String payload, String csHex) {
    var xor = 0;
    for (final cu in payload.codeUnits) {
      xor ^= cu;
    }
    final expected = xor.toRadixString(16).padLeft(2, '0').toUpperCase();
    return csHex.trim().toUpperCase().startsWith(expected);
  }

  void _parseGga(List<String> p) {
    // GGA,time,lat,N/S,lon,E/W,quality,...
    if (p.length < 7) return;
    final lat = _latLon(p[2], p[3]);
    final lon = _latLon(p[4], p[5]);
    final quality = int.tryParse(p[6]) ?? 0;
    if (quality > 0 && lat != null && lon != null) {
      fix.latitude = lat;
      fix.longitude = lon;
      fix.observedAt = DateTime.now().toUtc();
    }
  }

  void _parseRmc(List<String> p) {
    // RMC,time,status,lat,N/S,lon,E/W,sog,cog,...
    if (p.length < 9) return;
    if (p[2].toUpperCase() != 'A') return; // void
    final lat = _latLon(p[3], p[4]);
    final lon = _latLon(p[5], p[6]);
    if (lat != null && lon != null) {
      fix.latitude = lat;
      fix.longitude = lon;
      fix.observedAt = DateTime.now().toUtc();
    }
    final sog = double.tryParse(p[7]);
    if (sog != null) fix.sogKt = sog;
    final cog = double.tryParse(p[8]);
    if (cog != null) fix.cogDeg = cog;
  }

  void _parseVtg(List<String> p) {
    // VTG,cogT,T,cogM,M,sogKn,N,sogKmh,K
    if (p.length < 6) return;
    final cog = double.tryParse(p[1]);
    if (cog != null) fix.cogDeg = cog;
    final sog = double.tryParse(p[5]);
    if (sog != null) fix.sogKt = sog;
  }

  void _parseMwv(List<String> p) {
    // MWV,angle,R/T,speed,unit,A
    if (p.length < 5) return;
    final angle = double.tryParse(p[1]);
    final ref = p[2].toUpperCase();
    final speed = double.tryParse(p[3]);
    final unit = p[4].toUpperCase();
    if (angle != null) fix.windDirectionDeg = angle;
    if (speed != null) {
      fix.windSpeedKt = switch (unit) {
        'M' => speed * 1.943844, // m/s → kn
        'K' => speed * 0.539957, // km/h → kn
        _ => speed, // N = knots
      };
    }
    fix.windIsTrue = ref == 'T';
  }

  void _parseMwd(List<String> p) {
    // MWD,dirT,T,dirM,M,speedKn,N,speedMs,M
    if (p.length < 6) return;
    final dir = double.tryParse(p[1]);
    if (dir != null) {
      fix.windDirectionDeg = dir;
      fix.windIsTrue = true;
    }
    final kn = double.tryParse(p[5]);
    if (kn != null) fix.windSpeedKt = kn;
  }

  void _parseDbt(List<String> p) {
    // DBT,feet,f,meters,M,fathoms,F
    if (p.length < 4) return;
    final m = double.tryParse(p[3]);
    if (m != null) {
      fix.depthMeters = m;
      return;
    }
    final ft = double.tryParse(p[1]);
    if (ft != null) fix.depthMeters = ft * 0.3048;
  }

  void _parseDpt(List<String> p) {
    // DPT,depth,offset
    if (p.length < 2) return;
    final d = double.tryParse(p[1]);
    final offset = p.length > 2 ? double.tryParse(p[2]) ?? 0 : 0;
    if (d != null) fix.depthMeters = d + offset;
  }

  void _parseRpm(List<String> p) {
    // RPM,source,engine#,speed,pitch,status — NMEA 0183
    // e.g. $IIRPM,E,1,0.0,100.0,A
    if (p.length < 4) return;
    final eng = int.tryParse(p[2]);
    final rpm = double.tryParse(p[3]);
    if (rpm == null) return;
    if (eng == 1 || eng == null) {
      fix.enginePortRpm = rpm;
    } else if (eng == 2) {
      fix.engineStbdRpm = rpm;
    }
  }

  void _parseVhw(List<String> p) {
    // VHW,headingT,T,headingM,M,speedKn,N,speedKmh,K
    if (p.length < 6) return;
    final kn = double.tryParse(p[5]);
    if (kn != null) fix.stwKt = kn;
  }

  void _parseVbw(List<String> p) {
    // VBW,waterLong,waterTrans,statusWater,groundLong,...
    // Prefer longitudinal water speed when status is A.
    if (p.length < 3) return;
    final status = p.length > 3 ? p[3].toUpperCase() : 'A';
    if (status == 'V') return;
    final kn = double.tryParse(p[1]);
    if (kn != null) fix.stwKt = kn.abs();
  }

  void _parseMta(List<String> p) {
    // MTA,temp,C — air temperature. Unit field is always 'C' per spec, but
    // parse the value regardless of what's actually there rather than
    // gating on it (a sender that omits/misformats the unit still gives a
    // usable number).
    if (p.length < 2) return;
    final c = double.tryParse(p[1]);
    if (c != null) fix.airTempC = c;
  }

  void _parseMtw(List<String> p) {
    // MTW,temp,C — water temperature.
    if (p.length < 2) return;
    final c = double.tryParse(p[1]);
    if (c != null) fix.waterTempC = c;
  }

  /// NMEA lat/lon: `ddmm.mmm` + hemisphere.
  static double? _latLon(String raw, String hemi) {
    if (raw.isEmpty || hemi.isEmpty) return null;
    final v = double.tryParse(raw);
    if (v == null) return null;
    final hemiU = hemi.toUpperCase();
    final isLat = hemiU == 'N' || hemiU == 'S';
    final degDigits = isLat ? 2 : 3;
    if (raw.length < degDigits + 1) return null;
    final deg = double.tryParse(raw.substring(0, degDigits)) ??
        (v / 100).floorToDouble();
    final min = v - deg * 100;
    var dec = deg + min / 60.0;
    if (hemiU == 'S' || hemiU == 'W') dec = -dec;
    return dec;
  }
}
