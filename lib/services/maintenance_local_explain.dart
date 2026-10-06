/// #402 / #286 — offline maintenance explanations and part-spec hints.
///
/// Bundled notes keyed to the seeded Yanmar 4JH45 schedule, plus a few
/// common boat systems. Cloud LLM enrichment stays in the dialogs.
class MaintenanceLocalExplain {
  MaintenanceLocalExplain._();

  /// Why the task matters, with no network and no API key.
  static String explain({required String title, String? description}) {
    final raw = _raw(title, description);
    final guide = _match(raw);
    final scraped = _scraped(raw);
    final buf = StringBuffer()
      ..writeln(
        'Offline maintenance note (bundled guide — confirm in your engine manual):',
      )
      ..writeln();
    if (guide == null) {
      buf
        ..writeln(
          '“$title” is not in the bundled Yanmar 4JH45 table, so this is a general reading of the wording.',
        )
        ..writeln()
        ..writeln(
          'A skipped check is how small wear becomes a failure away from help. Do it while you can still get parts.',
        )
        ..writeln()
        ..writeln('Before you start, confirm:')
        ..writeln('• What “done” looks like on this exact item')
        ..writeln('• Whether the engine must be stopped and cold')
        ..writeln(
          '• The interval in your own manual, in hours and on the calendar',
        );
    } else {
      buf
        ..writeln('Why it matters')
        ..writeln(guide.why)
        ..writeln()
        ..writeln('If you skip it')
        ..writeln(guide.ifSkipped)
        ..writeln()
        ..writeln('What to have on hand')
        ..writeln(guide.spec);
    }
    if (scraped.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('Numbers copied from the task text: $scraped');
    }
    return buf.toString().trimRight();
  }

  /// Part-spec and supplier-type summary. Not a live catalog.
  static String partSpec({
    required String title,
    String? description,
    String? coarseLocation,
  }) {
    final raw = _raw(title, description);
    final guide = _match(raw);
    final scraped = _scraped(raw);
    final buf = StringBuffer()
      ..writeln('Offline part guide (not a live catalog or a stock check):')
      ..writeln()
      ..writeln('• Task: $title');
    final detail = description?.trim();
    if (detail != null && detail.isNotEmpty) {
      buf.writeln('• From the task: $detail');
    }
    if (scraped.isNotEmpty) {
      buf.writeln('• Numbers copied from the text: $scraped');
    }
    if (guide != null) {
      buf
        ..writeln('• Match this: ${guide.spec}')
        ..writeln('• Likely suppliers: ${guide.suppliers}');
    } else {
      buf
        ..writeln(
          '• No bundled spec for this wording. Take the old part and match thread, seal, and size on the part itself.',
        )
        ..writeln(
          '• Likely suppliers: chandlery, diesel mechanic, or a hardware store.',
        );
    }
    buf.writeln(
      '• Take the removed part with you. Confirm thread, o-ring, and gasket before you install anything.',
    );
    final place = coarseLocation?.trim();
    if (place != null && place.isNotEmpty) {
      buf.writeln(
        '• Area: $place. Ask those suppliers there. This does not check who is open or what is on the shelf.',
      );
    } else {
      buf.writeln('• Area: not set. The spec above does not need a city.');
    }
    return buf.toString().trimRight();
  }

  static String _raw(String title, String? description) => [
    title,
    description,
  ].where((s) => s != null && s.trim().isNotEmpty).join('. ');

  static _Guide? _match(String raw) {
    final haystack = raw.toLowerCase();
    for (final guide in _guides) {
      for (final needle in guide.needles) {
        if (haystack.contains(needle)) return guide;
      }
    }
    return null;
  }

  static String _scraped(String raw) {
    final found = <String>[];
    void addAll(RegExp re) {
      for (final match in re.allMatches(raw)) {
        final text = match.group(0)!.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (text.isNotEmpty && !found.contains(text)) found.add(text);
      }
    }

    addAll(
      RegExp(
        r'(?:yanmar\s*)?#\s*\d{4,}(?:-\d+)*|\b\d{6,}(?:-\d+)+\b',
        caseSensitive: false,
      ),
    );
    addAll(RegExp(r'SAE(?:\s+viscosity)?\s*#?\s*\d+', caseSensitive: false));
    addAll(RegExp(r'\d+(?:\.\d+)?\s*lit(?:er|re)s?', caseSensitive: false));
    return found.join(', ');
  }
}

class _Guide {
  const _Guide({
    required this.needles,
    required this.why,
    required this.ifSkipped,
    required this.spec,
    required this.suppliers,
  });

  final List<String> needles;
  final String why;
  final String ifSkipped;
  final String spec;
  final String suppliers;
}

// First match wins, so more specific phrases come before broader ones.
const List<_Guide> _guides = [
  _Guide(
    needles: ['gear oil filter'],
    why:
        'The marine gear has its own oil filter. Metal in that filter is an early sign the gearbox is wearing.',
    ifSkipped:
        'Dirty gear oil keeps circulating. Bearings and clutches wear, and the failure shows up as slip or noise, not a dashboard warning.',
    spec:
        'The seeded item leaves the element number blank. Match the old element; do not guess from the engine oil filter.',
    suppliers: 'diesel shop or a Yanmar dealer',
  ),
  _Guide(
    needles: ['oil filter'],
    why:
        'The filter is what actually catches the grit the oil change is for. A fresh sump of oil through a clogged filter does not protect the bearings.',
    ifSkipped:
        'Oil pressure can drop once the bypass opens, and bearing wear shows up later as low pressure or a knock.',
    spec:
        'Seeded Yanmar 4JH45 50-hour and 250-hour lists use filter 129150-35170. A 3YM or any other engine may differ — match the old filter’s gasket and thread.',
    suppliers:
        'chandlery, diesel shop, or an auto-parts counter that will cross-check the old filter',
  ),
  _Guide(
    needles: ['engine oil'],
    why:
        'The oil film is what the bearings and the turbo ride on. The 50-hour seed is the break-in change; later changes are on hours and on the calendar, whichever comes first.',
    ifSkipped:
        'Dirty oil carries metal and fuel dilution. Pressure drops when the oil is hot, and the turbo bearing is usually the first to suffer.',
    spec:
        'Use the oil grade the manual names. The seeded 4JH45 first 50-hour item says about 7.5 liters. Check the dipstick after the filter is full, and do not copy that volume onto a different engine.',
    suppliers:
        'chandlery or an auto-parts store that carries the grade your manual names',
  ),
  _Guide(
    needles: ['fuel/water', 'fuel water separator', 'water separator'],
    why:
        'Diesel bugs and water collect in the separator before they reach the injection pump. The bowl is the early warning.',
    ifSkipped:
        'Water in the pump scores the plungers. The engine stumbles or stops, often in a seaway when the tank is stirred up.',
    spec:
        'The seeded item says a Racor or equivalent element. Match the bowl model and micron rating on the unit you already have.',
    suppliers: 'chandlery or a diesel shop',
  ),
  _Guide(
    needles: ['fuel filter'],
    why:
        'The primary fuel filter stops rust and dirt before the lift pump and injectors. Marine tanks shed both.',
    ifSkipped:
        'A clogged element starves the engine under load. You lose rpm when you need it, and a badly blocked filter can pull air.',
    spec:
        'Match the old element and note whether this is the primary (hull) filter or the engine secondary. They are not interchangeable.',
    suppliers: 'chandlery or a diesel shop',
  ),
  _Guide(
    needles: ['injector'],
    why:
        'Injectors meter and atomise the fuel. A poor spray burns dirty, washes the bores, and wastes fuel.',
    ifSkipped:
        'One lazy injector shows up as smoke, a knock, or a cylinder that never pulls its weight. Carbon then loads the turbo and exhaust.',
    spec:
        'Testing needs a diesel shop. Do not swap injector lines without marking them, and do not invent a nozzle number from the engine family.',
    suppliers: 'diesel injection shop',
  ),
  _Guide(
    needles: ['injection timing'],
    why:
        'Timing sets when the fuel burns relative to the piston. It is a check, not a routine parts swap.',
    ifSkipped:
        'Retarded timing smokes and runs hot. Advanced timing knocks and loads the bearings.',
    spec:
        'This needs the manual’s timing procedure and, usually, a dial gauge. There is no shelf part for “timing”.',
    suppliers: 'diesel shop if you are not set up to check it aboard',
  ),
  _Guide(
    needles: ['air filter'],
    why:
        'The engine breathes whatever is in the compartment. A choked filter richens the mixture and raises exhaust temperature.',
    ifSkipped:
        'Power falls off and the engine runs sooty. In a bad case it pulls crankcase fumes or dust past a damaged seal.',
    spec:
        'Match the old element’s shape. The seeded schedule says replace it; clean-and-reuse only if the manual allows that element.',
    suppliers: 'chandlery or a diesel shop',
  ),
  _Guide(
    needles: ['impeller', 'raw water'],
    why:
        'The raw-water impeller is the seawater side of the cooling circuit. It is a wear item: neoprene hardens, loses a vane, and then the engine overheats.',
    ifSkipped:
        'One missing vane, or a cover left weeping, cooks the exhaust elbow and can warp the head. The broken vane also travels downstream and blocks a passage.',
    spec:
        'Count the vanes and measure outside diameter, width, and shaft. The pump brand is on the cover. The seeded schedule says replace the seawater impeller; it does not print a part number.',
    suppliers: 'chandlery — take the old impeller and the cover gasket',
  ),
  _Guide(
    needles: ['timing belt'],
    why:
        'On engines that drive the cam with a belt, a snapped belt is a mechanical failure, not a roadside stall.',
    ifSkipped:
        'Valves and pistons can meet. That is a top-end rebuild, not a belt swap in the anchorage.',
    spec:
        'Replace the belt and check the tensioner together. Count teeth against the old belt and do not reuse a belt that has been rolled or contaminated.',
    suppliers: 'diesel shop or a dealer that can supply the timed kit',
  ),
  _Guide(
    needles: ['drive belt', 'v-belt', 'belts'],
    why:
        'The belt drives the alternator and, on many installs, the raw-water pump. Glazing or a cracked rib is the warning before it sheds.',
    ifSkipped:
        'You lose charging, and if the pump is belt-driven you lose cooling at the same time.',
    spec:
        'Read the number printed on the old belt, or match width and length. The seeded 4JH45 items cover the alternator and water-pump belts; tension is in the manual, not a stock lookup.',
    suppliers: 'chandlery, auto-parts counter, or a diesel shop',
  ),
  _Guide(
    needles: ['valve clearance', 'valve seat'],
    why:
        'Clearance lets the valve close fully as the engine heats. Too tight and it burns a seat; too loose and it ticks and loses compression.',
    ifSkipped:
        'A burnt valve shows up as a dead cylinder and a lot of heat in the exhaust. Seat wear is the expensive version of a skipped feeler-gauge check.',
    spec:
        'Use the manual’s cold clearance. This note does not include the thousandths — they differ by engine.',
    suppliers:
        'feeler gauges from a tool shop; a diesel mechanic if the head has to come off',
  ),
  _Guide(
    needles: ['heat exchanger'],
    why:
        'The heat exchanger is where coolant gives its heat to seawater. Scale and impeller crumbs block the tubes.',
    ifSkipped:
        'The engine runs hotter each season until it overheats under load, even with a new impeller.',
    spec:
        'Have a new end-cap gasket and o-rings before you split it. Tube count and stack length are on the old unit.',
    suppliers: 'chandlery or a diesel shop for the gasket set',
  ),
  _Guide(
    needles: ['coolant', 'cooling system', 'thermostat'],
    why:
        'The closed side of the cooling system needs the right coolant and a thermostat that actually opens. Mixed coolants gel.',
    ifSkipped:
        'Corrosion eats the heat exchanger and the exhaust elbow from the inside. A stuck thermostat overheats the engine while the raw-water side looks fine.',
    spec:
        'Match the manual’s coolant type and do not mix colours on a guess. The thermostat temperature is stamped on the old one. The 50-hour seed also says to check the hoses.',
    suppliers:
        'chandlery or an auto-parts store for coolant; take the old thermostat',
  ),
  _Guide(
    needles: ['turbo'],
    why:
        'The turbo oil feed is small and the compressor collects carbon. A dirty blower wheel is unbalanced.',
    ifSkipped:
        'Oil coke in the bearing, or a rubbing wheel, destroys the cartridge. Boost drops and exhaust temperature climbs.',
    spec:
        'The seeded task is to wash the blower, not to buy a cartridge. If the shaft has play, that is a shop job — do not order a turbo from the engine name alone.',
    suppliers: 'diesel shop if the inspection shows play or oil in the intake',
  ),
  _Guide(
    needles: ['gear oil'],
    why:
        'The marine gear is a separate sump from the engine. Its oil shears and collects clutch material.',
    ifSkipped:
        'The gearbox overheats, slips, or loses drive. Water in the oil (milky) means a seal is already leaking.',
    spec:
        'The seeded item specifies SAE viscosity #20 or #30 marine gear oil. Capacity is on the gear, not in this note.',
    suppliers: 'chandlery or a diesel shop',
  ),
  _Guide(
    needles: ['cylinder head'],
    why:
        'The 1000-hour seed calls for the head to come off so you can see the fire deck, valves, and gasket.',
    ifSkipped:
        'A weeping gasket or a cracked seat stays hidden until it passes coolant into a cylinder.',
    spec:
        'This is a workshop inspection. Have the manual’s torque sequence and a new head gasket before it goes back. There is no single “head part” to buy from the title.',
    suppliers: 'diesel shop',
  ),
  _Guide(
    needles: ['piston'],
    why:
        'Rings seal compression and scrape oil. The 1000-hour seed says inspect them and replace only if they are worn.',
    ifSkipped:
        'Blow-by fills the crankcase, oil consumption climbs, and the engine loses compression on one cylinder.',
    spec:
        'Ring size is a measurement of the bore, not a guess from “4JH45”. Leave the set to the shop that measures it.',
    suppliers: 'diesel machine shop',
  ),
  _Guide(
    needles: ['main bearing'],
    why:
        'Main bearings carry the crank. Clearance is a measurement with plastigage or a micrometer, not a visual “looks fine”.',
    ifSkipped:
        'Extra clearance knocks and drops oil pressure once the oil is hot.',
    spec:
        'Bearings are sized to the crank journals. Do not order a set from the marketing name of the engine.',
    suppliers: 'diesel machine shop',
  ),
  _Guide(
    needles: ['mixing elbow', 'exhaust elbow'],
    why:
        'The elbow is where cooling water joins the exhaust. It corrodes from the inside and can close the water path or leak exhaust into the boat.',
    ifSkipped:
        'A blocked elbow overheats the engine. A holed elbow puts carbon monoxide and seawater where they do not belong.',
    spec:
        'Match hose diameters and the flange on the old elbow. The seeded 500-hour item says replace it, not patch it.',
    suppliers: 'chandlery or a diesel shop — take the old elbow',
  ),
  _Guide(
    needles: ['exhaust'],
    why:
        'Exhaust leaks at the manifold gasket or the hose dump soot and gas into the compartment.',
    ifSkipped:
        'You breathe the leak, and a leaking raw-water joint fills the boat slowly.',
    spec:
        'Match hose inside diameter and the gasket. Check the clamps and the waterlock, not only the manifold.',
    suppliers:
        'chandlery for hose and clamps; a diesel shop for a cracked manifold',
  ),
  _Guide(
    needles: ['engine mount'],
    why:
        'Mounts hold the alignment of the shaft. Soft or separated rubber lets the engine walk under load.',
    ifSkipped:
        'The shaft coupling frets, the cutless wears, and you pick up a vibration that feels like a bent prop.',
    spec:
        'Match the stud size and the mount height under load. Replace as a set if one has collapsed.',
    suppliers: 'chandlery or a marine engineer',
  ),
  _Guide(
    needles: ['rubber hose', 'hose'],
    why:
        'Fuel, coolant, and raw-water hoses harden and crack at the clamps. The failure is a leak you notice by smell or by a hot engine.',
    ifSkipped:
        'A fuel hose weeps into the bilge. A raw-water hose splits and the engine overheats, or the bilge fills.',
    spec:
        'Match inside diameter and whether the hose is fuel-rated, coolant, or wire-reinforced exhaust. The seeded item says replace them, not just tighten the clamps.',
    suppliers: 'chandlery',
  ),
  _Guide(
    needles: ['propeller', 'propellor'],
    why:
        'Shaft alignment and a tight prop nut are what keep the coupling from fretting. The seeded items cover spline grease and the nut, not a new propeller by default.',
    ifSkipped:
        'A loose nut frets the taper. Misalignment eats the cutless and the gearbox seal.',
    spec:
        'Grease the splines with the lubricant the coupling maker names. If you do need a propeller, the diameter, pitch, and rotation are stamped on the old one.',
    suppliers: 'chandlery for grease; a prop shop if the stamp is unreadable',
  ),
  _Guide(
    needles: ['diaphragm'],
    why:
        'The seeded diaphragm check is a fuel-pump or seal inspection. A cracked diaphragm dumps fuel or lets the pump lose prime.',
    ifSkipped: 'You get air in the fuel or a bilge that smells of diesel.',
    spec:
        'Match the pump model on its body. Diaphragms are not shared across pump brands.',
    suppliers: 'diesel shop or the pump maker’s chandlery kit',
  ),
  _Guide(
    needles: ['remote control', 'throttle'],
    why:
        'The cables have to hit the gearbox and the injection pump stops at the same time. A mis-adjusted cable slips out of gear or never reaches full throttle.',
    ifSkipped:
        'You cannot get neutral when you need it, or the engine overspeeds because the stop is wrong.',
    spec:
        'This is a cable-end and clamp check. Take the cable part number off the sheath if a cable is frayed — do not guess length.',
    suppliers:
        'chandlery for a replacement cable once you have the length and the end type',
  ),
  _Guide(
    needles: ['antifoul'],
    why:
        'The seeded sail-drive note says antifouling without copper, because copper next to aluminium eats the housing.',
    ifSkipped: 'Growth loads the drive, or the wrong paint pits the aluminium.',
    spec:
        'Use a copper-free antifoul rated for aluminium. Confirm on the tin, not from the colour.',
    suppliers: 'chandlery',
  ),
  _Guide(
    needles: ['grounding', 'continuity'],
    why:
        'The sail-drive grounding lead is there so stray current does not use the housing as the path back.',
    ifSkipped:
        'A loose bond shows up as pitting on the drive, which looks like “just corrosion” until the housing is damaged.',
    spec:
        'Clean the terminals and confirm continuity. The part, if you need one, is the bonding strap you already have — match its length and lug size.',
    suppliers: 'chandlery for a bonding strap or terminals',
  ),
  _Guide(
    needles: ['bilge', 'float switch'],
    why:
        'The bilge pump and its float switch are the backup when a hose, stuffing box, or hatch leaks. A float that sticks open runs the battery down; one that sticks shut lets the boat fill.',
    ifSkipped:
        'You find out at anchor, at night, that the automatic pump never started. A manual pump you have not tested is the same failure.',
    spec:
        'Match voltage, hose inside diameter, and fuse size to the pump label. The float switch is a separate part — match the wire and whether it is a reed or a mechanical float.',
    suppliers: 'chandlery',
  ),
  _Guide(
    needles: ['anode', 'zinc'],
    why:
        'The anode is sacrificed so the propeller, shaft, and sail drive are not. Under half remaining, it is no longer doing that job.',
    ifSkipped:
        'The metal you care about pits instead. On an aluminium drive that can be structural.',
    spec:
        'Match the shape to the old anode. Use zinc in salt water, aluminium where the yard specifies it, and magnesium only in fresh water.',
    suppliers: 'chandlery — take the old anode',
  ),
  _Guide(
    needles: [
      '50-hour',
      '50 hour',
      '250-hour',
      '250 hour',
      '500-hour',
      '500 hour',
      '1000-hour',
      '1000 hour',
    ],
    why:
        'The hour marks stack. Each block includes the shorter service plus extra inspections. Skipping one means the next service is not a fresh start.',
    ifSkipped:
        'Filters, the impeller, belts, and clearances run past the interval the schedule was built around.',
    spec:
        'Do the items in that block. The seeded 4JH45 50-hour and 250-hour lists name oil filter 129150-35170 and about 7.5 liters of oil at the first 50 hours. Other engines differ.',
    suppliers:
        'chandlery or a diesel shop for the filters, impeller, belts, and oil in that block',
  ),
];
