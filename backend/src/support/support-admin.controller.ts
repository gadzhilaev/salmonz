import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { IsEnum, IsOptional } from 'class-validator';
import { Role, SupportStatus } from '../../generated/prisma/enums';
import { Roles } from '../common/decorators/roles.decorator';
import { PaginationDto } from '../common/dto/pagination.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { UpdateSupportStatusDto } from './dto/support.dto';
import { SupportService } from './support.service';

class AdminSupportQueryDto extends PaginationDto {
  @ApiPropertyOptional({ enum: SupportStatus })
  @IsOptional()
  @IsEnum(SupportStatus)
  status?: SupportStatus;
}

@ApiTags('admin-support')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
@Controller('admin/support')
export class SupportAdminController {
  constructor(private readonly support: SupportService) {}

  @Get()
  list(@Query() query: AdminSupportQueryDto) {
    return this.support.adminList(query);
  }

  @Patch(':id/status')
  updateStatus(@Param('id') id: string, @Body() dto: UpdateSupportStatusDto) {
    return this.support.updateStatus(id, dto.status);
  }
}
