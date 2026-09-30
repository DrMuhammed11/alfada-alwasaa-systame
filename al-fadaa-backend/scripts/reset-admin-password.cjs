// إعادة ضبط كلمة مرور admin@al-fadaa.com المحلية لتوافق بقية الحسابات
// (كلمة المرور الأصلية وُلّدت عشوائيًا عند زرع القاعدة ولم تُحفظ)
require('dotenv').config();
const { Client } = require('pg');
const bcrypt = require('bcrypt');

(async () => {
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  await c.connect();
  const hash = bcrypt.hashSync('Alfadaa@2026', 10);
  await c.query(
    'UPDATE "User" SET "passwordHash" = $1, "failedLoginAttempts" = 0, "lockedUntil" = NULL WHERE email = $2',
    [hash, 'admin@al-fadaa.com'],
  );
  const check = await c.query('SELECT "passwordHash" FROM "User" WHERE email = $1', ['admin@al-fadaa.com']);
  const ok = await bcrypt.compare('Alfadaa@2026', check.rows[0].passwordHash);
  console.log('إعادة الضبط:', ok ? 'نجحت ✓' : 'فشلت ✗');
  await c.end();
})().catch((e) => {
  console.error('ERR:', e.message);
  process.exit(1);
});
