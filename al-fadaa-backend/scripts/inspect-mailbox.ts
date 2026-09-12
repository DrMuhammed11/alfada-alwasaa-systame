import { ImapFlow } from 'imapflow';
import * as dotenv from 'dotenv';
dotenv.config();

async function check() {
  const client = new ImapFlow({
    host: process.env.IMAP_HOST!,
    port: parseInt(process.env.IMAP_PORT || '993', 10),
    secure: true,
    auth: {
      user: process.env.IMAP_USER!,
      pass: process.env.IMAP_PASS!,
    },
    logger: false,
  });

  await client.connect();
  const lock = await client.getMailboxLock('INBOX');
  try {
    const status = await client.status('INBOX', { messages: true, unseen: true, highestModseq: true });
    console.log('📬 إجمالي الرسائل في INBOX:', status.messages);

    const messages: any[] = [];
    for await (const msg of client.fetch('1:*', { envelope: true, uid: true, internalDate: true })) {
      const env = msg.envelope;
      messages.push({
        uid: msg.uid,
        date: env?.date,
        internalDate: msg.internalDate,
        from: env?.from?.[0]?.address,
        fromName: env?.from?.[0]?.name,
        subject: env?.subject,
        messageId: env?.messageId,
      });
    }

    console.log(`\n📋 عدد الرسائل المسحوبة: ${messages.length}`);
    messages.forEach((m) => {
      console.log(`[UID ${m.uid}] Date: ${m.date?.toISOString() || m.internalDate?.toISOString()} | From: ${m.from} (${m.fromName}) | Subject: ${m.subject}`);
    });
  } finally {
    lock.release();
    await client.logout();
  }
}

check().catch(console.error);
