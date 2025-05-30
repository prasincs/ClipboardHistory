#!/usr/bin/env python3
import os
import subprocess

# Create a professional app icon using SF Symbols and color
icon_svg = '''<?xml version="1.0" encoding="UTF-8"?>
<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <!-- Background Circle with Gradient -->
  <defs>
    <linearGradient id="bgGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#007AFF;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#0051D5;stop-opacity:1" />
    </linearGradient>
    <filter id="shadow" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur in="SourceAlpha" stdDeviation="10"/>
      <feOffset dx="0" dy="10" result="offsetblur"/>
      <feFlood flood-color="#000000" flood-opacity="0.2"/>
      <feComposite in2="offsetblur" operator="in"/>
      <feMerge>
        <feMergeNode/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
  
  <!-- Main Background Circle -->
  <circle cx="512" cy="512" r="480" fill="url(#bgGradient)" filter="url(#shadow)"/>
  
  <!-- Inner Circle for depth -->
  <circle cx="512" cy="512" r="440" fill="none" stroke="white" stroke-width="2" opacity="0.3"/>
  
  <!-- Clipboard Base -->
  <g transform="translate(512, 512)">
    <!-- Clipboard Body -->
    <rect x="-220" y="-280" width="440" height="560" rx="40" ry="40" 
          fill="white" opacity="0.95"/>
    
    <!-- Clipboard Clip -->
    <rect x="-100" y="-320" width="200" height="120" rx="20" ry="20" 
          fill="#E0E0E0" stroke="#CCCCCC" stroke-width="4"/>
    <rect x="-70" y="-300" width="140" height="60" rx="30" ry="30" 
          fill="#CCCCCC"/>
    
    <!-- History Lines representing stacked papers -->
    <rect x="-200" y="-260" width="400" height="520" rx="30" ry="30" 
          fill="white" stroke="#E0E0E0" stroke-width="2" opacity="0.4" 
          transform="translate(15, 15) rotate(3)"/>
    <rect x="-200" y="-260" width="400" height="520" rx="30" ry="30" 
          fill="white" stroke="#E0E0E0" stroke-width="2" opacity="0.6" 
          transform="translate(8, 8) rotate(1.5)"/>
    
    <!-- Content Lines -->
    <rect x="-160" y="-180" width="240" height="16" rx="8" ry="8" fill="#007AFF" opacity="0.8"/>
    <rect x="-160" y="-140" width="320" height="16" rx="8" ry="8" fill="#34C759" opacity="0.8"/>
    <rect x="-160" y="-100" width="280" height="16" rx="8" ry="8" fill="#FF9500" opacity="0.8"/>
    <rect x="-160" y="-60" width="200" height="16" rx="8" ry="8" fill="#AF52DE" opacity="0.8"/>
    
    <!-- Lock icon for password items -->
    <g transform="translate(100, -140)">
      <rect x="-15" y="-8" width="30" height="22" rx="4" ry="4" fill="#34C759"/>
      <path d="M -10 -8 L -10 -14 A 10 10 0 0 1 10 -14 L 10 -8" 
            fill="none" stroke="#34C759" stroke-width="6"/>
      <circle cx="0" cy="4" r="4" fill="white"/>
    </g>
    
    <!-- Plus icon indicating copy action -->
    <g transform="translate(-120, 180)">
      <circle cx="0" cy="0" r="40" fill="#007AFF"/>
      <rect x="-20" y="-4" width="40" height="8" rx="4" ry="4" fill="white"/>
      <rect x="-4" y="-20" width="8" height="40" rx="4" ry="4" fill="white"/>
    </g>
  </g>
</svg>'''

# Write the SVG file
with open('AppIcon.svg', 'w') as f:
    f.write(icon_svg)

# Create different sizes for iconset
sizes = [16, 32, 64, 128, 256, 512, 1024]
os.makedirs('AppIcon.iconset', exist_ok=True)

for size in sizes:
    # Normal resolution
    cmd = [
        'rsvg-convert',
        '-w', str(size),
        '-h', str(size),
        'AppIcon.svg',
        '-o', f'AppIcon.iconset/icon_{size}x{size}.png'
    ]
    # Try using rsvg-convert if available, otherwise use sips
    try:
        subprocess.run(cmd, check=True)
    except:
        # Fallback to sips (macOS built-in)
        subprocess.run([
            'sips', '-z', str(size), str(size),
            'AppIcon.svg',
            '--out', f'AppIcon.iconset/icon_{size}x{size}.png'
        ])
    
    # @2x resolution for retina
    if size <= 512:
        try:
            cmd = [
                'rsvg-convert',
                '-w', str(size * 2),
                '-h', str(size * 2),
                'AppIcon.svg',
                '-o', f'AppIcon.iconset/icon_{size}x{size}@2x.png'
            ]
            subprocess.run(cmd, check=True)
        except:
            subprocess.run([
                'sips', '-z', str(size * 2), str(size * 2),
                'AppIcon.svg',
                '--out', f'AppIcon.iconset/icon_{size}x{size}@2x.png'
            ])

# Create the icns file
subprocess.run(['iconutil', '-c', 'icns', 'AppIcon.iconset', '-o', 'AppIcon.icns'])

print("Icon created successfully!")
print("- AppIcon.svg (source)")
print("- AppIcon.icns (for app bundle)")
print("- AppIcon.iconset/ (individual sizes)")

# Also create a simpler menu bar icon
menubar_svg = '''<?xml version="1.0" encoding="UTF-8"?>
<svg width="22" height="22" viewBox="0 0 22 22" xmlns="http://www.w3.org/2000/svg">
  <!-- Simplified clipboard for menu bar -->
  <g transform="translate(11, 11)">
    <!-- Clipboard body -->
    <rect x="-7" y="-9" width="14" height="18" rx="2" ry="2" 
          fill="none" stroke="currentColor" stroke-width="1.5"/>
    <!-- Clip -->
    <rect x="-4" y="-10" width="8" height="4" rx="1" ry="1" 
          fill="currentColor"/>
    <!-- Lines -->
    <rect x="-5" y="-4" width="10" height="1.5" rx="0.75" fill="currentColor" opacity="0.8"/>
    <rect x="-5" y="-1" width="8" height="1.5" rx="0.75" fill="currentColor" opacity="0.6"/>
    <rect x="-5" y="2" width="6" height="1.5" rx="0.75" fill="currentColor" opacity="0.4"/>
  </g>
</svg>'''

with open('MenuBarIcon.svg', 'w') as f:
    f.write(menubar_svg)

print("\nMenu bar icon created: MenuBarIcon.svg")