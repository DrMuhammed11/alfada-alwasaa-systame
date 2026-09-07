import { Module } from '@nestjs/common';
import { CorrespondencesModule } from '../correspondences/correspondences.module';
import { TasksController } from './tasks.controller';
import { TasksService } from './tasks.service';

@Module({
  imports: [CorrespondencesModule],
  controllers: [TasksController],
  providers: [TasksService],
})
export class TasksModule {}
