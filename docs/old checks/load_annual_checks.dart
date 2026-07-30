import '../models/constants.dart';
import '../models/database_helper.dart';
import '../models/check.dart';
import '../models/group.dart';

Future<void> loadAnnualChecks(DatabaseHelper dbHelper) async {
  await dbHelper.addGroup(Group(
    groupId: anualChecksId,
    name: 'Anual Boat Checks',
    isDeleted: false,
    dateChecked: DateTime.parse('1800-01-01'),
  ));

  await dbHelper.addCheck(Check(
    name: "Important Disclaimer (a.k.a. the 'Don't Blame Me' Notice)",
    description:
        "This comprehensive checklist is based on the Leopard 45 2018 Catamaran model, as featured on the SailingSisu YouTube channel ((www.YouTube.com/c/SailingSisu), 'Boat Life and Boat Checks' playlist). However, please note that each vessel has unique characteristics and requirements. Before departing, it's essential to tailor this list to your specific boat, engine(s), needs, and circumstances. Additionally, ensure compliance with your country's legal regulations to avoid any potential issues. As the Skipper/Captain, the safety of your vessel, crew, and passengers is your responsibility. Use this application wisely and at your own risk. The developer shall not be held liable for any damage, loss, or injury resulting from the use of this product. Pro Version Users: Please acknowledge this notice by deleting this message, indicating your understanding of the terms.",
    groupId: anualChecksId,
    assetName: 'lib/assets/Disclaimer.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Passage Planning',
    description:
        """Plot your course for a successful voyage! Before setting sail, make sure to:
            * Chart your possible routes, anchorages, and ports to navigate like a pro
            * Tune into Port VHF frequencies for clear communication
            * Locate Customs and immigration offices to clear the way
            * Identify backup routes and anchorages for Plan B (and C, and D...)
            * Brush up on local politics, customs, and traditions to be a respectful visitor
            * Gather essential documents, including:
              + Visas for all crew members (no exceptions!)
              + Medical clearance for the crew (healthy and happy!)
              + Boat insurance (just in case!)
            * Study weather and current patterns to stay ahead of the game""",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/PassagePlanning.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Cleaning',
    description:
        "Give your vessel some TLC! Regular cleaning of the hull, deck, and topsides with a mild detergent is essential to keep your boat looking ship-shape and prolong its lifespan. A clean boat is a happy boat, and a happy boat means a safe and enjoyable sailing experience for all on board!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Cleaning.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Scuppers',
    description:
        "Keep your boat's drains and scuppers flowing freely! Clear out debris and investigate any water buildup to avoid blockages. A clear path for water to exit is essential for a safe and dry vessel - and a stress-free sailing experience.",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Scuppers.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Polish Metal',
    description:
        "Keep your boat's drains and scuppers flowing freely! Clear out debris and investigate any water buildup to avoid blockages. A clear path for water to exit is essential for a safe and dry vessel - and a stress-free sailing experience.",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/PolishMetal.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Clean Hatches',
    description:
        "Keep your boat's windows and hatches sparkling clean and leak-free! Regular cleaning and conditioning of the rubber seals with a suitable treatment like lanolin (or a similar non-petroleum based product) will keep them flexible and functioning properly. It's a small task that makes a big difference in ensuring a safe and dry sailing experience.",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/CleanHatches.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Clean Canvas',
    description:
        "Keep your boat's canvas and enclosures in top condition! Regular cleaning of your sails, bimini, and dodger will prevent dirt and grime from building up, preserving their appearance and extending their lifespan. A clean and well-maintained sail is a joy to behold, and a welcoming sailing environment for all on board!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/CleanCanvas.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Clean Interior',
    description:
        "Give your boat a thorough interior scrub-down, bilges and all! A clean and organized sailing environment is just the beginning. Don't forget to inspect for any signs of leaks, structural cracks, or damage around bulkheads - catching issues early saves time and headaches in the long run. Stay on top of maintenance and keep your boat sailing smoothly!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/CleanInterior.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Spares',
    description:
        "Don't get caught off guard - make sure you have a treasure trove of spare parts and tools on board! Regularly inspect and swap out worn or outdated items to keep your vessel running like a well-oiled machine. A little prep work now saves a lot of headaches later, and keeps your sailing adventure smooth sailing all the way!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Spares.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Boat Registration',
    description:
        "Keep your vessel's paperwork shipshape! Ensure your registration is up-to-date and easily accessible on board, so you can sail smoothly and avoid any regulatory rocky waters. Staying on top of the rules is key to a hassle-free voyage - and who doesn't love a stress-free sail?",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/BoatRegistration.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Dive Cylinders',
    description:
        "Don't let your dive cylinders become a ticking time bomb! Regularly check their expiry dates and give them a thorough visual and hydrostatic once-over. Replace or renew them as needed, and breathe easy knowing you've got a safe and reliable setup for your underwater adventures.",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/DiveCylinders.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Dive Compressor Operation',
    description:
        "Keep your Bavaria FUNII EM Dive Compressor in top shape! Regular inspections and maintenance are key to its optimal operation, and a reliable air supply is the breath of life for your diving adventures. Don't let a faulty compressor leave you feeling deflated - stay on top of its upkeep and dive with confidence!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/DiveCompressor.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Dive Compressor Oil',
    description:
        "Don't let your dive compressor go dry! Regularly check the oil level and keep it well-lubricated with #SM107 Mineral Oil. A smooth-running compressor is the backbone of your diving adventures, and adequate lubrication is the key to its optimal performance and long lifespan. Keep it well-oiled and dive with peace of mind!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/CompressorOil.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Dive Compressor Filter',
    description:
        "Keep your dive compressor in top gear with a fresh filter! Regularly replacing the #VM10300100 filter ensures optimal performance, extends its lifespan, and keeps your air compression and delivery running smoothly. It's a small swap that makes a big difference in safe and reliable diving ops - don't let a dirty filter slow you down!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/CompressorFilter.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Hull Condition',
    description:
        "Give your hull a thorough check-up! Regularly inspect for scratches, gouges, and stress fractures, and address any issues promptly to keep your vessel looking and performing its best. A well-maintained hull is the foundation of safe and efficient operation - don't let damage sneak up on you!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/HullCondition.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Zinc Anodes',
    description:
        "Keep your boat's metal components shining like new! Regularly inspect and replace your prop and saildrive zinc anodes as needed to prevent corrosion and ensure longevity. It's a small change that makes a big difference in performance and prevents damage to surrounding metal parts - don't let corrosion anchor you down!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/ZincAnodes.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'DriveTrain',
    description:
        "Get your boat's propulsion system in top gear! Perform a thorough inspection of the sail drive, seals, shafts, cutlass bearings, and propellers to ensure optimal performance and prevent damage. Regular maintenance is the anchor that keeps your sailing experience safe and reliable - don't let issues slip beneath the surface!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/DriveTrain.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Antifouling',
    description:
        "Keep your boat in shipshape condition! A fresh coat of antifouling paint or a replacement when needed will keep marine growth and fouling at bay, reducing drag and boosting fuel efficiency. Regular hull maintenance is the key to a smooth sailing experience and a long, happy life for your vessel - don't let fouling get in the way!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Antifouling.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Stanchions',
    description:
        "Stay on guard with your guardrails! Regularly inspect your stanchions, pulpits, and lifelines to ensure they're in top condition. A secure rail is the best way to keep your crew safe and dry - don't let them become unexpected swimmers! Prioritize a safe and enjoyable sailing experience, and keep your guardrails on high alert!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Stanchions.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Mooring Lines',
    description:
        "Keep your mooring lines shipshape! Regularly inspect for chafe and wear, and replace them if needed. A well-maintained line is the anchor that keeps your sailing experience secure - don't let it become a tangled mess! Prioritize a smooth sail, and keep your lines in top condition!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/MooringLines.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Mooring Cleats',
    description:
        "Mooring cleats are the unsung heroes of sailing - give them the attention they deserve! Conduct a thorough inspection to ensure they're in top shape. Check for tightness, cracks, and weak spots, and keep an eye out for any signs of leaks or water ingress. A secure cleat is the anchor that keeps your sailing experience safe and sound - don't let it slip through the cracks!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/MooringCleats.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Mooring Fenders',
    description:
        "Don't let your fenders fall flat! Check them regularly and inflate or replace as needed to keep your boat and dock in perfect harmony.",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/MooringFenders.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name:
        "Be prepared for any mooring situation! Keep spare mooring fenders and lines on hand to ensure a smooth and secure docking experience. It's always better to be safe than sorry - and a little extra preparation can save you from a whole lot of hassle!",
    description: 'Ensure spare lines and fenders are available',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/SpareFenders.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Ground Tackle',
    description:
        "Anchor down with confidence! Inspect your anchor chain, swivel, and anchor regularly to ensure they're in top shape. Don't let a weak link wreck your holiday!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/GroundTackle.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Windlass',
    description:
        "Wind up your anchor game! Clean and service your anchor windlass and remotes regularly to ensure a smooth and secure anchoring experience - no one likes a tangled mess!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Windlass.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Winches',
    description:
        "Keep your winches winding smoothly! Service them regularly to prevent stress fractures and leaks, and avoid getting caught in a sticky situation.",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Winches.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Swim Ladder',
    description:
        "Make a splash with safety! Check your swim ladder's security and operation, and don't let leaks leave you high and dry - ensure a smooth entry and exit from the water!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/SwimLadder.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Port Light Leaks',
    description:
        "Seal the deal on safety! Check your deck, windows, and port lights for leaks to avoid a sinking feeling!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/PortLight.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Davits',
    description:
        "Stay lifted! Check your Davits and control cables for excess wear and smooth operation - don't let worn-out cables bring you down!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Davits.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Seacocks',
    description:
        "Seacocks in check! Regularly test and lubricate them to keep your vessel's plumbing flowing smoothly.",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Seacocks.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Hoses Below Decks',
    description:
        "Hose down the competition! Check your hoses and clamps regularly, and replace them as needed to avoid any leaks or blowouts - keep your vessel's fluids flowing smoothly!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/HosesBelowDecks.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Hoses Below Waterline',
    description:
        "Double down on safety! Ensure hoses below the waterline are securely double clamped to prevent any leaks or flooding - keep your vessel afloat and your worries at bay!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/HosesBelowWaterline.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Bilge Pumps',
    description:
        "Pump up the safety! Check your bilge pumps for seamless automatic and manual operation, and test the high water level alarm to ensure you're never caught off guard - stay afloat and in control!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/BilgePumps.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Bilges',
    description:
        "Stay leak-free and stress-less! Check your bilges for oil or water, and fix any leaks promptly. Also, inspect for salt lines or buildup near skin fittings, seacocks, and thru-hulls to catch potential leaks before they become major issues.",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Bilge.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Limber Holes',
    description:
        "Clear the way! Check your limber holes and ensure they're free from debris - keep the water flowing and your vessel's plumbing happy!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/LimberHoles.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Batteries',
    description:
        "Power up! Check, recharge, or replace your batteries as needed - a dead battery can leave you stranded, but a well-maintained one will keep you energized and in control. Don't let a flat battery drain your voyage!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Batteries.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Battery Terminals',
    description:
        "Connect with confidence! Check your battery terminals for corrosion, clean them up, and lubricate for a smooth connection - a clean terminal is a happy terminal, and a happy terminal keeps your vessel powered and your journey uninterrupted!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/BatteryTerminals.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Charger/Inverter',
    description:
        "Charge ahead! Check your battery charger and inverter's operation to ensure they're working in harmony - a well-balanced power flow keeps your vessel's energy levels high and your journey on course!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Inverter.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Galvanic Isolator',
    description:
        "Grounded and safe! Check your galvanic isolator system to ensure it's functioning properly, and double-check that your AC ground is still connected to shore - a solid grounding system keeps your vessel and crew protected from electrical shocks and makes for a shock-free sailing experience!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/GalvanicIsolator.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Wiring',
    description:
        "Wired for success! Inspect all wiring for wear and chafe, and check for corrosion at terminals - a well-maintained wiring system keeps your vessel's electrical flow smooth, and your journey free from short-circuits and shocks!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Wiring.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Gauges',
    description:
        "Metering success! Test all gauges and instruments for proper operation - a well-calibrated dashboard keeps you informed, in control, and navigating smoothly through the waters of uncertainty!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Gauges.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Speed log',
    description:
        "Speed Log jam avoided! Pull the speed log to clean it from debris and growth, and remember to replace the impeller and speed log in the correct direction after cleaning - a clear and accurate speed log keeps you on course.",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/SpeedLog.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Shore Power Cables',
    description:
        "Power up with confidence! Check your shore power cables and connectors for any signs of burnout, corrosion, or damage, and replace them if necessary - a secure and reliable power connection keeps your vessel energized, so don't let a faulty cable leave you in the dark!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/ShorePower.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Spare Fuses',
    description:
        "Fuse with ease! Check for spare fuses to ensure you're prepared for any electrical emergency - a well-stocked fuse box is like having a superhero cape for your vessel's electrical system, saving the day one blown fuse at a time!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/SpareFuses.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Light Bulbs',
    description:
        "Shine on! Check all lighting fixtures and stock up on spare bulbs - a well-lit vessel is not only safer, but also a beacon of hospitality, welcoming all on board to a bright and cozy atmosphere. Don't let a burnt-out bulb leave you in the dark!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/LightBulbs.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Electronics',
    description:
        "Electrify your voyage! Check all electronics for proper operation, switching on instruments and gauges to ensure they're functioning correctly - a well-lit and humming instrument panel is music to a sailor's ears! Verify that all backlighting is shining bright, and that no sneaky fuse has blown, leaving you in the dark. A smooth-sailing electronics check keeps your journey on course!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Electronics.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Antennas',
    description:
        "Stay connected, stay safe! Inspect your VHF, AIS, GPS, EPIRB, and WiFi antennas for corrosion - a clear signal is just a clean antenna away! Corrosion can disrupt your connection to the world, leaving you lost at sea (figuratively, of course!). Keep your antennas in top shape to ensure a strong signal and a successful voyage.",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Sound Horn',
    description:
        "Sound the alarm! Check your sound signalling device to ensure it's in working order - a loud and clear signal can be the difference between a near-miss and a safe passage. Don't let a silent signal leave you in a precarious position, make sure your device is sounding off loud and clear!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/SoundHorn.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Flares',
    description:
        "Signal for help, not hassle! Check your distress signals and expiration dates to ensure they're ready for use - a functioning distress signal can be the difference between a rescue and a prolonged predicament. Don't let an expired signal leave you in distress, replace as necessary and stay safe!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Flares.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Harnasses',
    description:
        "Hold tight, stay safe! Check your harnesses and tethers for wear and tear - a secure connection is just a check away! Don't let frayed edges or worn-out straps leave you hanging loose, inspect and replace as needed to keep your journey secure and your mind at ease.",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/OneWeek/Harnasses.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'PFD Cartridges',
    description:
        "Inflate your safety, not your worries! Check your inflatable PFD cartridges and bobbin to ensure they're ready for deployment - a properly functioning PFD can be the difference between a close call and a safe return to shore. Don't let an expired cartridge or tangled bobbin leave you deflated, inspect and replace as needed to keep your safety afloat!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/PFDCartridges.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'PFD Equipment',
    description:
        "Lifesaving gear, in top gear! Check your PFD equipment for wear and tear - a well-maintained PFD is like a trusted companion, always ready to save the day! Don't let frayed straps or faded fabric leave you high and dry, inspect and replace as needed to keep your safety afloat and your mind at ease.",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/PFDEquipment.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Life Rings',
    description:
        "Ring in safety, shine on! Inspect your life rings and cushions to ensure they're in top shape - a reliable lifeline can be the difference between a close call and a safe return to shore. And don't forget to check the rescue light, because a bright idea can quickly turn into a lifesaver! Make sure it's functioning properly to guide the way to safety.",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/LifeRings.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire Extinguishers',
    description:
        "Extinguish worries, not fires! Check your fire extinguishers' service and recharge if necessary - a fully charged extinguisher is like a trusty sidekick, ready to save the day! Don't forget to inspect other fire-fighting equipment like fire blankets, and ensure all access points to engine rooms are open and clear. A well-prepared fire response is the best defense against a blazing disaster!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/FireExtinguishers.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Compass',
    description:
        "Stay on course, stay enlightened! Check and adjust your compass to ensure it's pointing you in the right direction - a accurate compass is like a trusted navigator, always guiding you home. And don't forget to check the backlight for proper operation. A well-lit compass is like a beacon in the dark.",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Compass.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Navigation Lights',
    description:
        'Check operation of navigation lights make sure you have spare bulbs for starboard, port, stern, steaming, and deck lights. Some smaller boats uses tri-color light on the mast so, ensure that you have the correct spares.',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/NavigationLights.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Paper Charts',
    description:
        "Chart your course, stay on track! Check your charts and replace or update them as necessary - a current chart is like a reliable roadmap, guiding you through treacherous waters. And don't forget to look for any additional notes that may have been issued since the chart was printed, because a small update can make a big difference in your journey! Stay informed, stay safe, and avoid getting lost at sea... or at least, lost in navigation!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/PaperCharts.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Electronic Charts',
    description:
        "Navigate with confidence, chart your course! Confirm your Electronic Chart coverage and expiration dates for the passage - a valid chart is like a trusted co-pilot, ensuring you stay on course. Download the area covering the passage, as well as backup routes, because a safe journey is like a well-planned detour - it's always better to be prepared! Don't let outdated charts leave you lost at sea, stay up-to-date and navigate with ease!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/ElectronicCharts.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Radar Reflector',
    description:
        "Reflect on safety, shine bright! Check your radar reflector to ensure it's in top condition - a functional reflector is like a beacon calling out to others, 'I'm here, steer clear!' Don't get lost in the fog, make sure your radar reflector is working properly to avoid collisions and keep your journey on course. A little reflection can go a long way in staying safe at sea!",
    groupId: anualChecksId,
    isDeleted: true,
    assetName: 'lib/assets/lists/AnualChecks/RadarReflector.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Medicines',
    description:
        "Medicine cabinet, not a treasure chest! Check expiry dates on medicines and replace or replenish if needed - expired meds are like anchors without a hold, they won't keep you safe in rough waters! Keep your medical supplies ship-shape and up-to-date, so you can weather any storm. Don't let expired medications leave you feeling seasick, stay healthy and prepared with fresh supplies!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Medicines.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Grab Bag',
    description:
        "Provision for safety, not spoilage! Check expiry dates on grab bag items like food - expired rations are like a sinking ship, they won't keep you afloat in an emergency! Keep your grab bag stocked with fresh supplies, so you can weather any storm.",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/GrabBag.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'First Aid',
    description:
        "Bandage your worries, not just your boo-boos! Check and replace first aid supplies as required - a well-stocked first aid kit is like a trusted crew member, always ready to lend a helping hand. Don't let expired supplies leave you feeling stuck, keep your first aid kit ship-shape and up-to-date, so you can patch up any problem that comes your way!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/FirstAid.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Liferaft',
    description:
        "Liferaft: your safety net, not a guessing game! Check your liferaft and service as required - a well-maintained liferaft is like a reliable anchor, holding you secure in rough waters. Don't leave your safety to chance, ensure your liferaft is in top condition, so you can weather any storm with confidence!",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Liferaft.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Heads',
    description:
        "'Head' in the right direction with a smooth-operating toilet! Check your heads/toilets for proper operation - a well-lubricated and clean toilet is like a trusted navigator, guiding you through choppy waters. Don't let leaks leave you high and dry, ensure a tight seal to avoid any messy situations. And remember, clear hoses are like clear sailing - descale or replace them if flow is restricted, so you can keep your journey flowing smoothly! Finally, check those raw intake strainers to ensure a smooth ride.",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Toilets.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Holding Tanks',
    description:
        "'Holding' onto a clean conscience? Check and flush/pump out holding tanks in a legal manner - a responsible sailor's duty! Don't let waste weigh you down, dispose of it properly to avoid any 'crappy' situations.",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/HoldingTanks.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Skin Fittings',
    description:
        "Don't let leaks or blockages leave you high and dry, ensure all skin fittings and valves are in top condition to avoid any 'leaky' situations.",
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/HosesBelowDecks.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Holding Tank Sensor',b
    description: 'Check operation of holding tank watch sensor & light',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/TankSensor.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Diesel Tanks',
    description: 'Check Diesel Tank for water, debris and bio bugs',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/DieselTanks.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: '250 Hour Engine Service',
    description:
        'Do the 250 Hour Engine Service as per service manual instructions',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/250HourEngineService/EngineOilFilter.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Inventory of Coolant',
    description: 'Check Inventory of Coolant',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Inventory Engine Oil',
    description: 'Check Inventory Engine Oil',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/InventoryEngineOil.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Inventory Engine Oil Filters',
    description: 'Check Inventory Engine Oil Filters',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/250HourEngineService/EngineOilFilter.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Inventory Fuel Filters',
    description: 'Check Inventory Fuel Filters',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/250HourEngineService/FuelFilter.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Inventory Fuel Seperator',
    description: 'Check Inventory Fuel Water Seperator Filters',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/250HourEngineService/FuelSeperator.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Inventory of spare belts',
    description: 'Check Inventory of spare belts',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/SpareBelts.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Inventory impellers',
    description: 'Check Inventory impellers',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/250HourEngineService/Impeller.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Maintenance Log',
    description:
        'Record engine maintenance log, especially date & hours of last oil changes',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Fresh Water Tanks',
    description:
        'Flush & clean water tanks. Add a cup of vinegar and bleach to main tanks,  fill the pipes by flushing both the cold and hotw ater taps until you smell bleach. Let it stand overnight.  Flush tanks thoroughly antill bleach smell is detected.',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/FreshWaterTanks.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Water System',
    description: 'Check water system and pumps for leaks and proper operation',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/WaterSystem.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Hot Water',
    description: 'Check hot water tanks working on both ac and engines',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/HotWater.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Taps and Drains',
    description: 'Check operation of all taps & drains',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/HotWater.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Shower Sump Pump',
    description: 'Check and clean shower sump pump filter screens',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/ShowerSumpPump.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Water Maker Filters',
    description:
        'Check and replace if needed. Also took inventory Water Maker Pore-Filters, 20 micron #FT-FTC-20, 5 micron #FT-FTC-5, and carbon #FT-FTC-CC',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/WaterMakerFilters.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Washer Dryer',
    description: 'Washer Dryer filter clean and rimse/wash cycle with vinegar',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/WasherDryerFilter.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'LPG Hoses',
    description:
        'Check operation of electric & manual valves, Check gas locker vent to make sure it is clear,  Check seal on gas locker lid, Check all LPG supply hoses & clamps for leaks with soapy water  and tighten or replace as required',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/OneWeek/LPGGas.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Refrigerator and Freezer',
    description: 'Check refrigerator, clean and freshen, operate on DC and DC',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Refrigerator.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Air Conditioners',
    description:
        'Check aircon, clean the cooling vanes from any dust or debris. Clean raw intake lines and strainers.',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/AirCon.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Stove and Burners',
    description:
        'Clean stove, Check that all burners, oven & ignition are working',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/StoveBurners.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Steering',
    description: 'Check general condition. Check steering lock operation.',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Steering.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Steering Cables, Chain, and Hoses',
    description:
        'Look for wear and chafing on cables & steering chains / hoses. Recalibrate steering centre if required.',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/SteeringCables.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Hydraulic',
    description: 'Check hydraulic pipes for leaks',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    isDeleted: true,
  ));
  await dbHelper.addCheck(Check(
    name: 'Rudder',
    description:
        'Check rudders, rudder arms, and fittings such as electronic angle sensor. Also check the emergency tiller for good operation.',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Rudder.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Rudder Bearings',
    description: 'Check all rudder bearings for wear',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/RudderBearings.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));
  await dbHelper.addCheck(Check(
    name: 'Steering Calibration',
    description: 'Check calibration of auto pilot & compass',
    groupId: anualChecksId,
    assetName: 'lib/assets/lists/AnualChecks/SteeringCalibration.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
  ));

// TODO(Frik): Add trampoline lines inspection
}
