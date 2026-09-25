import { registerDecorator, ValidationOptions, ValidationArguments } from 'class-validator';

/**
 * سياسة كلمة المرور المركزية:
 * - 10 خانات فأكثر
 * - حرف لاتيني كبير + صغير + رقم + رمز خاص
 * تُطبَّق على إنشاء المستخدمين وتحديثهم وتغيير كلمة المرور الذاتي.
 */
export function validateStrongPassword(value: unknown): boolean {
  if (typeof value !== 'string') return false;
  return (
    value.length >= 10 &&
    /[A-Z]/.test(value) &&
    /[a-z]/.test(value) &&
    /[0-9]/.test(value) &&
    /[^A-Za-z0-9]/.test(value)
  );
}

export const STRONG_PASSWORD_MESSAGE =
  'كلمة المرور ضعيفة — يلزم 10 خانات فأكثر مع حرف كبير وصغير ورقم ورمز خاص';

export function IsStrongPassword(validationOptions?: ValidationOptions) {
  return function (object: object, propertyName: string) {
    registerDecorator({
      name: 'isStrongPassword',
      target: object.constructor,
      propertyName,
      options: validationOptions,
      validator: {
        validate(value: unknown, _args: ValidationArguments) {
          return validateStrongPassword(value);
        },
        defaultMessage: () => STRONG_PASSWORD_MESSAGE,
      },
    });
  };
}
