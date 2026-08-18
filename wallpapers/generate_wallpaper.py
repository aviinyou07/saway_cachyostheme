#!/usr/bin/env python3
"""
Cyber Noir 4K Wallpaper Palette Suite for CachyOS
-------------------------------------------------
Generates 5 production-grade, minimalist 4K vector wallpapers (3840x2160)
and converts them immediately to PNG using rsvg-convert:
  1. cyber_noir_4k (Classic Obsidian + Cyber Cyan & Neon Green)
  2. cyber_emerald_4k (Matrix Emerald + Neon Mint)
  3. cyber_synthwave_4k (Electric Pink + Neon Violet)
  4. cyber_crimson_4k (Red Team Blood + Amber Glow)
  5. cyber_midnight_4k (Cobalt Blue + Ice White)
"""

import math
import random
import sys
import os
import subprocess

WIDTH = 3840
HEIGHT = 2160

THEMES = {
    "cyber_noir_4k": {
        "bg": "#0A0A0A",
        "grid_main": "#1A1A1A",
        "grid_sub": "#121212",
        "line_color": "#00E5FF",
        "node_color": "#39FF14",
        "seed": 1337
    },
    "cyber_emerald_4k": {
        "bg": "#070C09",
        "grid_main": "#15241B",
        "grid_sub": "#0D1711",
        "line_color": "#00FF66",
        "node_color": "#00E5FF",
        "seed": 2026
    },
    "cyber_synthwave_4k": {
        "bg": "#0B0813",
        "grid_main": "#1E1433",
        "grid_sub": "#140D22",
        "line_color": "#FF007F",
        "node_color": "#BF00FF",
        "seed": 42
    },
    "cyber_crimson_4k": {
        "bg": "#0C0808",
        "grid_main": "#261515",
        "grid_sub": "#190E0E",
        "line_color": "#FF1A1A",
        "node_color": "#FFB300",
        "seed": 999
    },
    "cyber_midnight_4k": {
        "bg": "#060810",
        "grid_main": "#141C33",
        "grid_sub": "#0C1120",
        "line_color": "#1F51FF",
        "node_color": "#E0F7FF",
        "seed": 31337
    }
}

def generate_theme(name, cfg, out_dir):
    random.seed(cfg["seed"])
    svg_path = os.path.join(out_dir, f"{name}.svg")
    png_path = os.path.join(out_dir, f"{name}.png")

    svg_lines = [
        f'<?xml version="1.0" encoding="UTF-8" standalone="no"?>',
        f'<svg width="{WIDTH}" height="{HEIGHT}" viewBox="0 0 {WIDTH} {HEIGHT}" '
        'xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
        '  <defs>',
        f'    <filter id="glow-line" x="-50%" y="-50%" width="200%" height="200%">',
        '      <feGaussianBlur stdDeviation="6" result="blur1" />',
        '      <feGaussianBlur stdDeviation="3" result="blur2" />',
        '      <feMerge><feMergeNode in="blur1" /><feMergeNode in="blur2" /><feMergeNode in="SourceGraphic" /></feMerge>',
        '    </filter>',
        f'    <filter id="glow-node" x="-50%" y="-50%" width="200%" height="200%">',
        '      <feGaussianBlur stdDeviation="5" result="blur1" />',
        '      <feGaussianBlur stdDeviation="2" result="blur2" />',
        '      <feMerge><feMergeNode in="blur1" /><feMergeNode in="blur2" /><feMergeNode in="SourceGraphic" /></feMerge>',
        '    </filter>',
        '  </defs>',
        '',
        f'  <rect width="{WIDTH}" height="{HEIGHT}" fill="{cfg["bg"]}" />',
        '  <g id="hex-mesh" opacity="0.8">'
    ]

    cols = 14
    rows = 9
    x_step = WIDTH / (cols - 1)
    y_step = HEIGHT / (rows - 1)
    vertices = []

    for r in range(rows):
        for c in range(cols):
            base_x = c * x_step
            base_y = r * y_step
            if 0 < c < cols - 1 and 0 < r < rows - 1:
                jitter_x = (random.random() - 0.5) * (x_step * 0.4)
                jitter_y = (random.random() - 0.5) * (y_step * 0.4)
            else:
                jitter_x = 0; jitter_y = 0
            vertices.append((base_x + jitter_x, base_y + jitter_y))

    def get_v(r, c):
        return vertices[r * cols + c]

    svg_lines.append(f'    <g stroke="{cfg["grid_main"]}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none">')
    for r in range(rows - 1):
        for c in range(cols - 1):
            v1 = get_v(r, c); v2 = get_v(r, c + 1); v3 = get_v(r + 1, c + 1); v4 = get_v(r + 1, c)
            svg_lines.append(f'      <polygon points="{v1[0]:.1f},{v1[1]:.1f} {v2[0]:.1f},{v2[1]:.1f} {v3[0]:.1f},{v3[1]:.1f}" />')
            svg_lines.append(f'      <polygon points="{v1[0]:.1f},{v1[1]:.1f} {v3[0]:.1f},{v3[1]:.1f} {v4[0]:.1f},{v4[1]:.1f}" />')
    svg_lines.append('    </g>')

    svg_lines.append(f'    <g fill="{cfg["grid_main"]}" opacity="0.9">')
    for (x, y) in vertices:
        svg_lines.append(f'      <circle cx="{x:.1f}" cy="{y:.1f}" r="2.5" />')
    svg_lines.append('    </g>')
    svg_lines.append('  </g>')

    svg_lines.append(f'  <g id="circuit-traces" stroke="{cfg["grid_sub"]}" stroke-width="1.5" stroke-linecap="round" fill="none">')
    trace_paths = []
    for _ in range(80):
        start_r = random.randint(0, rows - 1); start_c = random.randint(0, cols - 1)
        curr_r = start_r; curr_c = start_c
        path = [get_v(curr_r, curr_c)]
        for _ in range(random.randint(2, 6)):
            dr = random.choice([-1, 0, 1]); dc = random.choice([-1, 0, 1])
            if dr == 0 and dc == 0: continue
            next_r = max(0, min(rows - 1, curr_r + dr)); next_c = max(0, min(cols - 1, curr_c + dc))
            if next_r == curr_r and next_c == curr_c: continue
            curr_r = next_r; curr_c = next_c
            path.append(get_v(curr_r, curr_c))
        if len(path) >= 2:
            trace_paths.append(path)
            d = f"M {path[0][0]:.1f},{path[0][1]:.1f} " + " ".join([f"L {p[0]:.1f},{p[1]:.1f}" for p in path[1:]])
            svg_lines.append(f'    <path d="{d}" />')
    svg_lines.append('  </g>')

    svg_lines.append(f'  <g id="glow-lines" stroke="{cfg["line_color"]}" stroke-width="2.2" stroke-linecap="round" fill="none" filter="url(#glow-line)" opacity="0.95">')
    accent_endpoints = []
    for _ in range(35):
        if not trace_paths: break
        base = random.choice(trace_paths)
        if len(base) >= 3:
            idx = random.randint(0, len(base) - 3)
            sub = base[idx:idx + random.randint(2, min(5, len(base) - idx))]
            d = f"M {sub[0][0]:.1f},{sub[0][1]:.1f} " + " ".join([f"L {p[0]:.1f},{p[1]:.1f}" for p in sub[1:]])
            svg_lines.append(f'    <path d="{d}" />')
            accent_endpoints.extend(sub)
    svg_lines.append('  </g>')

    svg_lines.append(f'  <g id="glow-nodes" fill="{cfg["node_color"]}" filter="url(#glow-node)" opacity="0.95">')
    candidates = list(set(accent_endpoints) | set(random.sample(vertices, min(60, len(vertices)))))
    selected = random.sample(candidates, min(45, len(candidates)))
    for (nx, ny) in selected:
        svg_lines.append(f'    <circle cx="{nx:.1f}" cy="{ny:.1f}" r="{round(random.uniform(2.5, 4.0), 1)}" />')
    svg_lines.append('  </g>')
    svg_lines.append('</svg>')

    with open(svg_path, "w", encoding="utf-8") as f:
        f.write("\n".join(svg_lines) + "\n")

    print(f"[+] Compiled SVG: {svg_path} -> Converting to PNG...")
    res = subprocess.run(["rsvg-convert", "-w", str(WIDTH), "-h", str(HEIGHT), "-f", "png", "-o", png_path, svg_path], capture_output=True)
    if res.returncode == 0:
        print(f"[✓] Successfully built 4K Wallpaper: {png_path}")
    else:
        print(f"[!] Warning: rsvg-convert failed for {png_path}")

if __name__ == "__main__":
    out_directory = os.path.dirname(os.path.abspath(__file__))
    for theme_name, theme_cfg in THEMES.items():
        generate_theme(theme_name, theme_cfg, out_directory)
