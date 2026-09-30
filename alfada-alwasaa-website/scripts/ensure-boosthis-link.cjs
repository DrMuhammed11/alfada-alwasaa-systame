/**
 * يضمن قابلية حل حزمة قياس الأداء Boosthis من node_modules.
 *
 * الحزمة تُشحن مصدر TypeScript مباشرة وتحمل اعتماديات تطويرية ببروتوكول
 * "catalog:" (pnpm/yarn) يرفضه npm، لذا يتعذّر إضافتها كاعتمادية file:.
 * الحل: وصلة junction من node_modules إلى النسخة المورّدة غير المعدَّلة
 * تحت lib/boosthis-runtime-web — تعمل على Windows بلا صلاحيات مدير.
 *
 * يعمل تلقائياً بعد كل npm install (سكربت postinstall).
 */
const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const target = path.join(root, "lib", "boosthis-runtime-web");
const linkParent = path.join(root, "node_modules", "@workspace");
const link = path.join(linkParent, "boosthis-runtime-web");

if (!fs.existsSync(target)) {
  console.error("[boosthis-link] missing vendored kit at lib/boosthis-runtime-web");
  process.exit(1);
}

try {
  const existing = fs.readlinkSync(link);
  if (existing === target) {
    process.exit(0);
  }
  // وصلة قديمة بمسار مختلف — تُستبدل
  fs.rmSync(link, { recursive: true, force: true });
} catch {
  // لا وصلة قائمة — تُنشأ الآن
}

fs.mkdirSync(linkParent, { recursive: true });
fs.symlinkSync(target, link, "junction");
console.log("[boosthis-link] linked @workspace/boosthis-runtime-web -> lib/boosthis-runtime-web");
