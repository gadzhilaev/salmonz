import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import type { Request, Response } from 'express';
import { Observable } from 'rxjs';

@Injectable()
export class RequestIdInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const http = context.switchToHttp();
    const request = http.getRequest<Request & { requestId?: string }>();
    const response = http.getResponse<Response>();
    const incoming = request.headers['x-request-id'];
    const requestId =
      typeof incoming === 'string' && incoming.trim()
        ? incoming.trim()
        : randomUUID();

    request.requestId = requestId;
    response.setHeader('x-request-id', requestId);
    return next.handle();
  }
}
