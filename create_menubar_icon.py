#!/usr/bin/env python3
from PIL import Image, ImageDraw

def create_menubar_icon(size=22):
    # Create icon at 4x scale for better quality
    scale = 4
    img_size = size * scale
    
    img = Image.new('RGBA', (img_size, img_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Scale helper
    def s(val):
        return int(val * scale)
    
    # Draw a simpler, bolder clipboard design
    # Main clipboard body
    body_margin = s(3)
    body_width = img_size - 2 * body_margin
    body_height = int(body_width * 1.2)
    body_y = (img_size - body_height) // 2 + s(1)
    
    # Draw clipboard background
    draw.rounded_rectangle(
        [body_margin, body_y, body_margin + body_width, body_y + body_height],
        radius=s(2), fill=(0, 0, 0, 255), width=0
    )
    
    # Draw clip at top
    clip_width = body_width // 2
    clip_height = s(5)
    clip_x = body_margin + (body_width - clip_width) // 2
    clip_y = body_y - s(2)
    
    draw.rounded_rectangle(
        [clip_x, clip_y, clip_x + clip_width, clip_y + clip_height],
        radius=s(1), fill=(0, 0, 0, 255)
    )
    
    # Draw hole in clip (white cutout)
    hole_width = clip_width - s(4)
    hole_height = s(2)
    hole_x = clip_x + (clip_width - hole_width) // 2
    hole_y = clip_y + s(1)
    
    draw.rounded_rectangle(
        [hole_x, hole_y, hole_x + hole_width, hole_y + hole_height],
        radius=s(1), fill=(255, 255, 255, 0)
    )
    
    # Draw content lines (white on black)
    line_margin = s(2)
    line_x = body_margin + line_margin
    line_y = body_y + s(6)
    line_height = s(1.5)
    line_spacing = s(2.5)
    
    # Three lines with decreasing width
    line_widths = [body_width - 2 * line_margin, 
                   body_width - 3 * line_margin,
                   body_width - 4 * line_margin]
    
    for i, width in enumerate(line_widths):
        y = line_y + i * line_spacing
        draw.rounded_rectangle(
            [line_x, y, line_x + width, y + line_height],
            radius=s(0.5), fill=(255, 255, 255, 255)
        )
    
    # Scale down with antialiasing
    final_img = img.resize((size, size), Image.Resampling.LANCZOS)
    
    # Convert to template format (black with proper alpha)
    template = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    
    # Process pixels for template image
    for x in range(size):
        for y in range(size):
            r, g, b, a = final_img.getpixel((x, y))
            if a > 0:
                # For template images, we want black pixels with alpha
                # White areas become transparent
                if r > 128:  # White pixels
                    template.putpixel((x, y), (0, 0, 0, 0))
                else:  # Black pixels
                    template.putpixel((x, y), (0, 0, 0, a))
    
    return template

# Create regular and @2x versions
icon = create_menubar_icon(22)
icon.save('MenuBarIcon.png')

# Create @2x version
icon_2x = create_menubar_icon(44)
icon_2x.save('MenuBarIcon@2x.png')

print("Menu bar icons created:")
print("- MenuBarIcon.png (22x22)")
print("- MenuBarIcon@2x.png (44x44)")