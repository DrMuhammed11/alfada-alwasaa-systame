import { randomBytes } from 'crypto';
import type { NextFunction, Request, Response } from 'express';

/**
 * وسيط توليد معرف طلب قصير فريد لكل طلب HTTP.
 * - يقبل رأس وارد `X-Request-Id` (من بوابة أو عميل) أو يولّد واحدًا جديدًا (8 حروف hex).
 * - يُعيد المعرف في رأس الاستجابة `X-Request-Id`.
 * - يُحقن في `req['requestId']` ليكون متاحًا في جميع الطبقات.
 */
export function requestIdMiddleware(req: Request, res: Response, next: NextFunction): void {
  const requestId =
    (req.headers['x-request-id'] as string | undefined)?.trim() ||
    randomBytes(4).toString('hex'); // 8 حروف hex

  (req as any).requestId = requestId;
  res.setHeader('X-Request-Id', requestId);
  next();
}
