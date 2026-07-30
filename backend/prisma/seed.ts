import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import * as argon2 from 'argon2';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { PrismaClient } from '../generated/prisma/client';
import { Role } from '../generated/prisma/enums';

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error('DATABASE_URL is required for seeding');
}

const adapter = new PrismaPg({ connectionString });
const prisma = new PrismaClient({ adapter });

async function upsertAdmin() {
  const email = process.env.ADMIN_EMAIL?.trim();
  const password = process.env.ADMIN_PASSWORD;
  if (!email || !password) {
    throw new Error(
      'ADMIN_EMAIL and ADMIN_PASSWORD are required to seed the admin user',
    );
  }

  const passwordHash = await argon2.hash(password, { type: argon2.argon2id });
  await prisma.user.upsert({
    where: { email: email.toLowerCase() },
    create: {
      email: email.toLowerCase(),
      passwordHash,
      name: 'Admin',
      role: Role.ADMIN,
    },
    update: {
      passwordHash,
      role: Role.ADMIN,
      isActive: true,
    },
  });
  console.log(`Admin upserted: ${email.toLowerCase()}`);
}

async function upsertDemoUser() {
  const email = process.env.DEMO_USER_EMAIL?.trim();
  const password = process.env.DEMO_USER_PASSWORD;
  if (!email || !password) {
    console.log('DEMO_USER_EMAIL/DEMO_USER_PASSWORD not set — skipping demo user');
    return;
  }
  const passwordHash = await argon2.hash(password, { type: argon2.argon2id });
  await prisma.user.upsert({
    where: { email: email.toLowerCase() },
    create: {
      email: email.toLowerCase(),
      passwordHash,
      name: 'Demo User',
      role: Role.USER,
    },
    update: {
      passwordHash,
      isActive: true,
    },
  });
  console.log(`Demo user upserted: ${email.toLowerCase()}`);
}

async function seedCatalog() {
  const rolls = await prisma.category.upsert({
    where: { slug: 'rolls' },
    create: {
      name: 'Роллы',
      slug: 'rolls',
      sortOrder: 1,
      isActive: true,
    },
    update: { name: 'Роллы', isActive: true, sortOrder: 1 },
  });

  const sets = await prisma.category.upsert({
    where: { slug: 'sets' },
    create: {
      name: 'Сеты',
      slug: 'sets',
      sortOrder: 2,
      isActive: true,
    },
    update: { name: 'Сеты', isActive: true, sortOrder: 2 },
  });

  const drinks = await prisma.category.upsert({
    where: { slug: 'drinks' },
    create: {
      name: 'Напитки',
      slug: 'drinks',
      sortOrder: 3,
      isActive: true,
    },
    update: { name: 'Напитки', isActive: true, sortOrder: 3 },
  });

  const products = [
    {
      key: 'philadelphia',
      categoryId: rolls.id,
      name: 'Филадельфия',
      description: 'Лосось, сыр, огурец',
      price: 459,
      oldPrice: 520,
      weight: 250,
      sortOrder: 1,
    },
    {
      key: 'california',
      categoryId: rolls.id,
      name: 'Калифорния',
      description: 'Краб, авокадо, огурец',
      price: 399,
      weight: 230,
      sortOrder: 2,
    },
    {
      key: 'set-family',
      categoryId: sets.id,
      name: 'Семейный сет',
      description: '24 кусочка ассорти',
      price: 1490,
      oldPrice: 1690,
      weight: 900,
      sortOrder: 1,
    },
    {
      key: 'cola',
      categoryId: drinks.id,
      name: 'Кола 0.5л',
      description: '',
      price: 120,
      weight: 500,
      sortOrder: 1,
    },
  ];

  for (const p of products) {
    const existing = await prisma.product.findFirst({
      where: { name: p.name, categoryId: p.categoryId },
    });
    if (existing) {
      await prisma.product.update({
        where: { id: existing.id },
        data: {
          description: p.description,
          price: p.price,
          oldPrice: p.oldPrice ?? null,
          weight: p.weight,
          isAvailable: true,
          sortOrder: p.sortOrder,
        },
      });
    } else {
      await prisma.product.create({
        data: {
          categoryId: p.categoryId,
          name: p.name,
          description: p.description,
          price: p.price,
          oldPrice: p.oldPrice,
          weight: p.weight,
          isAvailable: true,
          sortOrder: p.sortOrder,
        },
      });
    }
  }

  const promoTitle = 'Бесплатная доставка от 1500₽';
  const promoImageKey = 'promotions/free-delivery.webp';
  await uploadSeedPromo(promoImageKey);

  const promo = await prisma.promotion.findFirst({ where: { title: promoTitle } });
  if (promo) {
    await prisma.promotion.update({
      where: { id: promo.id },
      data: {
        description: 'При заказе от 1500 ₽ доставка бесплатно',
        imageKey: promoImageKey,
        isActive: true,
        sortOrder: 1,
      },
    });
  } else {
    await prisma.promotion.create({
      data: {
        title: promoTitle,
        description: 'При заказе от 1500 ₽ доставка бесплатно',
        imageKey: promoImageKey,
        isActive: true,
        sortOrder: 1,
      },
    });
  }

  console.log('Catalog seed upserted');
}

/** Best-effort upload of demo promo art into local/S3 storage. */
async function uploadSeedPromo(key: string) {
  const filePath = path.join(__dirname, '..', 'seed-assets', 'promo-free-delivery.png');
  let body: Buffer;
  try {
    body = await readFile(filePath);
  } catch {
    console.log('seed-assets/promo-free-delivery.png missing — skip promo upload');
    return;
  }

  const driver = (process.env.STORAGE_DRIVER ?? 'local').toLowerCase();
  if (driver === 's3') {
    try {
      const { PutObjectCommand, S3Client } = await import('@aws-sdk/client-s3');
      const endpoint = process.env.S3_ENDPOINT;
      const bucket = process.env.S3_BUCKET ?? 'salmonz';
      const client = new S3Client({
        region: process.env.S3_REGION ?? 'us-east-1',
        endpoint,
        forcePathStyle: (process.env.S3_FORCE_PATH_STYLE ?? 'true') === 'true',
        credentials: {
          accessKeyId: process.env.S3_ACCESS_KEY ?? 'minioadmin',
          secretAccessKey: process.env.S3_SECRET_KEY ?? 'minioadmin',
        },
      });
      await client.send(
        new PutObjectCommand({
          Bucket: bucket,
          Key: key,
          Body: body,
          ContentType: 'image/png',
        }),
      );
      console.log(`Promo image uploaded to s3://${bucket}/${key}`);
    } catch (e) {
      console.log(`Promo S3 upload skipped: ${(e as Error).message}`);
    }
    return;
  }

  try {
    const { mkdir, writeFile } = await import('node:fs/promises');
    const root = process.env.LOCAL_UPLOAD_DIR ?? 'uploads';
    const dest = path.join(root, key);
    await mkdir(path.dirname(dest), { recursive: true });
    await writeFile(dest, body);
    console.log(`Promo image written to ${dest}`);
  } catch (e) {
    console.log(`Promo local upload skipped: ${(e as Error).message}`);
  }
}

async function main() {
  await upsertAdmin();
  await upsertDemoUser();
  await seedCatalog();
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
