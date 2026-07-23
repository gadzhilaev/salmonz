import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { SupportStatus } from '../../../generated/prisma/enums';

export class CreateSupportMessageDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(200)
  subject?: string;

  @ApiProperty()
  @IsString()
  @MinLength(1)
  @MaxLength(4000)
  message!: string;
}

export class UpdateSupportStatusDto {
  @ApiProperty({ enum: SupportStatus })
  @IsEnum(SupportStatus)
  status!: SupportStatus;
}
