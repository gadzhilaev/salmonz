import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import * as argon2 from 'argon2';
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
  const promo = await prisma.promotion.findFirst({ where: { title: promoTitle } });
  if (promo) {
    await prisma.promotion.update({
      where: { id: promo.id },
      data: {
        description: 'При заказе от 1500 ₽ доставка бесплатно',
        imageKey: 'promotions/free-delivery.webp',
        isActive: true,
        sortOrder: 1,
      },
    });
  } else {
    await prisma.promotion.create({
      data: {
        title: promoTitle,
        description: 'При заказе от 1500 ₽ доставка бесплатно',
        imageKey: 'promotions/free-delivery.webp',
        isActive: true,
        sortOrder: 1,
      },
    });
  }

  console.log('Catalog seed upserted');
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
