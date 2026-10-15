const express = require('express');
const cors = require('cors');
const nodemailer = require('nodemailer');

const app = express();
app.use(cors());
app.use(express.json());

const fs = require('fs');
const path = require('path');

// Load credentials safely from credentials.json (gitignored) or environment variables
let gmailUser = process.env.GMAIL_USER || process.env.gmail_user || process.env.Gmail_User;
let gmailPass = process.env.GMAIL_PASS || process.env.gmail_pass || process.env.Gmail_Pass;

// Clean up any extra spaces or quotes if pasted in Web UI
if (gmailUser) gmailUser = gmailUser.trim().replace(/^["']|["']$/g, '');
if (gmailPass) gmailPass = gmailPass.trim().replace(/^["']|["']$/g, '').replace(/\s+/g, '');

let resendApiKey = process.env.RESEND_API_KEY;
let brevoApiKey = process.env.BREVO_API_KEY || process.env.brevo_api_key;

const credsPath = path.join(__dirname, 'credentials.json');
if (fs.existsSync(credsPath)) {
  try {
    const creds = JSON.parse(fs.readFileSync(credsPath, 'utf8'));
    gmailUser = gmailUser || creds.user;
    gmailPass = gmailPass || creds.pass;
    resendApiKey = resendApiKey || creds.resendApiKey;
    brevoApiKey = brevoApiKey || creds.brevoApiKey;
  } catch (err) {
    console.warn('[Credentials Warning] Could not parse credentials.json:', err.message);
  }
}

// Configure official Gmail SMTP transporter with Google App Password on Port 587 (STARTTLS)
const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  requireTLS: true,
  connectionTimeout: 5000,
  greetingTimeout: 5000,
  socketTimeout: 8000,
  auth: {
    user: gmailUser,
    pass: gmailPass
  }
});

// Verify connection configuration
if (gmailUser && gmailPass) {
  transporter.verify(function (error, success) {
    if (error) {
      console.warn('[SMTP Transporter Notice] Direct SMTP not available on this network (ports may be blocked). HTTPS fallback will be used.');
    } else {
      console.log(`[SMTP Ready] Google Mail Server connected for ${gmailUser}`);
    }
  });
}

app.post('/send-otp', async (req, res) => {
  if (!brevoApiKey && (!gmailUser || !gmailPass)) {
    return res.status(500).json({
      error: 'Mail relay missing BREVO_API_KEY or GMAIL_USER/GMAIL_PASS environment variables.'
    });
  }

  const { to, code } = req.body;
  if (!to || !code) {
    return res.status(400).json({ error: 'Missing required fields: to or code' });
  }

  const mailOptions = {
    from: `"ISUFST Campus Gate Security" <${gmailUser || 'noreply@isufst.edu.ph'}>`,
    to: to,
    subject: `[${code}] Your ISUFST Campus Pass Verification Code`,
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 14px; background: #ffffff;">
        <div style="background: linear-gradient(135deg, #1e3a8a, #2563eb); padding: 24px; border-radius: 10px; text-align: center; color: #ffffff;">
          <h2 style="margin: 0; font-size: 20px; font-weight: 800;">ISUFST CAMPUS GATE SECURITY</h2>
          <p style="margin: 6px 0 0 0; font-size: 13px; opacity: 0.9;">Plakado Automatic License Plate Recognition System</p>
        </div>
        <div style="padding: 28px 12px; text-align: center;">
          <p style="color: #475569; font-size: 14px; line-height: 1.6; margin-bottom: 20px;">
            You requested a verification code to access your <strong>ISUFST Campus Vehicle Pass</strong> account. Use this one-time security code to verify your sign-in:
          </p>
          <div style="display: inline-block; background: #f1f5f9; padding: 18px 32px; border-radius: 12px; border: 2px dashed #cbd5e1; margin: 12px 0 20px 0;">
            <span style="font-family: 'Courier New', Courier, monospace; font-size: 34px; font-weight: 800; letter-spacing: 8px; color: #1e3a8a;">${code}</span>
          </div>
          <p style="color: #64748b; font-size: 12px; line-height: 1.5;">
            • This verification code will expire in <strong>60 seconds</strong>.<br>
            • Never share this code with anyone. Campus security officers will never ask for your code.
          </p>
        </div>
        <div style="border-top: 1px solid #e2e8f0; padding-top: 16px; text-align: center; font-size: 11px; color: #94a3b8;">
          Iloilo State University of Fisheries Science and Technology (ISUFST)<br>
          Management Information System (MIS) • Campus Security Gate Division
        </div>
      </div>
    `
  };

  // 1. Try Brevo HTTPS API (Recommended for Cloud Hosting like Render - NEVER blocked by port restrictions)
  if (brevoApiKey) {
    try {
      const senderEmail = gmailUser || 'osiallj@gmail.com';
      const brevoRes = await fetch('https://api.brevo.com/v3/smtp/email', {
        method: 'POST',
        headers: {
          'api-key': brevoApiKey.trim(),
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          sender: {
            name: 'ISUFST Campus Gate Security',
            email: senderEmail
          },
          to: [{ email: to }],
          subject: mailOptions.subject,
          htmlContent: mailOptions.html
        })
      });
      const brevoData = await brevoRes.json();
      if (brevoRes.ok) {
        console.log(`[BREVO HTTPS SUCCESS] Delivered to ${to}: ${brevoData.messageId}`);
        return res.json({ success: true, messageId: brevoData.messageId, provider: 'brevo_https' });
      } else {
        console.warn('[BREVO ERROR]:', brevoData);
      }
    } catch (brevoErr) {
      console.warn('[BREVO FETCH ERROR]:', brevoErr.message);
    }
  }

  // 2. Try Direct Gmail SMTP (Works on Local PC / Unblocked environments)
  if (gmailUser && gmailPass) {
    try {
      const info = await transporter.sendMail(mailOptions);
      console.log(`[SMTP SUCCESS] Verification code ${code} sent to ${to}: ${info.messageId}`);
      return res.json({ success: true, messageId: info.messageId, provider: 'gmail_smtp' });
    } catch (err) {
      console.warn(`[SMTP NOTICE] Direct SMTP delivery failed/timed out (${err.message}). Trying Resend fallback...`);
    }
  }

  // 3. Try Resend HTTPS API fallback
  if (resendApiKey) {
    try {
      const resendRes = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${resendApiKey.trim()}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          from: 'ISUFST Gate Security <onboarding@resend.dev>',
          to: [to],
          subject: mailOptions.subject,
          html: mailOptions.html
        })
      });
      const resendData = await resendRes.json();
      if (resendRes.ok) {
        console.log(`[HTTPS RESEND SUCCESS] Delivered to ${to}: ${resendData.id}`);
        return res.json({ success: true, messageId: resendData.id, provider: 'resend_https' });
      } else {
        console.error('[HTTPS RESEND ERROR]:', resendData);
      }
    } catch (fetchErr) {
      console.error('[HTTPS FETCH ERROR]:', fetchErr);
    }
  }

  res.status(500).json({ error: 'All email delivery providers failed or timed out.' });
});

app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    service: 'Plakado ISUFST Mail Relay',
    hasBrevo: Boolean(brevoApiKey),
    hasGmail: Boolean(gmailUser && gmailPass),
    hasResend: Boolean(resendApiKey),
    connected: Boolean(brevoApiKey || (gmailUser && gmailPass)),
    userEmail: gmailUser ? `${gmailUser.substring(0, 3)}***@gmail.com` : null
  });
});

const PORT = process.env.PORT || 5050;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Plakado Gmail & Brevo Mail Relay active on port ${PORT}`);
});
