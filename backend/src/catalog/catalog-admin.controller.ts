import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Role } from '../../generated/prisma/enums';
import { Roles } from '../common/decorators/roles.decorator';
import { PaginationDto } from '../common/dto/pagination.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { CatalogService } from './catalog.service';
import {
  CreateCategoryDto,
  CreateProductDto,
  CreatePromotionDto,
  UpdateCategoryDto,
  UpdateProductDto,
  UpdatePromotionDto,
} from './dto/catalog.dto';
import { AdminProductQueryDto } from './dto/query.dto';

@ApiTags('admin-catalog')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
@Controller('admin')
export class CatalogAdminController {
  constructor(private readonly catalog: CatalogService) {}

  @Get('categories')
  listCategories(@Query() query: PaginationDto) {
    return this.catalog.adminListCategories(query);
  }

  @Post('categories')
  createCategory(@Body() dto: CreateCategoryDto) {
    return this.catalog.createCategory(dto);
  }

  @Patch('categories/:id')
  updateCategory(@Param('id') id: string, @Body() dto: UpdateCategoryDto) {
    return this.catalog.updateCategory(id, dto);
  }

  @Delete('categories/:id')
  deleteCategory(@Param('id') id: string) {
    return this.catalog.deleteCategory(id);
  }

  @Get('products')
  listProducts(@Query() query: AdminProductQueryDto) {
    return this.catalog.adminListProducts(query);
  }

  @Post('products')
  createProduct(@Body() dto: CreateProductDto) {
    return this.catalog.createProduct(dto);
  }

  @Patch('products/:id')
  updateProduct(@Param('id') id: string, @Body() dto: UpdateProductDto) {
    return this.catalog.updateProduct(id, dto);
  }

  @Delete('products/:id')
  deleteProduct(@Param('id') id: string) {
    return this.catalog.deleteProduct(id);
  }

  @Get('promotions')
  listPromotions(@Query() query: PaginationDto) {
    return this.catalog.adminListPromotions(query);
  }

  @Post('promotions')
  createPromotion(@Body() dto: CreatePromotionDto) {
    return this.catalog.createPromotion(dto);
  }

  @Patch('promotions/:id')
  updatePromotion(@Param('id') id: string, @Body() dto: UpdatePromotionDto) {
    return this.catalog.updatePromotion(id, dto);
  }

  @Delete('promotions/:id')
  deletePromotion(@Param('id') id: string) {
    return this.catalog.deletePromotion(id);
  }
}
