#!/usr/bin/env python3
from PIL import Image, ImageDraw

def create_menubar_icon():
    # Create 22x22 icon for menu bar (template image)
    size = 22
    scale = 4  # Create at higher resolution then scale down
    img_size = size * scale
    
    img = Image.new('RGBA', (img_size, img_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Scale all coordinates by scale factor
    def s(val):
        return val * scale
    
    # Draw clipboard shape
    # Body
    clipboard_x = s(4)
    clipboard_y = s(2)
    clipboard_w = s(14)
    clipboard_h = s(18)
    
    draw.rounded_rectangle(
        [clipboard_x, clipboard_y, clipboard_x + clipboard_w, clipboard_y + clipboard_h],
        radius=s(2), fill=(0, 0, 0, 255)
    )
    
    # Clip at top
    clip_x = s(7)
    clip_y = s(1)
    clip_w = s(8)
    clip_h = s(4)
    
    draw.rounded_rectangle(
        [clip_x, clip_y, clip_x + clip_w, clip_y + clip_h],
        radius=s(1), fill=(0, 0, 0, 255)
    )
    
    # Hole in clip
    hole_x = s(9)
    hole_y = s(2)
    hole_w = s(4)
    hole_h = s(2)
    
    draw.rectangle(
        [hole_x, hole_y, hole_x + hole_w, hole_y + hole_h],
        fill=(0, 0, 0, 0)
    )
    
    # Content lines (cut out from clipboard)
    line_x = clipboard_x + s(2)
    line_w = s(10)
    line_h = s(1.5)
    line_spacing = s(3)
    
    for i in range(3):
        y = clipboard_y + s(5) + i * line_spacing
        width = line_w - i * s(2)  # Make lines progressively shorter
        draw.rectangle(
            [line_x, y, line_x + width, y + line_h],
            fill=(0, 0, 0, 0)
        )
    
    # Scale down to final size with antialiasing
    img = img.resize((size, size), Image.Resampling.LANCZOS)
    
    # Create template versions (black pixels with varying alpha)
    template = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    
    for x in range(size):
        for y in range(size):
            r, g, b, a = img.getpixel((x, y))
            if a > 0:
                # Convert to template format (black with alpha)
                template.putpixel((x, y), (0, 0, 0, a))
    
    return template

# Create regular and @2x versions
icon = create_menubar_icon()
icon.save('MenuBarIcon.png')

# Create @2x version
icon_2x = create_menubar_icon()
icon_2x = icon_2x.resize((44, 44), Image.Resampling.LANCZOS)
icon_2x.save('MenuBarIcon@2x.png')

print("Menu bar icons created:")
print("- MenuBarIcon.png (22x22)")
print("- MenuBarIcon@2x.png (44x44)")