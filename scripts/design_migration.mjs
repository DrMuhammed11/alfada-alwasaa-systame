#!/usr/bin/env node
/**
 * سكربت ترحيل التصميم الميكانيكي — يستبدل القيم المكتوبة يدويًا بتوكنات الثيم:
 *   1) Color(0xFF...) → AppTheme./AdminTheme.token
 *   2) fontSize: N → مقياس الخطوط الموحد
 *   3) BorderRadius.circular(N) → مقياس الأشعة الموحد
 * ويضيف استيراد الثيم تلقائيًا للملفات التي أصبحت تستهلكه.
 * الاستخدام: node design_migration.mjs <appRoot> <themeClass> <themeFile>
 */
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, relative, dirname } from 'node:path';

const [appRoot, themeClass, themeFile] = process.argv.slice(2);
if (!appRoot || !themeClass || !themeFile) {
  console.error('Usage: node design_migration.mjs <appRoot> <ThemeClass> <lib/core/theme/file.dart>');
  process.exit(1);
}

// ── خرائط الاستبدال (نفس القيم للمراسلات والأدمن مع أسماء توكنات مختلفة) ──
const isFrontend = themeClass === 'AppTheme';

const hexMap = isFrontend ? {
  '64748B': 'textTertiary',
  '94A3B8': 'textTertiary', // إصلاح تباين فاشل
  'E2E8F0': 'borderLight',
  'DC2626': 'crimson',
  '0F172A': 'primary',
  'F8FAFC': 'backgroundLight',
  '059669': 'emerald',
  '10B981': 'emerald',
  '16A34A': 'emerald',
  '0284C7': 'info',
  '2563EB': 'info',
  '3B82F6': 'info',
  '475569': 'textMuted',
  '1E293B': 'textHeading',
  '334155': 'secondary',
  '020617': 'textDark',
  'FEF2F2': 'surfaceDanger',
  'FECACA': 'borderDanger',
  'ECFDF5': 'surfaceSuccess',
} : {
  '475569': 'textMuted',
  '94A3B8': 'textLight',
  'E2E8F0': 'border',
  '1E293B': 'textHeading',
  '334155': 'borderDark',
  'FECACA': 'borderDanger',
  'A7F3D0': 'borderSuccess',
  'F8FAFC': 'bgLight',
  '8B5CF6': 'purple',
  '0F172A': 'primary',
  'CBD5E1': 'textLight',
  '0284C7': 'accent',
  'ECFDF5': 'surfaceSuccess',
  'FEF2F2': 'surfaceDanger',
  'F1F5F9': 'surface2',
  '10B981': 'emerald',
  '059669': 'emerald',
  'F59E0B': 'amber',
  'EF4444': 'crimson',
  'EFF6FF': 'surfaceInfo',
  'BFDBFE': 'borderInfo',
  '64748B': 'textMuted',
  '1E40AF': 'accent',
  '0369A1': 'accent',
  'EAB308': 'amber',
};

// fontSize: N → توكن (القيم تحت الحد الأدنى تُرفع)
const fontMap = isFrontend ? {
  8.5: 'fontXs', 9: 'fontXs', 9.5: 'fontXs', 10: 'fontXs', 10.5: 'fontXs', 11: 'fontXs',
  11.5: 'fontSm', 12: 'fontSm', 12.5: 'fontBase', 13: 'fontBase', 13.5: 'fontMd', 14: 'fontMd',
  15: 'fontLg', 16: 'fontLg', 18: 'fontXl', 20: 'fontXxl', 22: 'fontXxl', 28: 'fontDisplay',
} : {
  7: 'fontXs', 8: 'fontXs', 9: 'fontXs', 9.5: 'fontXs', 10: 'fontXs',
  10.5: 'fontSm', 11: 'fontSm', 11.5: 'fontBase', 12: 'fontBase', 12.5: 'fontMd', 13: 'fontMd',
  13.5: 'fontLg', 14: 'fontLg', 15: 'fontTitle', 16: 'fontTitle', 17: 'fontTitle',
  18: 'fontXl', 20: 'fontXxl', 22: 'fontXxl', 24: 'fontDisplay', 26: 'fontDisplay',
};

const radiusMap = isFrontend ? {
  2: 'radiusXs', 3: 'radiusXs', 4: 'radiusXs', 6: 'radiusSm', 8: 'radiusMd',
  10: 'radiusLg', 12: 'radiusLg', 16: 'radiusXl',
} : {
  2: 'radiusXs', 3: 'radiusXs', 4: 'radiusXs', 6: 'radiusSm', 8: 'radiusMd',
  10: 'radiusMd', 12: 'radiusLg', 14: 'radiusLg', 20: 'radiusXl',
};

const themeFileAbs = join(appRoot, themeFile);
const stats = { files: 0, changed: 0, hex: 0, font: 0, radius: 0, importsAdded: 0 };
const unmapped = {};

function walk(dir) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) { walk(full); continue; }
    if (!entry.name.endsWith('.dart')) continue;
    if (full === themeFileAbs) continue; // الثيم نفسه مستثنى
    stats.files++;
    let src = readFileSync(full, 'utf8');
    const before = src;

    // 1) hex → token — نبتعِد "const " السابقة لأن التوكنات ثوابت أصلًا
    src = src.replace(/const\s+Color\(0x(?:FF|ff)([0-9A-Fa-f]{6})\)/g, (m, hex) => {
      const token = hexMap[hex.toUpperCase()];
      if (token) { stats.hex++; return `${themeClass}.${token}`; }
      unmapped[hex.toUpperCase()] = (unmapped[hex.toUpperCase()] || 0) + 1;
      return m;
    });
    src = src.replace(/Color\(0x(?:FF|ff)([0-9A-Fa-f]{6})\)/g, (m, hex) => {
      const token = hexMap[hex.toUpperCase()];
      if (token) { stats.hex++; return `${themeClass}.${token}`; }
      unmapped[hex.toUpperCase()] = (unmapped[hex.toUpperCase()] || 0) + 1;
      return m;
    });

    // 2) fontSize → توكن (الأطول أولًا لتفادي 12.5/12)
    src = src.replace(/fontSize:\s*(\d+(?:\.\d+)?)(?=[,\s)])/g, (m, num) => {
      const token = fontMap[num];
      if (!token) return m;
      stats.font++;
      return `fontSize: ${themeClass}.${token}`;
    });

    // 3) BorderRadius.circular(N) → توكن (أعداد صحيحة فقط)
    src = src.replace(/BorderRadius\.circular\((\d+)\)/g, (m, num) => {
      const token = radiusMap[num];
      if (!token) return m;
      stats.radius++;
      return `BorderRadius.circular(${themeClass}.${token})`;
    });

    if (src === before) continue;
    // إضافة الاستيراد إن لزم — الحساب نسبي من مسار الملف
    const usesTheme = new RegExp(`\\b${themeClass}\\.`).test(src);
    const hasImport = new RegExp(`import\\s+['"].*${themeFile.split('/').pop()}['"]`).test(src);
    if (usesTheme && !hasImport) {
      const rel = relative(dirname(full), join(appRoot, themeFile)).replace(/\\/g, '/');
      const importLine = `import '${rel}';\n`;
      // أدرج بعد آخر import موجود
      const lines = src.split('\n');
      let lastImport = -1;
      for (let i = 0; i < lines.length; i++) {
        if (/^\s*import\s/.test(lines[i])) lastImport = i;
      }
      lines.splice(lastImport + 1, 0, importLine.trimEnd());
      src = lines.join('\n');
      stats.importsAdded++;
    }
    writeFileSync(full, src);
    stats.changed++;
  }
}

walk(join(appRoot, 'lib'));
console.log(`[design_migration] files scanned: ${stats.files}, changed: ${stats.changed}`);
console.log(`  hex→token: ${stats.hex}, fontSize→token: ${stats.font}, radius→token: ${stats.radius}, imports added: ${stats.importsAdded}`);
const leftovers = Object.entries(unmapped).sort((a, b) => b[1] - a[1]).slice(0, 20);
if (leftovers.length) {
  console.log('  قيم غير معوّنة (hex: count):');
  for (const [hex, count] of leftovers) console.log(`    ${hex}: ${count}`);
}
