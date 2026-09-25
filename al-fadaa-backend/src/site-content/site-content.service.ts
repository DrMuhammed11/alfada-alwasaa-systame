import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import type { AuthUser } from '../common/types';
import {
  CreateSiteFaqDto,
  CreateSiteProjectDto,
  CreateSiteSectorDto,
  CreateSiteServiceDto,
  UpdateSiteFaqDto,
  UpdateSiteProjectDto,
  UpdateSiteSectorDto,
  UpdateSiteServiceDto,
  UpsertSiteSettingDto,
} from './dto';

/**
 * إدارة محتويات الموقع الإلكتروني:
 * الخدمات، القطاعات، سابقة الأعمال، الأسئلة الشائعة، والإعدادات العامة.
 * القراءة العامة تعيد المفعّل فقط بالترتيب، والإدارة الكاملة بصلاحية CONTENT_MANAGE.
 */
@Injectable()
export class SiteContentService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  // ─── القراءة العامة (تُستهلك من الموقع الإلكتروني) ───

  getPublicServices() {
    return this.prisma.siteService.findMany({
      where: { isActive: true },
      orderBy: { order: 'asc' },
    });
  }

  getPublicSectors() {
    return this.prisma.siteSector.findMany({
      where: { isActive: true },
      orderBy: { order: 'asc' },
    });
  }

  getPublicProjects() {
    return this.prisma.siteProject.findMany({
      where: { isActive: true },
      orderBy: { order: 'asc' },
    });
  }

  getPublicFaqs() {
    return this.prisma.siteFaq.findMany({
      where: { isActive: true },
      orderBy: { order: 'asc' },
    });
  }

  async getPublicSetting(key: string) {
    const setting = await this.prisma.siteSetting.findUnique({ where: { key } });
    if (!setting) throw new NotFoundException(`إعداد الموقع «${key}» غير موجود`);
    return { key: setting.key, value: setting.value };
  }

  // ─── الإدارة الكاملة (لوحة الإدارة) ───

  getAllServices() {
    return this.prisma.siteService.findMany({ orderBy: [{ order: 'asc' }, { createdAt: 'desc' }] });
  }

  async createService(dto: CreateSiteServiceDto, user: AuthUser) {
    const item = await this.prisma.siteService.create({ data: dto });
    await this.audit.log({
      action: 'CREATE',
      entityType: 'SiteService',
      entityId: item.id,
      summary: `إضافة خدمة موقع جديدة: ${item.titleAr}`,
      metadata: { slug: item.slug },
      userId: user.id,
    });
    return item;
  }

  async updateService(id: string, dto: UpdateSiteServiceDto, user: AuthUser) {
    const item = await this.prisma.siteService.update({ where: { id }, data: dto });
    await this.audit.log({
      action: 'UPDATE',
      entityType: 'SiteService',
      entityId: id,
      summary: `تعديل خدمة الموقع: ${item.titleAr}`,
      userId: user.id,
    });
    return item;
  }

  async deleteService(id: string, user: AuthUser) {
    const item = await this.prisma.siteService.delete({ where: { id } });
    await this.audit.log({
      action: 'DELETE',
      entityType: 'SiteService',
      entityId: id,
      summary: `حذف خدمة الموقع: ${item.titleAr}`,
      userId: user.id,
    });
    return { deleted: true, id };
  }

  getAllSectors() {
    return this.prisma.siteSector.findMany({ orderBy: [{ order: 'asc' }, { createdAt: 'desc' }] });
  }

  async createSector(dto: CreateSiteSectorDto, user: AuthUser) {
    const item = await this.prisma.siteSector.create({ data: dto });
    await this.audit.log({
      action: 'CREATE',
      entityType: 'SiteSector',
      entityId: item.id,
      summary: `إضافة قطاع موقع جديد: ${item.titleAr}`,
      userId: user.id,
    });
    return item;
  }

  async updateSector(id: string, dto: UpdateSiteSectorDto, user: AuthUser) {
    const item = await this.prisma.siteSector.update({ where: { id }, data: dto });
    await this.audit.log({
      action: 'UPDATE',
      entityType: 'SiteSector',
      entityId: id,
      summary: `تعديل قطاع الموقع: ${item.titleAr}`,
      userId: user.id,
    });
    return item;
  }

  async deleteSector(id: string, user: AuthUser) {
    const item = await this.prisma.siteSector.delete({ where: { id } });
    await this.audit.log({
      action: 'DELETE',
      entityType: 'SiteSector',
      entityId: id,
      summary: `حذف قطاع الموقع: ${item.titleAr}`,
      userId: user.id,
    });
    return { deleted: true, id };
  }

  getAllProjects() {
    return this.prisma.siteProject.findMany({ orderBy: [{ order: 'asc' }, { createdAt: 'desc' }] });
  }

  async createProject(dto: CreateSiteProjectDto, user: AuthUser) {
    const item = await this.prisma.siteProject.create({ data: dto });
    await this.audit.log({
      action: 'CREATE',
      entityType: 'SiteProject',
      entityId: item.id,
      summary: `إضافة مشروع موقع جديد: ${item.titleAr}`,
      userId: user.id,
    });
    return item;
  }

  async updateProject(id: string, dto: UpdateSiteProjectDto, user: AuthUser) {
    const item = await this.prisma.siteProject.update({ where: { id }, data: dto });
    await this.audit.log({
      action: 'UPDATE',
      entityType: 'SiteProject',
      entityId: id,
      summary: `تعديل مشروع الموقع: ${item.titleAr}`,
      userId: user.id,
    });
    return item;
  }

  async deleteProject(id: string, user: AuthUser) {
    const item = await this.prisma.siteProject.delete({ where: { id } });
    await this.audit.log({
      action: 'DELETE',
      entityType: 'SiteProject',
      entityId: id,
      summary: `حذف مشروع الموقع: ${item.titleAr}`,
      userId: user.id,
    });
    return { deleted: true, id };
  }

  getAllFaqs() {
    return this.prisma.siteFaq.findMany({ orderBy: [{ order: 'asc' }, { createdAt: 'desc' }] });
  }

  async createFaq(dto: CreateSiteFaqDto, user: AuthUser) {
    const item = await this.prisma.siteFaq.create({ data: dto });
    await this.audit.log({
      action: 'CREATE',
      entityType: 'SiteFaq',
      entityId: item.id,
      summary: `إضافة سؤال شائع جديد: ${item.questionAr}`,
      userId: user.id,
    });
    return item;
  }

  async updateFaq(id: string, dto: UpdateSiteFaqDto, user: AuthUser) {
    const item = await this.prisma.siteFaq.update({ where: { id }, data: dto });
    await this.audit.log({
      action: 'UPDATE',
      entityType: 'SiteFaq',
      entityId: id,
      summary: `تعديل السؤال الشائع: ${item.questionAr}`,
      userId: user.id,
    });
    return item;
  }

  async deleteFaq(id: string, user: AuthUser) {
    const item = await this.prisma.siteFaq.delete({ where: { id } });
    await this.audit.log({
      action: 'DELETE',
      entityType: 'SiteFaq',
      entityId: id,
      summary: `حذف السؤال الشائع: ${item.questionAr}`,
      userId: user.id,
    });
    return { deleted: true, id };
  }

  getSettings() {
    return this.prisma.siteSetting.findMany({ orderBy: { key: 'asc' } });
  }

  async upsertSetting(key: string, dto: UpsertSiteSettingDto, user: AuthUser) {
    const data: { value: Prisma.InputJsonValue; description?: string } = {
      value: dto.value as Prisma.InputJsonValue,
    };
    if (dto.description !== undefined) data.description = dto.description;

    const setting = await this.prisma.siteSetting.upsert({
      where: { key },
      create: { key, ...data },
      update: data,
    });
    await this.audit.log({
      action: 'UPDATE',
      entityType: 'SiteSetting',
      entityId: setting.id,
      summary: `تحديث إعداد الموقع: ${key}`,
      userId: user.id,
    });
    return setting;
  }
}
