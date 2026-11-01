#!/usr/bin/env python3
"""Draw a device's plate spec (hole coordinates, caps, device, margins, slots) from the
`Spec = [...]` line that assembly.scad echoes. Seen from the device face, row 0 at the
bottom, as in the hole map and slot indices.

    spec.py <assembly.echo> <out.png|out.svg> <title>

.svg is written directly; .png goes through rsvg-convert or inkscape. Without either
(or if it fails) it writes the .svg next to it and warns instead of failing.
"""
import json, os, shutil, subprocess, sys, tempfile


def load(path):
    for line in open(path):
        if line.startswith('ECHO: Spec = '):
            return dict(json.loads(line[len('ECHO: Spec = '):]))
    sys.exit(f'{path}: no "Spec =" echo (assembly.scad failed? see the ERROR lines in it)')


def svg(d, title):
    cx, cy = d['cells']
    cell, gap, r = d['cell'], d['edge_gap'], d['slot_r']
    ma, mb, ml, mr = d['margins']
    W, H = cx*cell, cy*cell
    S = min(3.2, 640 / W, 560 / H)       # px per mm
    L, T, R, B = 120, 110, 150, 175      # page margins, px
    R = max(R, 780 - L - W*S)            # room for the legend on small plates
    pw, ph = L + W*S + R, T + H*S + B
    hole = lambda i: cell/4 + i*cell/2
    px = lambda x: L + x*S
    py = lambda y: T + (H - y)*S         # y up
    o = []
    a = o.append
    a(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {pw:.0f} {ph:.0f}" width="{pw:.0f}" height="{ph:.0f}" '
      'font-family="Helvetica, Arial, sans-serif" font-size="13">')
    a('<defs><marker id="ar" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">'
      '<path d="M0,0 L10,5 L0,10 z" fill="#333"/></marker>'
      '<pattern id="hatch" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">'
      '<line x1="0" y1="0" x2="0" y2="8" stroke="#c9a227" stroke-width="2"/></pattern>'
      f'<clipPath id="plate"><rect x="{px(gap):.1f}" y="{py(H-gap):.1f}" width="{(W-2*gap)*S:.1f}" height="{(H-2*gap)*S:.1f}"/></clipPath></defs>')
    a('<rect width="100%" height="100%" fill="#fff"/>')
    a(f'<text x="{pw/2:.0f}" y="28" text-anchor="middle" font-size="17" font-weight="bold">Plate coordinates, seen from the device face</text>')
    a(f'<text x="{pw/2:.0f}" y="50" text-anchor="middle" fill="#555">{title} · {cx} × {cy} cells</text>')
    # plate, margin cells, cell grid
    a(f'<rect x="{px(gap):.1f}" y="{py(H-gap):.1f}" width="{(W-2*gap)*S:.1f}" height="{(H-2*gap)*S:.1f}" fill="#e9ecef" stroke="#6c757d" stroke-width="1.5"/>')
    for x0, y0, x1, y1 in ((0, 0, W, cell*ma), (0, H - cell*mb, W, H), (0, 0, cell*ml, H), (W - cell*mr, 0, W, H)):
        if x1 > x0 and y1 > y0:
            a(f'<rect x="{px(x0):.1f}" y="{py(y1):.1f}" width="{(x1-x0)*S:.1f}" height="{(y1-y0)*S:.1f}" fill="url(#hatch)" opacity="0.35" clip-path="url(#plate)"/>')
    for i in range(1, cx): a(f'<line x1="{px(i*cell):.1f}" y1="{py(H):.1f}" x2="{px(i*cell):.1f}" y2="{py(0):.1f}" stroke="#adb5bd" stroke-dasharray="4 4"/>')
    for j in range(1, cy): a(f'<line x1="{px(0):.1f}" y1="{py(j*cell):.1f}" x2="{px(W):.1f}" y2="{py(j*cell):.1f}" stroke="#adb5bd" stroke-dasharray="4 4"/>')
    sw = d['snap_w']
    for sx, sy in d['snaps']:
        a(f'<rect x="{px(sx-sw/2):.1f}" y="{py(sy+sw/2):.1f}" width="{sw*S:.1f}" height="{sw*S:.1f}" fill="#d0ebff" stroke="#4dabf7" rx="6"/>')
    # caps, device
    for k, (x0, y0, x1, y1) in enumerate(d['caps']):
        a(f'<rect x="{px(x0):.1f}" y="{py(y1):.1f}" width="{(x1-x0)*S:.1f}" height="{(y1-y0)*S:.1f}" fill="#4682b4" fill-opacity="0.55" stroke="#2f5f8a"/>')
    dx, dy, dw, dh = d['device']
    a(f'<rect x="{px(dx):.1f}" y="{py(dy+dh):.1f}" width="{dw*S:.1f}" height="{dh*S:.1f}" fill="#ffa94d" fill-opacity="0.45" stroke="#e8590c" stroke-dasharray="6 3"/>')
    a(f'<text x="{px(dx+dw/2):.1f}" y="{py(dy+dh/2)+5:.1f}" text-anchor="middle" font-size="15" fill="#a34700">device {dw:g} × {dh:g}</text>')
    for (x0, y0, x1, y1), name in zip(d['caps'], ('cap A', 'cap B')):
        a(f'<text x="{px(dx+dw/2):.1f}" y="{py((y0+y1)/2)+5:.1f}" text-anchor="middle" fill="#fff" font-weight="bold">{name}</text>')
    # holes, then slots over them (the slot removes them), clipped to the plate edge
    screws = {(round(x, 3), round(y, 3)) for x, y in d['screws']}
    for i in range(2*cx):
        for j in range(2*cy):
            sc = (round(hole(i), 3), round(hole(j), 3)) in screws
            a(f'<circle cx="{px(hole(i)):.1f}" cy="{py(hole(j)):.1f}" r="{3.2 if sc else 2}" fill="{"#c92a2a" if sc else "#fff"}" '
              f'stroke="#495057" stroke-width="{1.5 if sc else 0.8}"/>')
    for k, s, segs in d['slots']:
        for (x1, y1), (x2, y2) in segs:
            a(f'<line x1="{px(x1):.1f}" y1="{py(y1):.1f}" x2="{px(x2):.1f}" y2="{py(y2):.1f}" stroke="#495057" '
              f'stroke-width="{2*r*S:.1f}" stroke-linecap="round" clip-path="url(#plate)"/>')
        (x1, y1), (x2, y2) = segs[0]
        label = f'slot{k} = [{", ".join(str(v) for v in s)}]'
        if abs(x2 - x1) * S < 7.5 * len(label): label = f'slot{k}'
        a(f'<text x="{px((x1+x2)/2):.1f}" y="{py((y1+y2)/2)+5:.1f}" text-anchor="middle" fill="#fff" font-weight="bold">{label}</text>')
    # indices: columns below, rows left; grey -1 / 2*cells = exit through that edge
    yb = py(0) + 42
    for i in range(-1, 2*cx + 1):
        a(f'<text x="{px(hole(i)):.1f}" y="{yb:.1f}" text-anchor="middle" fill="{"#adb5bd" if i in (-1, 2*cx) else "#212529"}">{i}</text>')
    for j in range(-1, 2*cy + 1):
        a(f'<text x="{px(0)-14:.1f}" y="{py(hole(j))+4:.1f}" text-anchor="end" fill="{"#adb5bd" if j in (-1, 2*cy) else "#212529"}">{j}</text>')
    a(f'<text x="{px(W/2):.1f}" y="{yb+48:.1f}" text-anchor="middle" fill="#555">x = hole column (14 mm pitch) · grey −1 / 2×cells = slot exits through that edge</text>')
    a(f'<text transform="translate({px(0)-58:.1f},{py(H/2):.1f}) rotate(-90)" text-anchor="middle" fill="#555">y = hole row</text>')
    a(f'<line x1="{px(hole(0)):.1f}" y1="{yb+16:.1f}" x2="{px(hole(0))+70:.1f}" y2="{yb+16:.1f}" stroke="#333" stroke-width="1.5" marker-end="url(#ar)"/>')
    a(f'<line x1="{px(0)-40:.1f}" y1="{py(hole(0)):.1f}" x2="{px(0)-40:.1f}" y2="{py(hole(0))-70:.1f}" stroke="#333" stroke-width="1.5" marker-end="url(#ar)"/>')
    cells = lambda m: f' (+{m} cell{"s" if m > 1 else ""})' if m else ''
    a(f'<text x="{px(W/2):.1f}" y="{py(H)-14:.1f}" text-anchor="middle" font-weight="bold">B end · margin_b = {mb}{cells(mb)}</text>')
    a(f'<text x="{px(W/2):.1f}" y="{yb+74:.1f}" text-anchor="middle" font-weight="bold">A end · margin_a = {ma}{cells(ma)}</text>')
    a(f'<text transform="translate({px(0)-85:.1f},{py(H/2):.1f}) rotate(-90)" text-anchor="middle" font-weight="bold">left · margin_l = {ml}{cells(ml)}</text>')
    a(f'<text transform="translate({px(W)+28:.1f},{py(H/2):.1f}) rotate(90)" text-anchor="middle" font-weight="bold">right · margin_r = {mr}{cells(mr)}</text>')
    lx, ly = L, ph - 22
    for col, txt in (('#c92a2a', 'cap screw hole'), ('#4682b4', 'cap footprint'), ('#ffa94d', 'device'),
                     ('#d0ebff', 'corner snap'), ('#495057', 'wire slot')):
        a(f'<rect x="{lx}" y="{ly-11}" width="14" height="14" fill="{col}" stroke="#495057" stroke-width="0.5"/><text x="{lx+20}" y="{ly}">{txt}</text>')
        lx += 30 + 7.5*len(txt)
    a('</svg>')
    return '\n'.join(o)


def main():
    if len(sys.argv) != 4: sys.exit(__doc__)
    src, out, title = sys.argv[1:]
    text = svg(load(src), title)
    if out.endswith('.svg'):
        open(out, 'w').write(text)
        return
    with tempfile.TemporaryDirectory() as tmp:
        f = os.path.join(tmp, 'spec.svg')
        open(f, 'w').write(text)
        if shutil.which('rsvg-convert'): cmd = ['rsvg-convert', '-o', out, f]
        elif shutil.which('inkscape'): cmd = ['inkscape', f, '--export-type=png', f'--export-filename={out}']
        else: cmd = None
        if cmd and subprocess.run(cmd, stderr=subprocess.DEVNULL).returncode == 0 and os.path.exists(out):
            return
    # No converter (or it failed): keep the drawing as SVG next to the PNG, don't fail the build.
    alt = os.path.splitext(out)[0] + '.svg'
    open(alt, 'w').write(text)
    print(f'spec.py: {"PNG conversion failed" if cmd else "no rsvg-convert or inkscape"}; wrote {alt} instead', file=sys.stderr)


if __name__ == '__main__':
    main()
