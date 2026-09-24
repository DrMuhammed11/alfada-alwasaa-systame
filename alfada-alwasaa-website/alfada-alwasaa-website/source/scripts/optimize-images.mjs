import sharp from "sharp";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, "..");
const profileDir = path.join(rootDir, "public", "profile");

const imagesToOptimize = [
  { name: "hero_bg.webp", targetWidth: 1600, quality: 80 },
  { name: "road_roller.webp", targetWidth: 900, quality: 80 },
  { name: "site_solar_array.webp", targetWidth: 900, quality: 80 },
  { name: "oil_tanks_truck.webp", targetWidth: 900, quality: 80 },
];

function formatBytes(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  return `${(bytes / 1024).toFixed(1)} KB`;
}

async function optimize() {
  console.log("Starting image optimization...\n");
  console.log("| الصورة (Image) | الحجم قبل | الحجم بعد | نسبة التوفير | العرض الجديد |");
  console.log("|---|---|---|---|---|");

  // Remove any leftover temp file if exists
  const tempFiles = fs.readdirSync(profileDir).filter(f => f.startsWith("_temp_"));
  for (const tf of tempFiles) {
    try { fs.unlinkSync(path.join(profileDir, tf)); } catch {}
  }

  for (const img of imagesToOptimize) {
    const inputPath = path.join(profileDir, img.name);
    if (!fs.existsSync(inputPath)) {
      console.warn(`File not found: ${inputPath}`);
      continue;
    }

    // Read to buffer first to prevent Windows file locking
    const inputBuffer = fs.readFileSync(inputPath);
    const beforeSize = inputBuffer.length;

    // Re-encode with sharp
    const outputBuffer = await sharp(inputBuffer)
      .resize({ width: img.targetWidth, withoutEnlargement: true })
      .webp({ quality: img.quality, effort: 6 })
      .toBuffer();

    const afterSize = outputBuffer.length;
    fs.writeFileSync(inputPath, outputBuffer);

    const diffPercent = (((beforeSize - afterSize) / beforeSize) * 100).toFixed(1);
    console.log(
      `| \`${img.name}\` | ${formatBytes(beforeSize)} (${beforeSize.toLocaleString()} B) | ${formatBytes(afterSize)} (${afterSize.toLocaleString()} B) | **-${diffPercent}%** | ${img.targetWidth}px |`
    );
  }

  console.log("\nImage optimization complete!");
}

optimize().catch((err) => {
  console.error("Optimization failed:", err);
  process.exit(1);
});
