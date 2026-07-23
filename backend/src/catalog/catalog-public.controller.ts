import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { CatalogService } from './catalog.service';
import { ProductQueryDto } from './dto/query.dto';

@ApiTags('catalog')
@Controller()
export class CatalogPublicController {
  constructor(private readonly catalog: CatalogService) {}

  @Get('categories')
  listCategories() {
    return this.catalog.listCategories();
  }

  @Get('categories/:idOrSlug')
  getCategory(@Param('idOrSlug') idOrSlug: string) {
    return this.catalog.getCategory(idOrSlug);
  }

  @Get('products')
  listProducts(@Query() query: ProductQueryDto) {
    return this.catalog.listProducts(query);
  }

  @Get('products/:id')
  getProduct(@Param('id') id: string) {
    return this.catalog.getProduct(id);
  }

  @Get('promotions')
  listPromotions() {
    return this.catalog.listPromotions();
  }
}
