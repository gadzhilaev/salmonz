import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import * as argon2 from 'argon2';
import { createHash } from 'node:crypto';
import { existsSync } from 'node:fs';
import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { PrismaClient } from '../generated/prisma/client';
import { OrderStatus, Role, SupportStatus } from '../generated/prisma/enums';

/**
 * Local demo seed only.
 * Refuses to run when NODE_ENV=production unless ALLOW_DEMO_SEED=1
 * (still blocked if NODE_ENV is production AND ALLOW_DEMO_SEED is not explicitly set —
 * and even with the flag we refuse real production-looking DATABASE_URL hosts).
 */
function assertDemoSeedAllowed() {
  const nodeEnv = (process.env.NODE_ENV ?? 'development').toLowerCase();
  const allow = process.env.ALLOW_DEMO_SEED === '1';
  if (nodeEnv === 'production' && !allow) {
    throw new Error(
      'Demo seed refused: NODE_ENV=production. This seed is for local portfolio demos only.',
    );
  }
  if (nodeEnv === 'production' && allow) {
    throw new Error(
      'Demo seed refused even with ALLOW_DEMO_SEED=1 under NODE_ENV=production.',
    );
  }
  const db = process.env.DATABASE_URL ?? '';
  if (/[?&]sslmode=require/i.test(db) && /amazonaws\.com|neon\.tech|supabase\.co|railway\.app/i.test(db)) {
    throw new Error(
      'Demo seed refused: DATABASE_URL looks like a hosted production database.',
    );
  }
}

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error('DATABASE_URL is required for seeding');
}

assertDemoSeedAllowed();

const adapter = new PrismaPg({ connectionString });
const prisma = new PrismaClient({ adapter });

/** Flutter assets live one level above backend/ when developing from monorepo. */
const assetsRoot =
  process.env.ASSETS_ROOT?.trim() ||
  path.resolve(__dirname, '..', '..', 'assets');

const demoRoot = path.join(assetsRoot, 'demo');

type CatDef = {
  name: string;
  slug: string;
  sortOrder: number;
  folder: string;
  imageCandidates: string[];
};

const CATEGORIES: CatDef[] = [
  {
    name: 'Роллы',
    slug: 'rolls',
    sortOrder: 1,
    folder: 'rolls',
    imageCandidates: [
      'demo/categories/rolls.png',
      'main/rolls.png',
    ],
  },
  {
    name: 'Сеты',
    slug: 'sets',
    sortOrder: 2,
    folder: 'sets',
    imageCandidates: ['demo/categories/sets.png', 'main/sets.png'],
  },
  {
    name: 'Суши',
    slug: 'sushi',
    sortOrder: 3,
    folder: 'sushi',
    imageCandidates: ['demo/categories/sushi.png', 'main/sushi.png'],
  },
  {
    name: 'Закуски',
    slug: 'snacks',
    sortOrder: 4,
    folder: 'snacks',
    imageCandidates: ['demo/categories/snacks.png', 'main/zakuski.png'],
  },
  {
    name: 'Лапша',
    slug: 'noodles',
    sortOrder: 5,
    folder: 'noodles',
    imageCandidates: ['demo/categories/noodles.png', 'main/lapsha.png'],
  },
  {
    name: 'Напитки',
    slug: 'drinks',
    sortOrder: 6,
    folder: 'drinks',
    imageCandidates: ['demo/categories/drinks.png', 'main/bootls.png'],
  },
  {
    name: 'Десерты',
    slug: 'deserts',
    sortOrder: 7,
    folder: 'deserts',
    imageCandidates: ['demo/categories/deserts.png', 'main/cakes.png'],
  },
  {
    name: 'Соусы',
    slug: 'sauce',
    sortOrder: 8,
    folder: 'sauce',
    imageCandidates: ['demo/categories/sauce.png', 'main/souses.png'],
  },
];

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
  dragon: {
    name: 'Дракон',
    description: 'Угорь, авокадо, унаги-соус',
    price: 529,
    weight: 280,
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
  cola: {
    name: 'Кола 0.5л',
    description: 'Газированный напиток 0.5 л',
    price: 120,
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
  return stem.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
}

async function fileExists(abs: string) {
  try {
    await readFile(abs);
    return true;
  } catch {
    return false;
  }
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

async function resolveAndUpload(relCandidates: string[], key: string) {
  for (const rel of relCandidates) {
    const abs = path.join(assetsRoot, rel);
    if (await fileExists(abs)) {
      const uploaded = await uploadFile(abs, key);
      if (uploaded) return uploaded;
    }
  }
  return null;
}

async function upsertAdmin() {
  const email = (process.env.ADMIN_EMAIL?.trim() || 'admin@example.com').toLowerCase();
  const password = process.env.ADMIN_PASSWORD || 'ChangeMeAdmin123!';
  const passwordHash = await argon2.hash(password, { type: argon2.argon2id });
  await prisma.user.upsert({
    where: { email },
    create: {
      email,
      passwordHash,
      name: 'Admin Demo',
      phone: '+79990000001',
      role: Role.ADMIN,
    },
    update: {
      passwordHash,
      role: Role.ADMIN,
      isActive: true,
      name: 'Admin Demo',
    },
  });
  console.log(`Admin upserted: ${email}`);
}

async function upsertDemoUser() {
  const email = (process.env.DEMO_USER_EMAIL?.trim() || 't@test.ru').toLowerCase();
  const password = process.env.DEMO_USER_PASSWORD || '12345678';
  const passwordHash = await argon2.hash(password, { type: argon2.argon2id });
  const user = await prisma.user.upsert({
    where: { email },
    create: {
      email,
      passwordHash,
      name: 'Иван Демо',
      phone: '+79991234567',
      role: Role.USER,
    },
    update: {
      passwordHash,
      isActive: true,
      name: 'Иван Демо',
      phone: '+79991234567',
    },
  });
  console.log(`Demo user upserted: ${email}`);
  return user;
}

async function seedDemoAddresses(userId: string) {
  const specs = [
    {
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
    {
      title: 'Работа',
      city: 'Махачкала',
      street: 'ул. Ярагского',
      house: '77',
      apartment: '12',
      entrance: '1',
      floor: '3',
      comment: 'Офис Salmonz Demo',
      isDefault: false,
    },
  ];

  for (const s of specs) {
    const existing = await prisma.address.findFirst({
      where: { userId, title: s.title },
    });
    if (existing) {
      await prisma.address.update({ where: { id: existing.id }, data: s });
    } else {
      await prisma.address.create({ data: { userId, ...s } });
    }
  }
  console.log(`Demo addresses upserted: ${specs.length}`);
}

async function seedCatalog() {
  const categoryIds = new Map<string, string>();

  for (const c of CATEGORIES) {
    const imageKey = `categories/${c.slug}.png`;
    await resolveAndUpload(c.imageCandidates, imageKey);
    const row = await prisma.category.upsert({
      where: { slug: c.slug },
      create: {
        name: c.name,
        slug: c.slug,
        sortOrder: c.sortOrder,
        isActive: true,
        imageKey,
      },
      update: {
        name: c.name,
        isActive: true,
        sortOrder: c.sortOrder,
        imageKey,
      },
    });
    categoryIds.set(c.slug, row.id);
  }
  console.log(`Categories upserted: ${CATEGORIES.length}`);

  let productCount = 0;
  for (const c of CATEGORIES) {
    const dir = path.join(assetsRoot, 'products', c.folder);
    let files: string[] = [];
    try {
      files = (await readdir(dir)).filter((f) => /\.(png|jpe?g|webp)$/i.test(f));
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

  // Legacy row «Кола 0.5л» without imageKey: attach drinks/cola.png if present.
  const drinksId = categoryIds.get('drinks');
  if (drinksId) {
    const colaPath = path.join(assetsRoot, 'products', 'drinks', 'cola.png');
    const colaKey = 'products/drinks/cola.png';
    if (existsSync(colaPath)) {
      await uploadFile(colaPath, colaKey);
      const orphan = await prisma.product.findFirst({
        where: { name: 'Кола 0.5л', categoryId: drinksId, imageKey: null },
      });
      if (orphan) {
        await prisma.product.update({
          where: { id: orphan.id },
          data: {
            imageKey: colaKey,
            description: 'Газированный напиток 0.5 л',
            price: 120,
            weight: 500,
            isAvailable: true,
          },
        });
      }
    }
  }

  console.log(`Products upserted: ${productCount}`);

  const promoDefs = [
    {
      title: 'Бесплатная доставка от 1500₽',
      description: 'При заказе от 1500 ₽ доставка бесплатно',
      candidates: [
        'demo/promotions/promo_delivery.png',
        'promotions/promotion1.png',
      ],
      key: 'promotions/promo_delivery.png',
      sortOrder: 1,
    },
    {
      title: 'Скидка на сеты −15%',
      description: 'Только сегодня на все сеты',
      candidates: ['demo/promotions/promo_sets.png', 'promotions/promotion2.png'],
      key: 'promotions/promo_sets.png',
      sortOrder: 2,
    },
    {
      title: 'Острые новинки недели',
      description: 'Спайси-роллы и вулкан со скидкой',
      candidates: [
        'demo/promotions/promo_spicy.png',
        'promotions/promotion3.png',
      ],
      key: 'promotions/promo_spicy.png',
      sortOrder: 3,
    },
    {
      title: '2 ролла по цене 1',
      description: 'На классические роллы в будние дни',
      candidates: ['promotions/promotion4.png', 'demo/banners/home_hero.png'],
      key: 'promotions/promo_two_for_one.png',
      sortOrder: 4,
    },
  ];

  for (const p of promoDefs) {
    const uploaded = await resolveAndUpload(p.candidates, p.key);
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
      imageKey: p.key,
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

  return categoryIds;
}

async function seedDemoOrders(userId: string) {
  const products = await prisma.product.findMany({
    where: { isAvailable: true },
    orderBy: { sortOrder: 'asc' },
    take: 12,
  });
  if (products.length < 3) {
    console.log('Not enough products for demo orders — skip');
    return;
  }

  const addressSnapshot = {
    title: 'Дом',
    city: 'Махачкала',
    street: 'пр. Акушинского',
    house: '12',
    apartment: '45',
  };

  const scenarios: Array<{
    key: string;
    status: OrderStatus;
    publicNumber: string;
    pick: number[];
    deliveryFee: number;
  }> = [
    {
      key: 'demo-order-completed-1',
      status: OrderStatus.COMPLETED,
      publicNumber: 'DEMO-1001',
      pick: [0, 1, 2],
      deliveryFee: 0,
    },
    {
      key: 'demo-order-delivering-1',
      status: OrderStatus.DELIVERING,
      publicNumber: 'DEMO-1002',
      pick: [3, 4],
      deliveryFee: 199,
    },
    {
      key: 'demo-order-new-1',
      status: OrderStatus.NEW,
      publicNumber: 'DEMO-1003',
      pick: [5, 6, 7],
      deliveryFee: 199,
    },
  ];

  for (const s of scenarios) {
    const items = s.pick
      .map((i) => products[i % products.length])
      .filter(Boolean)
      .map((p) => {
        const qty = 1 + (s.pick.length % 2);
        const unit = Number(p.price);
        return {
          productId: p.id,
          productNameSnapshot: p.name,
          unitPrice: unit,
          quantity: qty,
          lineTotal: unit * qty,
        };
      });
    const subtotal = items.reduce((a, i) => a + i.lineTotal, 0);
    const total = subtotal + s.deliveryFee;
    const payloadHash = createHash('sha256')
      .update(JSON.stringify({ items, total }))
      .digest('hex');

    const existing = await prisma.order.findFirst({
      where: { userId, idempotencyKey: s.key },
    });
    if (existing) {
      await prisma.orderItem.deleteMany({ where: { orderId: existing.id } });
      await prisma.order.update({
        where: { id: existing.id },
        data: {
          status: s.status,
          publicNumber: s.publicNumber,
          addressSnapshot,
          phone: '+79991234567',
          comment: 'Демо-заказ для портфолио',
          subtotal,
          deliveryFee: s.deliveryFee,
          total,
          idempotencyPayloadHash: payloadHash,
          items: { create: items },
        },
      });
    } else {
      await prisma.order.create({
        data: {
          userId,
          publicNumber: s.publicNumber,
          addressSnapshot,
          phone: '+79991234567',
          comment: 'Демо-заказ для портфолио',
          status: s.status,
          subtotal,
          deliveryFee: s.deliveryFee,
          total,
          idempotencyKey: s.key,
          idempotencyPayloadHash: payloadHash,
          items: { create: items },
        },
      });
    }
  }
  console.log(`Demo orders upserted: ${scenarios.length}`);
}

async function seedSupport(userId: string) {
  const tickets = [
    {
      subject: 'Вопрос по доставке',
      message: 'Подскажите среднее время доставки по центру?',
      status: SupportStatus.CLOSED,
      reply: 'Обычно 40–60 минут. Спасибо, что выбрали Salmonz!',
    },
    {
      subject: 'Состав Филадельфии',
      message: 'Есть ли кунжут в классической Филадельфии?',
      status: SupportStatus.IN_PROGRESS,
      reply: 'В классическом рецепте кунжута нет. Можем добавить по просьбе.',
    },
    {
      subject: 'Промокод',
      message: 'Как активировать акцию «2 ролла по цене 1»?',
      status: SupportStatus.NEW,
      reply: null,
    },
  ];

  for (const t of tickets) {
    let row = await prisma.supportMessage.findFirst({
      where: { userId, subject: t.subject },
    });
    if (row) {
      row = await prisma.supportMessage.update({
        where: { id: row.id },
        data: { message: t.message, status: t.status },
      });
      await prisma.supportReply.deleteMany({ where: { messageId: row.id } });
    } else {
      row = await prisma.supportMessage.create({
        data: {
          userId,
          subject: t.subject,
          message: t.message,
          status: t.status,
        },
      });
    }
    if (t.reply) {
      await prisma.supportReply.create({
        data: {
          messageId: row.id,
          authorUserId: null,
          body: t.reply,
          isStaff: true,
        },
      });
    }
  }
  console.log(`Support tickets upserted: ${tickets.length}`);
}

async function main() {
  console.log(`ASSETS_ROOT=${assetsRoot}`);
  console.log(`DEMO_ROOT=${demoRoot}`);
  await upsertAdmin();
  const demo = await upsertDemoUser();
  await seedDemoAddresses(demo.id);
  await seedCatalog();
  await seedDemoOrders(demo.id);
  await seedSupport(demo.id);
  const userEmail = (process.env.DEMO_USER_EMAIL?.trim() || 't@test.ru').toLowerCase();
  const userPass = process.env.DEMO_USER_PASSWORD || '12345678';
  const adminEmail = (process.env.ADMIN_EMAIL?.trim() || 'admin@example.com').toLowerCase();
  const adminPass = process.env.ADMIN_PASSWORD || 'ChangeMeAdmin123!';
  console.log('Seed complete — local demo catalog, orders and support are ready');
  console.log('Demo logins (local only):');
  console.log(`  USER  ${userEmail} / ${userPass}`);
  console.log(`  ADMIN ${adminEmail} / ${adminPass}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
