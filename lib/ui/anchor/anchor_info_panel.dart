import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/anchor_alarm_service.dart';
import '../../services/predictwind_datahub_service.dart';

/// #266 — read-only instrument snapshot for the Anchor Alarm "Info" tab.
///
/// Order is safety-first: remaining geofence margin and bearing to anchor
/// before raw coordinates. Each row has a clear unavailable state when the
/// Hub has no fix (or no active watch).
class AnchorInfoPanel extends StatelessWidget {
  final AnchorWatch? activeWatch;
  final PredictWindBoatData? boatData;

  static const _alarm = AnchorAlarmService();

  const AnchorInfoPanel({
    super.key,
    required this.activeWatch,
    required this.boatData,
  });

  @override
  Widget build(BuildContext context) {
    final watch = activeWatch;
    final data = boatData;
    final hasFix = data?.hasFix ?? false;
    final boatLat = hasFix ? data!.latitude : null;
    final boatLon = hasFix ? data!.longitude : null;

    double? distFromAnchor;
    double? marginToPerimeter;
    double? bearingToAnchor;
    if (watch != null && boatLat != null && boatLon != null) {
      distFromAnchor = _alarm.distanceMeters(
        lat1: watch.anchorLat,
        lon1: watch.anchorLon,
        lat2: boatLat,
        lon2: boatLon,
      );
      marginToPerimeter = _alarm.distanceFromPerimeterMeters(
        distanceFromAnchorMeters: distFromAnchor,
        radiusMeters: watch.radiusMeters,
      );
      bearingToAnchor = _alarm.bearingToAnchorDeg(
        boatLat: boatLat,
        boatLon: boatLon,
        anchorLat: watch.anchorLat,
        anchorLon: watch.anchorLon,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (watch == null)
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('No anchor set'),
              subtitle: Text(
                'Drop an anchor on the Watch tab to see distances and '
                'bearing here.',
              ),
            ),
          )
        else ...[
          _metricCard(
            context,
            icon: Icons.radar,
            title: 'Margin to perimeter',
            value: marginToPerimeter == null
                ? 'Unavailable'
                : marginToPerimeter >= 0
                    ? '${marginToPerimeter.toStringAsFixed(0)} m remaining'
                    : '${(-marginToPerimeter).toStringAsFixed(0)} m past circle',
            subtitle: marginToPerimeter == null
                ? 'Needs a live boat position from the Hub.'
                : marginToPerimeter >= 0
                    ? 'Still inside the ${watch.radiusMeters.toStringAsFixed(0)} m alarm circle.'
                    : 'Outside the safe swinging circle.',
            emphasis: marginToPerimeter != null && marginToPerimeter < 0,
          ),
          _metricCard(
            context,
            icon: Icons.navigation,
            title: 'Bearing to anchor',
            value: bearingToAnchor == null
                ? 'Unavailable'
                : '${bearingToAnchor.toStringAsFixed(0)}°T',
            subtitle: 'Direction from the boat back to the anchor.',
          ),
          _metricCard(
            context,
            icon: Icons.straighten,
            title: 'Distance from anchor',
            value: distFromAnchor == null
                ? 'Unavailable'
                : '${distFromAnchor.toStringAsFixed(0)} m',
          ),
        ],
        // #305 — depth is independent of GPS fix (sounder can stream without a fix).
        _metricCard(
          context,
          icon: Icons.waves,
          title: 'Depth',
          value: data?.depthMeters == null
              ? 'Unavailable'
              : '${data!.depthMeters!.toStringAsFixed(1)} m',
          subtitle: data?.depthMeters == null
              ? 'Needs a depth reading from boat instruments.'
              : 'Water depth below transducer (instruments)',
        ),
        _metricCard(
          context,
          icon: Icons.speed,
          title: 'SOG',
          value: data?.sogKt == null
              ? 'Unavailable'
              : '${data!.sogKt!.toStringAsFixed(1)} kn',
          subtitle: 'Speed over ground',
        ),
        _metricCard(
          context,
          icon: Icons.explore,
          title: 'COG',
          value: data?.cogDeg == null
              ? 'Unavailable'
              : '${data!.cogDeg!.toStringAsFixed(0)}°T',
          subtitle: 'Course over ground',
        ),
        _metricCard(
          context,
          icon: Icons.air,
          title: 'Apparent wind',
          value: data?.apparentWindSpeedKt == null
              ? 'Unavailable'
              : data!.apparentWindDirectionDeg != null
                  ? '${data.apparentWindSpeedKt!.toStringAsFixed(1)} kn @ '
                      '${data.apparentWindDirectionDeg!.toStringAsFixed(0)}°'
                  : '${data.apparentWindSpeedKt!.toStringAsFixed(1)} kn',
          subtitle: 'AWS / AWA from the Hub',
        ),
        _metricCard(
          context,
          icon: Icons.gps_fixed,
          title: 'Boat GPS',
          value: hasFix
              ? '${boatLat!.toStringAsFixed(5)}, ${boatLon!.toStringAsFixed(5)}'
              : 'Unavailable',
          subtitle: hasFix
              ? (data!.viaLocalNetwork
                  ? 'Source: PredictWind Hub (local WiFi)'
                  : 'Source: PredictWind Hub (internet)')
              : 'Waiting for a Hub fix.',
        ),
        if (watch != null)
          _metricCard(
            context,
            icon: Icons.anchor,
            title: 'Anchor GPS',
            value:
                '${watch.anchorLat.toStringAsFixed(5)}, ${watch.anchorLon.toStringAsFixed(5)}',
            subtitle:
                'Alarm radius ${watch.radiusMeters.toStringAsFixed(0)} m',
          ),
      ],
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    bool emphasis = false,
  }) {
    final theme = Theme.of(context);
    final unavailable = value == 'Unavailable';
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: emphasis
              ? theme.colorScheme.error
              : unavailable
                  ? theme.colorScheme.outline
                  : null,
        ),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: emphasis
                  ? theme.colorScheme.error
                  : unavailable
                      ? theme.colorScheme.outline
                      : null,
            ),
          ),
        ),
      ),
    );
  }
}
