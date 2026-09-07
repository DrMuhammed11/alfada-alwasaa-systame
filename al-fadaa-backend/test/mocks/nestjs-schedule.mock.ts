export const Cron = (_cronTime?: any, _options?: any): MethodDecorator => {
  return (_target: any, _propertyKey: string | symbol, descriptor: PropertyDescriptor) => {
    return descriptor;
  };
};

export const CronExpression = {
  EVERY_SECOND: '* * * * * *',
  EVERY_5_SECONDS: '*/5 * * * * *',
  EVERY_10_SECONDS: '*/10 * * * * *',
  EVERY_30_SECONDS: '*/30 * * * * *',
  EVERY_MINUTE: '* * * * *',
  EVERY_5_MINUTES: '*/5 * * * *',
  EVERY_10_MINUTES: '*/10 * * * *',
  EVERY_HOUR: '0 * * * *',
  EVERY_DAY_AT_MIDNIGHT: '0 0 * * *',
};

export class ScheduleModule {
  static forRoot() {
    return {
      module: ScheduleModule,
      providers: [],
      exports: [],
    };
  }
}
