export const ALLOWED_IMAGE_MIMES = [
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp',
] as const;

export type AllowedImageMime = (typeof ALLOWED_IMAGE_MIMES)[number];

export const IMAGE_EXT_BY_MIME: Record<AllowedImageMime, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/gif': 'gif',
  'image/webp': 'webp',
};

const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

/**
 * Detect image MIME from magic bytes. Rejects SVG and unknown types.
 */
export function detectImageMime(buffer: Buffer): AllowedImageMime | null {
  if (!buffer || buffer.length < 12) {
    return null;
  }

  // Reject SVG (text-based, never allow)
  const head = buffer
    .subarray(0, Math.min(buffer.length, 256))
    .toString('utf8');
  if (
    head.includes('<svg') ||
    (head.includes('<?xml') && head.toLowerCase().includes('svg'))
  ) {
    return null;
  }

  // JPEG
  if (buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) {
    return 'image/jpeg';
  }

  // PNG
  if (
    buffer[0] === 0x89 &&
    buffer[1] === 0x50 &&
    buffer[2] === 0x4e &&
    buffer[3] === 0x47
  ) {
    return 'image/png';
  }

  // GIF
  if (
    buffer[0] === 0x47 &&
    buffer[1] === 0x49 &&
    buffer[2] === 0x46 &&
    buffer[3] === 0x38
  ) {
    return 'image/gif';
  }

  // WEBP: RIFF....WEBP
  if (
    buffer[0] === 0x52 &&
    buffer[1] === 0x49 &&
    buffer[2] === 0x46 &&
    buffer[3] === 0x46 &&
    buffer[8] === 0x57 &&
    buffer[9] === 0x45 &&
    buffer[10] === 0x42 &&
    buffer[11] === 0x50
  ) {
    return 'image/webp';
  }

  return null;
}

export function assertAllowedImage(
  buffer: Buffer,
  maxBytes = MAX_IMAGE_BYTES,
): AllowedImageMime {
  if (buffer.length > maxBytes) {
    throw new Error(`Image exceeds max size of ${maxBytes} bytes`);
  }
  const mime = detectImageMime(buffer);
  if (!mime) {
    throw new Error(
      'Unsupported image type. Allowed: jpeg, png, gif, webp (SVG rejected)',
    );
  }
  return mime;
}

export function extensionForMime(mime: AllowedImageMime): string {
  return IMAGE_EXT_BY_MIME[mime];
}
