const express = require('express');
const cors = require('cors');
const nodemailer = require('nodemailer');

const app = express();
app.use(cors());
app.use(express.json());

const fs = require('fs');
const path = require('path');

// Load credentials safely from credentials.json (gitignored) or environment variables
let gmailUser = process.env.GMAIL_USER;
let gmailPass = process.env.GMAIL_PASS;

const credsPath = path.join(__dirname, 'credentials.json');
if (fs.existsSync(credsPath)) {
  try {
    const creds = JSON.parse(fs.readFileSync(credsPath, 'utf8'));
    gmailUser = gmailUser || creds.user;
    gmailPass = gmailPass || creds.pass;
  } catch (err) {
    console.warn('[Credentials Warning] Could not parse credentials.json:', err.message);
  }
}

// Configure official Gmail SMTP transporter with Google App Password
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: gmailUser,
    pass: gmailPass
  }
});

// Verify connection configuration
if (gmailUser && gmailPass) {
  transporter.verify(function (error, success) {
    if (error) {
      console.error('[SMTP Transporter Error]:', error);
    } else {
      console.log(`[SMTP Ready] Google Mail Server connected for ${gmailUser}`);
    }
  });
} else {
  console.warn('[SMTP Warning] No Gmail credentials found. Please provide server/credentials.json or GMAIL_USER/GMAIL_PASS.');
}

app.post('/send-otp', async (req, res) => {
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

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log(`[SMTP SUCCESS] Verification code ${code} sent to ${to}: ${info.messageId}`);
    res.json({ success: true, messageId: info.messageId });
  } catch (err) {
    console.error(`[SMTP ERROR] Delivery failed to ${to}:`, err);
    res.status(500).json({ error: err.toString() });
  }
});

const PORT = 5050;
app.listen(PORT, () => {
  console.log(`Plakado Gmail SMTP Relay active on http://localhost:${PORT}`);
});
