import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import type { Request, Response } from 'express';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request & { requestId?: string }>();
    const isProd = process.env.NODE_ENV === 'production';
    const requestId = request.requestId ?? 'unknown';

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message: string | string[] = 'Internal server error';
    let error = 'Internal Server Error';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const body = exception.getResponse();
      if (typeof body === 'string') {
        message = body;
      } else if (typeof body === 'object' && body !== null) {
        const obj = body as Record<string, unknown>;
        message = (obj.message as string | string[]) ?? message;
        error = (obj.error as string) ?? exception.name;
      }
    } else if (exception instanceof Error) {
      message = isProd ? 'Internal server error' : exception.message;
      this.logger.error(
        `[${requestId}] ${exception.message}`,
        isProd ? undefined : exception.stack,
      );
    }

    const payload: Record<string, unknown> = {
      statusCode: status,
      error,
      message,
      requestId,
      path: request.url,
      timestamp: new Date().toISOString(),
    };

    // Never leak stacks or secrets in production responses
    if (
      !isProd &&
      exception instanceof Error &&
      !(exception instanceof HttpException)
    ) {
      payload.stack = exception.stack;
    }

    response.status(status).json(payload);
  }
}
