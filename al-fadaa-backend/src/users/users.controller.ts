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
import { UsersService } from './users.service';
import { CreateUserDto, UpdateUserDto, UsersQueryDto } from './dto';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { Permission } from '../security/permissions';

@ApiTags('المستخدمون')
@ApiBearerAuth()
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  @RequirePermission(Permission.USERS_MANAGE)
  @ApiOperation({ summary: 'قائمة المستخدمين (مسؤول النظام) — تصفية وتقسيم صفحات' })
  findAll(@Query() dto: UsersQueryDto) {
    return this.usersService.findAll(dto);
  }

  @Get(':id')
  @RequirePermission(Permission.USERS_MANAGE)
  @ApiOperation({ summary: 'تفاصيل مستخدم' })
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.usersService.findOne(id);
  }

  @Post()
  @RequirePermission(Permission.USERS_MANAGE)
  @ApiOperation({ summary: 'إنشاء حساب مستخدم جديد (المسؤول فقط)' })
  create(@Body() dto: CreateUserDto) {
    return this.usersService.create(dto);
  }

  @Patch(':id')
  @RequirePermission(Permission.USERS_MANAGE)
  @ApiOperation({ summary: 'تعديل حساب (الاسم / الدور / القسم / كلمة المرور ...)' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateUserDto,
  ) {
    return this.usersService.update(id, dto);
  }

  @Delete(':id')
  @RequirePermission(Permission.USERS_MANAGE)
  @ApiOperation({
    summary: 'تعطيل الحساب (بدل الحذف النهائي — للحفاظ على سلامة السجلات)',
  })
  deactivate(@Param('id', ParseUUIDPipe) id: string) {
    return this.usersService.deactivate(id);
  }
}
