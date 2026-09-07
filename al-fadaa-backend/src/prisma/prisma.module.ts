import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

/** وحدة عامة (Global) — PrismaService متاح للحقن في أي مكان دون استيراد */
@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
