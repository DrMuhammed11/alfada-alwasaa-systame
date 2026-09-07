import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { TasksService } from './tasks.service';
import {
  CreateTaskDto,
  TasksQueryDto,
  UpdateTaskDto,
  UpdateTaskStatusDto,
} from './dto';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/types';
import { Permission } from '../security/permissions';

@ApiTags('التكليفات')
@ApiBearerAuth()
@Controller()
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  @Post('correspondences/:correspondenceId/tasks')
  @RequirePermission(Permission.TASK_ASSIGN)
  @ApiOperation({ summary: 'إنشاء تكليف على مراسلة (مدير القسم يكلّف موظفي قسمه فقط)' })
  create(
    @Param('correspondenceId', ParseUUIDPipe) correspondenceId: string,
    @Body() dto: CreateTaskDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.tasksService.create(correspondenceId, dto, user);
  }

  @Get('tasks/my')
  @ApiOperation({ summary: 'مهامي — التكليفات المعينة إليّ' })
  mine(@Query() dto: TasksQueryDto, @CurrentUser() user: AuthUser) {
    return this.tasksService.findMine(dto, user);
  }

  @Get('tasks')
  @ApiOperation({ summary: 'كل التكليفات (الإدارة العليا ومديرو الأقسام — بنطاق القسم)' })
  findAll(@Query() dto: TasksQueryDto, @CurrentUser() user: AuthUser) {
    return this.tasksService.findAll(dto, user);
  }

  @Patch('tasks/:id')
  @ApiOperation({ summary: 'تعديل بيانات تكليف (منشئه فقط)' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateTaskDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.tasksService.update(id, dto, user);
  }

  @Patch('tasks/:id/status')
  @ApiOperation({
    summary: 'تغيير حالة التكليف: بدء التنفيذ (المكلَّف) أو الإلغاء (المنشئ)',
  })
  updateStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateTaskStatusDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.tasksService.updateStatus(id, dto, user);
  }
}
