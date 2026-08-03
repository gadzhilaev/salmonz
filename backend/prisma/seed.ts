import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import * as argon2 from 'argon2';
import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { PrismaClient } from '../generated/prisma/client';
import { Role } from '../generated/prisma/enums';

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error('DATABASE_URL is required for seeding');
}

const adapter = new PrismaPg({ connectionString });
const prisma = new PrismaClient({ adapter });

/** Flutter assets live one level above backend/ when developing from monorepo. */
const assetsRoot =
  process.env.ASSETS_ROOT?.trim() ||
  path.resolve(__dirname, '..', '..', 'assets');

type CatDef = { name: string; slug: string; sortOrder: number; folder: string };

const CATEGORIES: CatDef[] = [
  { name: 'Роллы', slug: 'rolls', sortOrder: 1, folder: 'rolls' },
  { name: 'Сеты', slug: 'sets', sortOrder: 2, folder: 'sets' },
  { name: 'Суши', slug: 'sushi', sortOrder: 3, folder: 'sushi' },
  { name: 'Закуски', slug: 'snacks', sortOrder: 4, folder: 'snacks' },
  { name: 'Лапша', slug: 'noodles', sortOrder: 5, folder: 'noodles' },
  { name: 'Напитки', slug: 'drinks', sortOrder: 6, folder: 'drinks' },
  { name: 'Десерты', slug: 'deserts', sortOrder: 7, folder: 'deserts' },
  { name: 'Соусы', slug: 'sauce', sortOrder: 8, folder: 'sauce' },
];

/** Human titles / prices for known asset stems; others get a pretty-printed name. */
const PRODUCT_META: Record<
  string,
  { name: string; description?: string; price: number; oldPrice?: number; weight?: number }
> = {
  Philadelphia: {
    name: 'Филадельфия',
    description: 'Лосось, сыр, огурец',
    price: 459,
    oldPrice: 520,
    weight: 250,
  },
  phil_avo: {
    name: 'Филадельфия с авокадо',
    description: 'Лосось, сыр, авокадо',
    price: 489,
    weight: 260,
  },
  zapec_phil: {
    name: 'Запечённая филадельфия',
    description: 'Лосось, сыр, соус',
    price: 520,
    weight: 270,
  },
  california: {
    name: 'Калифорния',
    description: 'Краб, авокадо, огурец',
    price: 399,
    weight: 230,
  },
  spicy_crab: {
    name: 'Спайси краб',
    description: 'Краб, спайси соус',
    price: 420,
    weight: 220,
  },
  vulkan_spicy: {
    name: 'Вулкан спайси',
    description: 'Острый ролл',
    price: 449,
    weight: 240,
  },
  white_tiger: {
    name: 'Белый тигр',
    description: 'Креветка, сыр',
    price: 479,
    weight: 245,
  },
  in_yan: { name: 'Инь-Ян', description: 'Двухцветный ролл', price: 469, weight: 250 },
  mikasa: { name: 'Микаса', price: 439, weight: 240 },
  tomago: { name: 'Томаго', description: 'Яичный ролл', price: 359, weight: 210 },
  tunez: { name: 'Тунец', description: 'Тунец, огурец', price: 429, weight: 230 },
  tanaka: { name: 'Танака', price: 449, weight: 240 },
  los: { name: 'Лосось ролл', description: 'Лосось', price: 419, weight: 230 },
  vasabi: { name: 'Васаби ролл', price: 399, weight: 220 },
  set1: {
    name: 'Сет №1',
    description: 'Классическое ассорти',
    price: 1290,
    oldPrice: 1490,
    weight: 800,
  },
  set2: { name: 'Сет №2', description: 'Роллы для двоих', price: 1590, weight: 950 },
  set3: {
    name: 'Семейный сет',
    description: '24 кусочка ассорти',
    price: 1890,
    oldPrice: 2190,
    weight: 1100,
  },
  set4: { name: 'Сет №4', description: 'Запечённые роллы', price: 1690, weight: 1000 },
  set5: { name: 'Сет №5', description: 'Большой сет', price: 2190, weight: 1300 },
  salmon: { name: 'Суши лосось', price: 129, weight: 40 },
  shrimp: { name: 'Суши креветка', price: 139, weight: 40 },
  acne: { name: 'Суши угорь', price: 149, weight: 40 },
  baked_mussels: {
    name: 'Запечённые мидии',
    description: 'Мидии под сыром',
    price: 390,
    weight: 180,
  },
  shrimp_tempura: {
    name: 'Креветки темпура',
    description: 'Хрустящие креветки',
    price: 420,
    weight: 160,
  },
  salmon_sandwich_roll: {
    name: 'Сэндвич-ролл с лососем',
    price: 349,
    weight: 200,
  },
  chicken_vegetables: {
    name: 'Лапша с курицей и овощами',
    price: 390,
    weight: 350,
  },
  rice_chicken_vegetables: {
    name: 'Рис с курицей и овощами',
    price: 370,
    weight: 340,
  },
  shrimp_vegetables: {
    name: 'Лапша с креветками',
    price: 430,
    weight: 350,
  },
  homemade_cherry_fruit_drink: {
    name: 'Морс вишнёвый',
    price: 120,
    weight: 500,
  },
  homemade_mors_cranberry: {
    name: 'Морс клюквенный',
    price: 120,
    weight: 500,
  },
  homemade_mors_sea_buckthorn: {
    name: 'Морс облепиховый',
    price: 130,
    weight: 500,
  },
  banana_kiwi_roll: {
    name: 'Ролл банан-киви',
    description: 'Сладкий ролл',
    price: 290,
    weight: 180,
  },
  roll_tropic: { name: 'Тропический ролл', price: 310, weight: 180 },
  strawberry_cheesecake: {
    name: 'Чизкейк клубничный',
    price: 280,
    weight: 150,
  },
  soy: { name: 'Соевый соус', price: 40, weight: 50 },
  spicy: { name: 'Спайси соус', price: 50, weight: 50 },
  kimchi: { name: 'Кимчи соус', price: 55, weight: 50 },
};

function titleFromStem(stem: string): string {
  return stem
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

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
      phone: '+79990000001',
      role: Role.ADMIN,
    },
    update: {
      passwordHash,
      role: Role.ADMIN,
      isActive: true,
      name: 'Admin',
    },
  });
  console.log(`Admin upserted: ${email.toLowerCase()}`);
}

async function upsertDemoUser() {
  const email = process.env.DEMO_USER_EMAIL?.trim();
  const password = process.env.DEMO_USER_PASSWORD;
  if (!email || !password) {
    console.log('DEMO_USER_EMAIL/DEMO_USER_PASSWORD not set — skipping demo user');
    return null;
  }
  const passwordHash = await argon2.hash(password, { type: argon2.argon2id });
  const user = await prisma.user.upsert({
    where: { email: email.toLowerCase() },
    create: {
      email: email.toLowerCase(),
      passwordHash,
      name: 'Demo User',
      phone: '+79991234567',
      role: Role.USER,
    },
    update: {
      passwordHash,
      isActive: true,
      name: 'Demo User',
      phone: '+79991234567',
    },
  });
  console.log(`Demo user upserted: ${email.toLowerCase()}`);
  return user;
}

async function seedDemoAddress(userId: string) {
  const existing = await prisma.address.findFirst({
    where: { userId, isDefault: true },
  });
  if (existing) {
    await prisma.address.update({
      where: { id: existing.id },
      data: {
        title: 'Дом',
        city: 'Махачкала',
        street: 'пр. Акушинского',
        house: '12',
        apartment: '45',
        entrance: '2',
        floor: '5',
        comment: 'Домофон 45',
        isDefault: true,
      },
    });
  } else {
    await prisma.address.create({
      data: {
        userId,
        title: 'Дом',
        city: 'Махачкала',
        street: 'пр. Акушинского',
        house: '12',
        apartment: '45',
        entrance: '2',
        floor: '5',
        comment: 'Домофон 45',
        isDefault: true,
      },
    });
  }
  console.log('Demo address upserted');
}

async function uploadBuffer(key: string, body: Buffer, contentType: string) {
  const driver = (process.env.STORAGE_DRIVER ?? 'local').toLowerCase();
  if (driver === 's3') {
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
        ContentType: contentType,
      }),
    );
    return;
  }

  const { mkdir, writeFile } = await import('node:fs/promises');
  const root = process.env.LOCAL_UPLOAD_DIR ?? 'uploads';
  const dest = path.join(root, key);
  await mkdir(path.dirname(dest), { recursive: true });
  await writeFile(dest, body);
}

async function uploadFile(absPath: string, key: string) {
  const body = await readFile(absPath);
  const ext = path.extname(absPath).toLowerCase();
  const contentType =
    ext === '.png'
      ? 'image/png'
      : ext === '.jpg' || ext === '.jpeg'
        ? 'image/jpeg'
        : ext === '.webp'
          ? 'image/webp'
          : 'application/octet-stream';
  try {
    await uploadBuffer(key, body, contentType);
    return key;
  } catch (e) {
    console.log(`Upload skipped ${key}: ${(e as Error).message}`);
    return null;
  }
}

async function seedCatalog() {
  const categoryIds = new Map<string, string>();

  for (const c of CATEGORIES) {
    const row = await prisma.category.upsert({
      where: { slug: c.slug },
      create: {
        name: c.name,
        slug: c.slug,
        sortOrder: c.sortOrder,
        isActive: true,
      },
      update: { name: c.name, isActive: true, sortOrder: c.sortOrder },
    });
    categoryIds.set(c.slug, row.id);
  }
  console.log(`Categories upserted: ${CATEGORIES.length}`);

  let productCount = 0;
  for (const c of CATEGORIES) {
    const dir = path.join(assetsRoot, 'products', c.folder);
    let files: string[] = [];
    try {
      files = (await readdir(dir)).filter((f) =>
        /\.(png|jpe?g|webp)$/i.test(f),
      );
    } catch {
      console.log(`No assets for ${c.folder} at ${dir}`);
      continue;
    }

    let sort = 1;
    for (const file of files) {
      const stem = path.parse(file).name;
      const meta = PRODUCT_META[stem] ?? {
        name: titleFromStem(stem),
        price: 350,
        weight: 200,
      };
      const imageKey = `products/${c.folder}/${file}`;
      await uploadFile(path.join(dir, file), imageKey);

      const categoryId = categoryIds.get(c.slug)!;
      const existing = await prisma.product.findFirst({
        where: { name: meta.name, categoryId },
      });
      const data = {
        categoryId,
        name: meta.name,
        description: meta.description ?? '',
        price: meta.price,
        oldPrice: meta.oldPrice ?? null,
        weight: meta.weight ?? null,
        imageKey,
        isAvailable: true,
        sortOrder: sort++,
      };
      if (existing) {
        await prisma.product.update({ where: { id: existing.id }, data });
      } else {
        await prisma.product.create({ data });
      }
      productCount++;
    }
  }

  // Ensure classic drinks item exists even without a dedicated cola asset.
  const drinksId = categoryIds.get('drinks');
  if (drinksId) {
    const cola = await prisma.product.findFirst({
      where: { name: 'Кола 0.5л', categoryId: drinksId },
    });
    if (!cola) {
      await prisma.product.create({
        data: {
          categoryId: drinksId,
          name: 'Кола 0.5л',
          description: '',
          price: 120,
          weight: 500,
          isAvailable: true,
          sortOrder: 99,
        },
      });
      productCount++;
    }
  }

  console.log(`Products upserted: ${productCount}`);

  // Promotions from assets/promotions + classic free-delivery.
  const promoDir = path.join(assetsRoot, 'promotions');
  const promoDefs = [
    {
      title: 'Бесплатная доставка от 1500₽',
      description: 'При заказе от 1500 ₽ доставка бесплатно',
      file: 'promotion1.png',
      sortOrder: 1,
      fallbackKey: 'promotions/free-delivery.webp',
      fallbackFile: path.join(
        __dirname,
        '..',
        'seed-assets',
        'promo-free-delivery.png',
      ),
    },
    {
      title: 'Скидка на сеты −15%',
      description: 'Только сегодня на все сеты',
      file: 'promotion2.png',
      sortOrder: 2,
    },
    {
      title: '2 ролла по цене 1',
      description: 'На классические роллы в будние дни',
      file: 'promotion3.png',
      sortOrder: 3,
    },
    {
      title: 'Новинки недели',
      description: 'Попробуйте свежие позиции меню',
      file: 'promotion4.png',
      sortOrder: 4,
    },
  ];

  for (const p of promoDefs) {
    let imageKey = `promotions/${p.file}`;
    const fromAssets = path.join(promoDir, p.file);
    let uploaded = await uploadFile(fromAssets, imageKey).catch(() => null);
    if (!uploaded && p.fallbackFile) {
      imageKey = p.fallbackKey ?? imageKey;
      uploaded = await uploadFile(p.fallbackFile, imageKey);
    }
    if (!uploaded) {
      console.log(`Promo image missing for ${p.title} — skip`);
      continue;
    }
    const existing = await prisma.promotion.findFirst({
      where: { title: p.title },
    });
    const data = {
      title: p.title,
      description: p.description,
      imageKey,
      isActive: true,
      sortOrder: p.sortOrder,
    };
    if (existing) {
      await prisma.promotion.update({ where: { id: existing.id }, data });
    } else {
      await prisma.promotion.create({ data });
    }
  }
  console.log('Promotions upserted');
}

async function main() {
  console.log(`ASSETS_ROOT=${assetsRoot}`);
  await upsertAdmin();
  const demo = await upsertDemoUser();
  if (demo) await seedDemoAddress(demo.id);
  await seedCatalog();
  console.log('Seed complete — app is ready for local demo');
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
