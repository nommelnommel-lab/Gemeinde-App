import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors({
    origin: (origin, callback) => {
      if (!origin) {
        callback(null, true);
        return;
      }

      try {
        const url = new URL(origin);
        if (url.hostname === 'localhost' || url.hostname === '10.0.2.2') {
          callback(null, true);
          return;
        }
      } catch {
        // ignore parse errors
      }

      callback(new Error('Origin nicht erlaubt'), false);
    },
  });
  const port = process.env.PORT ? Number(process.env.PORT) : 3000;
  await app.listen(port);
}

bootstrap();
