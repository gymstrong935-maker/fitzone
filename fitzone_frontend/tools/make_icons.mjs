// Genera los PNG del ícono a partir de los SVG.
// Uso (desde la raíz del proyecto Flutter):  node tools/make_icons.mjs
import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';

const root = process.cwd();
const abs = (p) => path.join(root, p);
const out = (p) => {
  fs.mkdirSync(path.dirname(abs(p)), { recursive: true });
  return abs(p);
};

const svg = fs.readFileSync(abs('assets/icon/app_icon.svg'));
const svgFront = fs.readFileSync(abs('assets/icon/app_icon_foreground.svg'));

const png = (buf, size, file) =>
  sharp(buf, { density: 384 }).resize(size, size).png().toFile(out(file));

// Base para Android / iOS / Windows (lo usa flutter_launcher_icons)
await png(svg, 1024, 'assets/icon/app_icon.png');
await png(svgFront, 1024, 'assets/icon/app_icon_foreground.png');

// Web
await png(svg, 32, 'web/favicon.png');
await png(svg, 192, 'web/icons/Icon-192.png');
await png(svg, 512, 'web/icons/Icon-512.png');

// Íconos "maskable" (fondo sólido + logo dentro de la zona segura)
for (const size of [192, 512]) {
  const bg = await sharp({
    create: { width: size, height: size, channels: 4, background: '#0a0a0a' },
  })
    .png()
    .toBuffer();
  const front = await sharp(svgFront, { density: 384 })
    .resize(size, size)
    .png()
    .toBuffer();
  await sharp(bg)
    .composite([{ input: front }])
    .png()
    .toFile(out(`web/icons/Icon-maskable-${size}.png`));
}

console.log('✅ Íconos generados');