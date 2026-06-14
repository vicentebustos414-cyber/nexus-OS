# NexusOS Backgrounds

## Files
- `nexusos-background.svg` - Default wallpaper (1920x1080)

## How to Add Custom Wallpapers

1. Place your image in this directory
2. Update dconf configuration in:
   ```
   /etc/dconf/db/local.d/01-background
   ```
3. Change the `picture-uri` line to point to your image:
   ```
   picture-uri='file:///usr/share/backgrounds/nexusos/your-image.png'
   ```
4. Recompile dconf database:
   ```bash
   dconf update
   ```

## Recommended Specifications
- Resolution: 1920x1080 or higher
- Format: PNG, JPG, or SVG
- Size: < 5MB
- Color profile: sRGB

## SVG Advantages
- Scalable to any resolution
- Smaller file size
- Hardware-accelerated rendering
