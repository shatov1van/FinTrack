// functions/api/test.ts

// Правильный тип для Cloudflare Pages Functions
interface Env {
  DATABASE_URL: string;
  S3_BUCKET_NAME: string;
  S3_REGION: string;
}

export async function onRequest(context: { env: Env }) {
  try {
    // @ts-ignore - игнорируем отсутствие типов для pg в Edge Runtime
    const { Client } = await import('pg');
    
    const client = new Client({ 
      connectionString: context.env.DATABASE_URL 
    });
    
    await client.connect();
    const res = await client.query('SELECT NOW() as server_time');
    await client.end();

    return new Response(JSON.stringify({ 
      status: 'ok', 
      db_time: res.rows[0].server_time,
      bucket: context.env.S3_BUCKET_NAME,
      region: context.env.S3_REGION
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Unknown error';
    return new Response(JSON.stringify({ error: message }), { 
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}