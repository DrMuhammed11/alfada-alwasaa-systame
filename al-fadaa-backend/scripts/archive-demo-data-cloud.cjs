// أرشفة كل الرسائل التجريبية على الخادم السحابي — عبر API رسمي (GM)
const BASE = process.env.CLOUD_API || 'https://alfada-alwasaa-systame.onrender.com/api/v1';

async function api(path, opts = {}, token) {
  const res = await fetch(`${BASE}${path}`, {
    ...opts,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(opts.headers || {}),
    },
  });
  const text = await res.text();
  let body;
  try { body = JSON.parse(text); } catch { body = text; }
  return { status: res.status, body };
}

(async () => {
  const login = await api('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email: 'gm@al-fadaa.com', password: 'Alfadaa@2026' }),
  });
  if (login.status !== 200 && login.status !== 201) {
    console.error('فشل الدخول:', login.status);
    process.exit(1);
  }
  const token = login.body.accessToken;
  console.log('✓ دخول GM على الخادم السحابي');

  // نجلب كل المراسلات النشطة (حد أعلى 100) ونؤرشف كل ما هو تجريبي:
  // مرسلو الاختبار test@/test-audit@ وبيانات البذرة القديمة (5 خانات)
  const res = await api('/correspondences?limit=100', {}, token);
  const items = (res.body && res.body.data) || [];
  const demo = items.filter(
    (c) =>
      ['test@alfadaalwasaa.com', 'test-audit@alfadaalwasaa.com'].includes(
        (c.senderEmail || '').toLowerCase(),
      ) ||
      /^(INC|OUT|INT)-\d{4}-\d{5}$/.test(c.refNumber || ''), // صيغة البذرة القديمة 5 خانات
  );
  console.log(`المرشحة للأرشفة: ${demo.length} من ${items.length}`);
  for (const c of demo) {
    const arch = await api(`/correspondences/${c.id}/archive`, {
      method: 'POST',
      body: JSON.stringify({ reason: 'بيانات تجريبية — إخراج من العرض الفعلي' }),
    }, token);
    console.log(
      `${arch.status === 201 ? '✓ أُرشفت' : '✗ ' + arch.status}: ${c.refNumber} — ${(c.subject || '').slice(0, 30)}`,
    );
  }
})().catch((e) => { console.error('ERR:', e.message); process.exit(1); });
