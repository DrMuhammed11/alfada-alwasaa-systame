import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { DepartmentsService } from './departments.service';
import { CreateDepartmentDto, DepartmentsQueryDto, UpdateDepartmentDto } from './dto';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { Permission } from '../security/permissions';

@ApiTags('الأقسام')
@ApiBearerAuth()
@Controller('departments')
export class DepartmentsController {
  constructor(private readonly departmentsService: DepartmentsService) {}

  @Get()
  @ApiOperation({ summary: 'قائمة الأقسام (متاح لكل الموظفين المسجلين)' })
  findAll(@Query() dto: DepartmentsQueryDto) {
    return this.departmentsService.findAll(dto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'تفاصيل قسم' })
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.departmentsService.findOne(id);
  }

  @Post()
  @RequirePermission(Permission.DEPARTMENTS_MANAGE)
  @ApiOperation({ summary: 'إنشاء قسم (مسؤول النظام فقط)' })
  create(@Body() dto: CreateDepartmentDto) {
    return this.departmentsService.create(dto);
  }

  @Patch(':id')
  @RequirePermission(Permission.DEPARTMENTS_MANAGE)
  @ApiOperation({ summary: 'تعديل قسم (الاسم / الرمز / المدير)' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateDepartmentDto,
  ) {
    return this.departmentsService.update(id, dto);
  }

  @Delete(':id')
  @RequirePermission(Permission.DEPARTMENTS_MANAGE)
  @ApiOperation({ summary: 'حذف قسم فارغ (بدون موظفين)' })
  remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.departmentsService.remove(id);
  }
}
