/**
 * تنظيف موضوع الرسالة من البادئات وأرقام المراجع لمطابقة محادثات البريد
 */
export function normalizeSubject(subject: string): string {
  let s = (subject || '').trim();
  s = s.replace(/\[?(?:INC|OUT|INT)-\d{4}-\d{5,6}\]?/gi, '').trim();
  const prefixRegex = /^(re|fwd|fw|رد|اعادة|إعادة)\s*[:：\-]\s*/i;
  while (prefixRegex.test(s)) {
    s = s.replace(prefixRegex, '').trim();
  }
  return s.trim();
}

/**
 * تجريد وسوم HTML والإبقاء على النص المرئي فقط
 */
export function stripHtml(html: string): string {
  return html
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<\/p>/gi, '\n\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>')
    .replace(/&quot;/gi, '"')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

/**
 * استخراج معرفات الرسائل من ترويسات In-Reply-To و References
 */
export function parseHeaderIds(val: unknown, candidateIds: string[]): void {
  if (!val) return;
  const str = Array.isArray(val) ? val.join(' ') : String(val);
  const matches = str.match(/<[^>]+>|[^\s,]+/g) || [];
  for (const m of matches) {
    const t = m.trim();
    if (t) {
      candidateIds.push(t);
      if (t.startsWith('<') && t.endsWith('>')) {
        candidateIds.push(t.slice(1, -1));
      } else {
        candidateIds.push(`<${t}>`);
      }
    }
  }
}
