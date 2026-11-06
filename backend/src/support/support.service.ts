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
import {
  CreateSupportMessageDto,
  CreateSupportReplyDto,
} from './dto/support.dto';

@Injectable()
export class SupportService {
  constructor(private readonly prisma: PrismaService) {}

  private readonly withReplies = {
    replies: { orderBy: { createdAt: 'asc' as const } },
  };

  create(userId: string, dto: CreateSupportMessageDto) {
    return this.prisma.supportMessage.create({
      data: {
        userId,
        subject: dto.subject,
        message: dto.message,
      },
      include: this.withReplies,
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
          include: this.withReplies,
        }),
      ])
      .then(([total, rows]) => paginate(rows, total, page, limit));
  }

  async getMine(userId: string, id: string) {
    const row = await this.prisma.supportMessage.findUnique({
      where: { id },
      include: this.withReplies,
    });
    if (!row) throw new NotFoundException('Support message not found');
    if (row.userId !== userId) throw new ForbiddenException();
    return row;
  }

  async replyAsUser(userId: string, id: string, dto: CreateSupportReplyDto) {
    const row = await this.prisma.supportMessage.findUnique({ where: { id } });
    if (!row) throw new NotFoundException('Support message not found');
    if (row.userId !== userId) throw new ForbiddenException();

    await this.prisma.supportReply.create({
      data: {
        messageId: id,
        authorUserId: userId,
        body: dto.body.trim(),
        isStaff: false,
      },
    });
    if (row.status === SupportStatus.CLOSED) {
      await this.prisma.supportMessage.update({
        where: { id },
        data: { status: SupportStatus.IN_PROGRESS },
      });
    }
    return this.getMine(userId, id);
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
            ...this.withReplies,
            user: {
              select: { id: true, email: true, name: true, phone: true },
            },
          },
        }),
      ])
      .then(([total, rows]) => paginate(rows, total, page, limit));
  }

  async adminGet(id: string) {
    const row = await this.prisma.supportMessage.findUnique({
      where: { id },
      include: {
        ...this.withReplies,
        user: {
          select: { id: true, email: true, name: true, phone: true },
        },
      },
    });
    if (!row) throw new NotFoundException('Support message not found');
    return row;
  }

  async replyAsAdmin(adminId: string, id: string, dto: CreateSupportReplyDto) {
    const row = await this.prisma.supportMessage.findUnique({ where: { id } });
    if (!row) throw new NotFoundException('Support message not found');

    await this.prisma.$transaction([
      this.prisma.supportReply.create({
        data: {
          messageId: id,
          authorUserId: adminId,
          body: dto.body.trim(),
          isStaff: true,
        },
      }),
      this.prisma.supportMessage.update({
        where: { id },
        data: {
          status:
            row.status === SupportStatus.NEW
              ? SupportStatus.IN_PROGRESS
              : row.status,
        },
      }),
    ]);
    return this.adminGet(id);
  }

  async updateStatus(id: string, status: SupportStatus) {
    const row = await this.prisma.supportMessage.findUnique({ where: { id } });
    if (!row) throw new NotFoundException('Support message not found');
    return this.prisma.supportMessage.update({
      where: { id },
      data: { status },
      include: this.withReplies,
    });
  }
}
