// Cloudinary configuration for client-side uploads
class CloudinaryConfig {
  // Cloudinary cloud name
  static const String cloudName = 'dmazdiq0b';
  // Upload preset for unsigned uploads (configured in Cloudinary dashboard)
  static const String uploadPreset = 'fridge_lens_images';
  // Cloudinary API Key (for demo only, not secure)
  static const String apiKey = '313582314335782';
  // Cloudinary API Secret (for demo only, not secure)
  static const String apiSecret = 'wdNmLKDKt1Y1s-WcHl8riwfcwbE';

  // WARNING: API Key and Secret should NEVER be in client-side code
  // They are only needed for server-side operations
  // For client-side uploads, only cloudName and uploadPreset are required
}
