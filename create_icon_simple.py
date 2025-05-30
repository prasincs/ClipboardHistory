#!/usr/bin/env python3
import os
import subprocess
try:
    from PIL import Image, ImageDraw
except ImportError:
    print("Installing Pillow...")
    subprocess.run(["pip3", "install", "Pillow"])
    from PIL import Image, ImageDraw

def create_app_icon():
    # Create a 1024x1024 icon
    size = 1024
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background gradient effect (simplified to solid color)
    # Blue gradient background
    draw.ellipse([40, 40, size-40, size-40], fill=(0, 122, 255, 255))
    
    # White clipboard background
    clipboard_width = 440
    clipboard_height = 560
    clipboard_x = (size - clipboard_width) // 2
    clipboard_y = (size - clipboard_height) // 2
    
    # Draw shadow layers (stacked papers effect)
    for i in range(3, 0, -1):
        offset = i * 8
        alpha = 80 + (3-i) * 40
        draw.rounded_rectangle(
            [clipboard_x + offset, clipboard_y + offset, 
             clipboard_x + clipboard_width + offset, clipboard_y + clipboard_height + offset],
            radius=40, fill=(255, 255, 255, alpha)
        )
    
    # Main clipboard
    draw.rounded_rectangle(
        [clipboard_x, clipboard_y, clipboard_x + clipboard_width, clipboard_y + clipboard_height],
        radius=40, fill=(255, 255, 255, 240)
    )
    
    # Clipboard clip at top
    clip_width = 200
    clip_height = 80
    clip_x = (size - clip_width) // 2
    clip_y = clipboard_y - 40
    draw.rounded_rectangle(
        [clip_x, clip_y, clip_x + clip_width, clip_y + clip_height],
        radius=20, fill=(200, 200, 200, 255)
    )
    
    # Inner clip hole
    hole_width = 140
    hole_height = 40
    hole_x = (size - hole_width) // 2
    hole_y = clip_y + 20
    draw.rounded_rectangle(
        [hole_x, hole_y, hole_x + hole_width, hole_y + hole_height],
        radius=20, fill=(180, 180, 180, 255)
    )
    
    # Content lines
    line_x = clipboard_x + 60
    line_y = clipboard_y + 100
    line_height = 20
    line_spacing = 40
    
    # Different colored lines to represent different clipboard items
    colors = [(0, 122, 255), (52, 199, 89), (255, 149, 0), (175, 82, 222)]
    widths = [240, 320, 280, 200]
    
    for i, (color, width) in enumerate(zip(colors, widths)):
        y = line_y + i * line_spacing
        draw.rounded_rectangle(
            [line_x, y, line_x + width, y + line_height],
            radius=10, fill=color + (200,)
        )
    
    # Lock icon (representing password protection)
    lock_x = line_x + 340
    lock_y = line_y + line_spacing
    lock_size = 40
    # Lock body
    draw.rounded_rectangle(
        [lock_x, lock_y + 10, lock_x + lock_size, lock_y + lock_size],
        radius=5, fill=(52, 199, 89, 255)
    )
    # Lock shackle
    draw.arc(
        [lock_x + 5, lock_y - 5, lock_x + lock_size - 5, lock_y + 25],
        start=180, end=0, fill=(52, 199, 89, 255), width=6
    )
    
    # Plus icon (copy action indicator)
    plus_x = clipboard_x + 80
    plus_y = clipboard_y + clipboard_height - 120
    plus_size = 60
    # Circle background
    draw.ellipse(
        [plus_x, plus_y, plus_x + plus_size, plus_y + plus_size],
        fill=(0, 122, 255, 255)
    )
    # Plus sign
    plus_center_x = plus_x + plus_size // 2
    plus_center_y = plus_y + plus_size // 2
    plus_thickness = 8
    plus_length = 30
    # Horizontal line
    draw.rectangle(
        [plus_center_x - plus_length//2, plus_center_y - plus_thickness//2,
         plus_center_x + plus_length//2, plus_center_y + plus_thickness//2],
        fill=(255, 255, 255, 255)
    )
    # Vertical line
    draw.rectangle(
        [plus_center_x - plus_thickness//2, plus_center_y - plus_length//2,
         plus_center_x + plus_thickness//2, plus_center_y + plus_length//2],
        fill=(255, 255, 255, 255)
    )
    
    return img

# Create the icon
print("Creating app icon...")
icon = create_app_icon()
icon.save('AppIcon.png')

# Create iconset directory
os.makedirs('AppIcon.iconset', exist_ok=True)

# Generate all required sizes
sizes = [
    (16, 16, 'icon_16x16.png'),
    (32, 16, 'icon_16x16@2x.png'),
    (32, 32, 'icon_32x32.png'),
    (64, 32, 'icon_32x32@2x.png'),
    (128, 128, 'icon_128x128.png'),
    (256, 128, 'icon_128x128@2x.png'),
    (256, 256, 'icon_256x256.png'),
    (512, 256, 'icon_256x256@2x.png'),
    (512, 512, 'icon_512x512.png'),
    (1024, 512, 'icon_512x512@2x.png'),
]

for size, label_size, filename in sizes:
    resized = icon.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(f'AppIcon.iconset/{filename}')
    print(f"Created {filename}")

# Create icns file
print("Creating .icns file...")
subprocess.run(['iconutil', '-c', 'icns', 'AppIcon.iconset', '-o', 'AppIcon.icns'])

print("\nIcon files created successfully!")
print("- AppIcon.png (source)")
print("- AppIcon.icns (for app bundle)")

# Also update the Info.plist to use the icon
print("\nUpdating Info.plist to use new icon...")