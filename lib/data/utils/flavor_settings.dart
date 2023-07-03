enum BuildFlavor { dev, free, premium }

class FlavorSettings {
  String apiBaseUrl;
  String appName;
  BuildFlavor flavor;

  FlavorSettings.dev()
      : apiBaseUrl = '',
        appName = 'Kamera GPS Lokasi: Dev',
        flavor = BuildFlavor.dev;

  FlavorSettings.free()
      : apiBaseUrl = '',
        appName = 'Kamera GPS Lokasi: Free',
        flavor = BuildFlavor.free;

  FlavorSettings.premium()
      : apiBaseUrl = '',
        appName = 'Kamera GPS Lokasi: Premium',
        flavor = BuildFlavor.premium;
}
