// إتمام دورة حياة المراسلة التجريبية INC-2026-00002 على السحابة ثم أرشفتها:
// مهمة DONE ← رفع الرد ← اعتماد مدير القسم (+نائب المدير إن كانت HIGH) ← إرسال GM ← أرشفة
const BASE = process.env.CLOUD_API || 'https://alfada-alwasaa-systame.onrender.com/api/v1';
const PW = 'Alfadaa@2026';

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

async function login(email) {
  const r = await api('/auth/login', { method: 'POST', body: JSON.stringify({ email, password: PW }) });
  if (r.status !== 200 && r.status !== 201) throw new Error(`فشل دخول ${email}: ${r.status}`);
  console.log(`✓ دخول ${email}`);
  return r.body.accessToken;
}

(async () => {
  const gm = await login('gm@al-fadaa.com');
  const emp = await login('eng.employee1@al-fadaa.com');
  const mgr = await login('eng.manager@al-fadaa.com');
  let deputy;
  try { deputy = await login('deputy@al-fadaa.com'); } catch { deputy = null; }

  // 1) اعثر على المراسلة ومعرّفاتها
  const search = await api(`/correspondences?q=${encodeURIComponent('INC-2026-00002')}&limit=5`, {}, gm);
  const corr = (search.body.data || []).find((c) => c.refNumber === 'INC-2026-00002');
  if (!corr) { console.log('غير موجودة — ربما أُنجزت سابقًا'); return; }
  const detail = await api(`/correspondences/${corr.id}`, {}, gm);
  const d = detail.body;
  console.log(`المراسلة: ${corr.refNumber} | الحالة: ${d.status} | الأولوية: ${d.priority}`);

  // 2) إنجاز المهمة المعلقة
  for (const t of d.tasks || []) {
    if (t.status !== 'DONE') {
      const r = await api(`/tasks/${t.id}/status`, { method: 'PATCH', body: JSON.stringify({ status: 'DONE' }) }, emp);
      console.log(`مهمة ${t.id.slice(0, 8)}: ${r.status === 200 ? '✓ DONE' : '✗ ' + r.status + ' ' + JSON.stringify(r.body).slice(0, 120)}`);
    }
  }

  // 3) رفع الرد المسودة للاعتماد
  for (const rep of d.replies || []) {
    if (rep.status === 'DRAFT') {
      const r = await api(`/replies/${rep.id}/submit`, { method: 'POST', body: '{}' }, emp);
      console.log(`رفع الرد: ${r.status === 201 ? '✓ SUBMITTED' : r.status + ' ' + JSON.stringify(r.body).slice(0, 150)}`);
    }
  }

  // 4) الاعتماد عبر المستويات حتى APPROVED
  for (let round = 0; round < 3; round++) {
    const cur = await api(`/correspondences/${corr.id}`, {}, gm);
    const reply = (cur.body.replies || [])[0];
    if (!reply || reply.status !== 'SUBMITTED') { console.log('حالة الرد الآن:', reply && reply.status); break; }
    const level1 = await api(`/replies/${reply.id}/approve`, { method: 'POST', body: '{}' }, mgr);
    console.log(`اعتماد مدير القسم: ${level1.status === 201 ? '✓' : level1.status + ' ' + JSON.stringify(level1.body).slice(0, 150)}`);
    const check = await api(`/correspondences/${corr.id}`, {}, gm);
    const r2 = (check.body.replies || [])[0];
    if (r2 && r2.status === 'SUBMITTED' && deputy) {
      const level2 = await api(`/replies/${reply.id}/approve`, { method: 'POST', body: '{}' }, deputy);
      console.log(`اعتماد نائب المدير: ${level2.status === 201 ? '✓' : level2.status + ' ' + JSON.stringify(level2.body).slice(0, 150)}`);
    }
  }

  // 5) إرسال الرد من المدير العام
  const before = await api(`/correspondences/${corr.id}`, {}, gm);
  const replyFinal = (before.body.replies || [])[0];
  if (replyFinal && replyFinal.status === 'APPROVED') {
    const send = await api(`/replies/${replyFinal.id}/send`, { method: 'POST', body: '{}' }, gm);
    console.log(`الإرسال: ${send.status === 201 ? '✓ SENT' : send.status + ' ' + JSON.stringify(send.body).slice(0, 150)}`);
  }

  // 6) الأرشفة
  const arch = await api(`/correspondences/${corr.id}/archive`, { method: 'POST', body: JSON.stringify({ reason: 'بيانات تجريبية — إتمام الدورة ثم الأرشفة' }) }, gm);
  console.log(`الأرشفة: ${arch.status === 201 ? '✓ ARCHIVED' : arch.status + ' ' + JSON.stringify(arch.body).slice(0, 200)}`);
})().catch((e) => { console.error('ERR:', e.message); process.exit(1); });
