import { detectImageMime, assertAllowedImage } from './image-mime.util';

describe('image-mime.util', () => {
  it('detects jpeg/png magic bytes', () => {
    const jpeg = Buffer.alloc(24, 0);
    jpeg[0] = 0xff;
    jpeg[1] = 0xd8;
    jpeg[2] = 0xff;
    jpeg[3] = 0xe0;

    const png = Buffer.alloc(24, 0);
    png[0] = 0x89;
    png[1] = 0x50;
    png[2] = 0x4e;
    png[3] = 0x47;
    png[4] = 0x0d;
    png[5] = 0x0a;
    png[6] = 0x1a;
    png[7] = 0x0a;

    expect(detectImageMime(jpeg)).toBe('image/jpeg');
    expect(detectImageMime(png)).toBe('image/png');
  });

  it('rejects svg', () => {
    const svg = Buffer.from('<svg xmlns="http://www.w3.org/2000/svg"></svg>');
    expect(detectImageMime(svg)).toBeNull();
    expect(() => assertAllowedImage(svg)).toThrow(/Unsupported/);
  });
});
