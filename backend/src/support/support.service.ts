import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { SupportStatus } from '../../generated/prisma/enums';
import {
  PaginationDto,
  paginate,
  paginationSkip,
} from '../common/dto/pagination.dto';
import { PrismaService } from '../prisma/prisma.service';
import { CreateSupportMessageDto } from './dto/support.dto';

@Injectable()
export class SupportService {
  constructor(private readonly prisma: PrismaService) {}

  create(userId: string, dto: CreateSupportMessageDto) {
    return this.prisma.supportMessage.create({
      data: {
        userId,
        subject: dto.subject,
        message: dto.message,
      },
    });
  }

  listMine(userId: string, query: PaginationDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const where = { userId };
    return this.prisma
      .$transaction([
        this.prisma.supportMessage.count({ where }),
        this.prisma.supportMessage.findMany({
          where,
          skip: paginationSkip(page, limit),
          take: limit,
          orderBy: { createdAt: 'desc' },
        }),
      ])
      .then(([total, rows]) => paginate(rows, total, page, limit));
  }

  async getMine(userId: string, id: string) {
    const row = await this.prisma.supportMessage.findUnique({ where: { id } });
    if (!row) throw new NotFoundException('Support message not found');
    if (row.userId !== userId) throw new ForbiddenException();
    return row;
  }

  adminList(query: PaginationDto & { status?: SupportStatus }) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const where = query.status ? { status: query.status } : {};
    return this.prisma
      .$transaction([
        this.prisma.supportMessage.count({ where }),
        this.prisma.supportMessage.findMany({
          where,
          skip: paginationSkip(page, limit),
          take: limit,
          orderBy: { createdAt: 'desc' },
          include: {
            user: {
              select: { id: true, email: true, name: true, phone: true },
            },
          },
        }),
      ])
      .then(([total, rows]) => paginate(rows, total, page, limit));
  }

  async updateStatus(id: string, status: SupportStatus) {
    const row = await this.prisma.supportMessage.findUnique({ where: { id } });
    if (!row) throw new NotFoundException('Support message not found');
    return this.prisma.supportMessage.update({
      where: { id },
      data: { status },
    });
  }
}
