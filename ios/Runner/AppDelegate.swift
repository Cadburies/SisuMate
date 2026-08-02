import Flutter
import GoogleMobileAds
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // #124: tile-styled native ads — ids must match kNativeAdFactory* in
    // lib/services/admob_service.dart.
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      self, factoryId: "sisu_item_tile",
      nativeAdFactory: SisuItemTileNativeAdFactory())
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      self, factoryId: "sisu_cocktail_tile",
      nativeAdFactory: SisuCocktailTileNativeAdFactory())
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

// MARK: - #124 tile-styled native ad factories
// Colors mirror SisuColors tokens (dark: bg 0x1E1E1E, headline white, body
// 0xB0BEC5; light: bg white, headline 0x263238, body 0x546E7A) via dynamic
// providers so both themes work. Kept in this file because the Xcode project
// uses explicit file references (no synchronized groups).

private enum SisuAdStyle {
  static var tileBackground: UIColor {
    UIColor { t in t.userInterfaceStyle == .dark
      ? UIColor(red: 0x1E / 255, green: 0x1E / 255, blue: 0x1E / 255, alpha: 1)
      : .white }
  }

  static var headline: UIColor {
    UIColor { t in t.userInterfaceStyle == .dark
      ? .white
      : UIColor(red: 0x26 / 255, green: 0x32 / 255, blue: 0x38 / 255, alpha: 1) }
  }

  static var body: UIColor {
    UIColor { t in t.userInterfaceStyle == .dark
      ? UIColor(red: 0xB0 / 255, green: 0xBE / 255, blue: 0xC5 / 255, alpha: 1)
      : UIColor(red: 0x54 / 255, green: 0x6E / 255, blue: 0x7A / 255, alpha: 1) }
  }

  /// Required AdMob native-policy marker — the ad must be identifiable.
  static func adChip() -> UILabel {
    let chip = UILabel()
    chip.text = "Ad"
    chip.font = .boldSystemFont(ofSize: 11)
    chip.textColor = UIColor(red: 0x80 / 255, green: 0xDE / 255, blue: 0xEA / 255, alpha: 1)
    chip.backgroundColor = UIColor(red: 0, green: 0x66 / 255, blue: 0x66 / 255, alpha: 1)
    chip.textAlignment = .center
    chip.layer.cornerRadius = 4
    chip.layer.masksToBounds = true
    chip.translatesAutoresizingMaskIntoConstraints = false
    chip.widthAnchor.constraint(greaterThanOrEqualToConstant: 28).isActive = true
    chip.heightAnchor.constraint(equalToConstant: 18).isActive = true
    return chip
  }

  static func bind(_ adView: NativeAdView, to nativeAd: NativeAd,
                   headline: UILabel, body: UILabel?, icon: UIImageView?,
                   cta: UIButton?, media: MediaView?) {
    headline.text = nativeAd.headline
    adView.headlineView = headline

    if let body {
      body.text = nativeAd.body
      body.isHidden = nativeAd.body == nil
      adView.bodyView = body
    }
    if let icon {
      icon.image = nativeAd.icon?.image
      icon.isHidden = nativeAd.icon == nil
      adView.iconView = icon
    }
    if let cta {
      cta.setTitle(nativeAd.callToAction, for: .normal)
      cta.isHidden = nativeAd.callToAction == nil
      adView.callToActionView = cta
    }
    if let media {
      media.mediaContent = nativeAd.mediaContent
      adView.mediaView = media
    }
    adView.nativeAd = nativeAd
  }

  static func card(_ view: UIView) {
    view.backgroundColor = tileBackground
    view.layer.cornerRadius = 12
    view.layer.masksToBounds = true
  }
}

/// Full-width row matching the checklist/maintenance/safety item tiles.
class SisuItemTileNativeAdFactory: FLTNativeAdFactory {
  func createNativeAd(_ nativeAd: NativeAd,
                      customOptions: [AnyHashable: Any]? = nil) -> NativeAdView? {
    let adView = NativeAdView()
    let container = UIStackView()
    container.axis = .horizontal
    container.spacing = 12
    container.alignment = .center
    container.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    container.isLayoutMarginsRelativeArrangement = true
    SisuAdStyle.card(container)
    container.translatesAutoresizingMaskIntoConstraints = false
    adView.addSubview(container)
    NSLayoutConstraint.activate([
      container.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 16),
      container.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),
      container.topAnchor.constraint(equalTo: adView.topAnchor, constant: 6),
      container.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -6),
    ])

    let icon = UIImageView()
    icon.contentMode = .scaleAspectFit
    icon.widthAnchor.constraint(equalToConstant: 48).isActive = true
    icon.heightAnchor.constraint(equalToConstant: 48).isActive = true

    let textStack = UIStackView()
    textStack.axis = .vertical
    textStack.spacing = 2

    let headlineRow = UIStackView()
    headlineRow.axis = .horizontal
    headlineRow.spacing = 8
    headlineRow.alignment = .top
    let headline = UILabel()
    headline.font = .boldSystemFont(ofSize: 15)
    headline.textColor = SisuAdStyle.headline
    headline.numberOfLines = 2
    headlineRow.addArrangedSubview(headline)
    headlineRow.addArrangedSubview(SisuAdStyle.adChip())

    let body = UILabel()
    body.font = .systemFont(ofSize: 13)
    body.textColor = SisuAdStyle.body
    body.numberOfLines = 2

    textStack.addArrangedSubview(headlineRow)
    textStack.addArrangedSubview(body)

    let cta = UIButton(type: .system)
    cta.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)

    container.addArrangedSubview(icon)
    container.addArrangedSubview(textStack)
    container.addArrangedSubview(cta)

    SisuAdStyle.bind(adView, to: nativeAd, headline: headline, body: body,
                     icon: icon, cta: cta, media: nil)
    return adView
  }
}

/// Two-column grid card matching the cocktails/Chef recipe cards.
class SisuCocktailTileNativeAdFactory: FLTNativeAdFactory {
  func createNativeAd(_ nativeAd: NativeAd,
                      customOptions: [AnyHashable: Any]? = nil) -> NativeAdView? {
    let adView = NativeAdView()
    SisuAdStyle.card(adView)

    let media = MediaView()
    media.translatesAutoresizingMaskIntoConstraints = false
    adView.addSubview(media)
    NSLayoutConstraint.activate([
      media.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
      media.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
      media.topAnchor.constraint(equalTo: adView.topAnchor),
      media.heightAnchor.constraint(equalToConstant: 90),
    ])

    let chip = SisuAdStyle.adChip()
    adView.addSubview(chip)
    NSLayoutConstraint.activate([
      chip.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 6),
      chip.topAnchor.constraint(equalTo: adView.topAnchor, constant: 6),
    ])

    let icon = UIImageView()
    icon.contentMode = .scaleAspectFit
    icon.translatesAutoresizingMaskIntoConstraints = false
    adView.addSubview(icon)
    NSLayoutConstraint.activate([
      icon.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -6),
      icon.bottomAnchor.constraint(equalTo: media.bottomAnchor, constant: -2),
      icon.widthAnchor.constraint(equalToConstant: 36),
      icon.heightAnchor.constraint(equalToConstant: 36),
    ])

    let textStack = UIStackView()
    textStack.axis = .vertical
    textStack.spacing = 2
    textStack.layoutMargins = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
    textStack.isLayoutMarginsRelativeArrangement = true
    textStack.translatesAutoresizingMaskIntoConstraints = false
    adView.addSubview(textStack)
    NSLayoutConstraint.activate([
      textStack.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
      textStack.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
      textStack.topAnchor.constraint(equalTo: media.bottomAnchor),
      textStack.bottomAnchor.constraint(lessThanOrEqualTo: adView.bottomAnchor),
    ])

    let headline = UILabel()
    headline.font = .boldSystemFont(ofSize: 14)
    headline.textColor = SisuAdStyle.headline
    headline.numberOfLines = 2

    let body = UILabel()
    body.font = .systemFont(ofSize: 12)
    body.textColor = SisuAdStyle.body
    body.numberOfLines = 3

    let cta = UIButton(type: .system)
    cta.contentHorizontalAlignment = .leading
    cta.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)

    textStack.addArrangedSubview(headline)
    textStack.addArrangedSubview(body)
    textStack.addArrangedSubview(cta)

    SisuAdStyle.bind(adView, to: nativeAd, headline: headline, body: body,
                     icon: icon, cta: cta, media: media)
    return adView
  }
}
