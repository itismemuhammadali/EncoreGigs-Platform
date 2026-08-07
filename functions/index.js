const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Simple HTTP endpoint that receives OTP request from backend
 * Stores email task in Firestore
 */
exports.queueOtpEmail = async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { email, otp, uid } = req.body;

    if (!email || !otp || !uid) {
      res.status(400).json({ error: 'Missing email, otp, or uid' });
      return;
    }

    // Store email task - this can be processed by another Cloud Function or external service
    await admin.firestore().collection('email_tasks').add({
      to: email,
      subject: 'OnlyGigz - Your Verification Code',
      html: `
      <html>
        <body style="font-family: Arial; background-color: #f0f0f0; padding: 20px;">
          <div style="max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px;">
            <h1 style="text-align: center; color: #0A0A0F;">🎵 OnlyGigz</h1>
            <p style="text-align: center; color: #999;">Where Music Meets Opportunity</p>
            <hr style="border: none; border-top: 1px solid #ddd;">
            <h2 style="color: #333;">Email Verification</h2>
            <p style="color: #666; font-size: 16px;">Your one-time verification code is:</p>
            <div style="background: #0A0A0F; color: #A1F301; padding: 30px; text-align: center; border-radius: 8px; margin: 30px 0;">
              <h1 style="font-size: 48px; letter-spacing: 8px; margin: 0; font-family: monospace;">${otp}</h1>
            </div>
            <p style="color: #666; font-size: 16px;">This code expires in <strong>10 minutes</strong>.</p>
            <p style="color: #666; font-size: 16px;">If you didn't request this, please ignore this email.</p>
            <hr style="border: none; border-top: 1px solid #ddd;">
            <p style="text-align: center; color: #999; font-size: 12px;">© 2025 OnlyGigz. All rights reserved.</p>
          </div>
        </body>
      </html>
      `,
      uid: uid,
      email: email,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending'
    });

    console.log(`✅ Email task queued for ${email}`);

    res.json({
      success: true,
      message: 'OTP email queued',
      email: email,
      otp: otp
    });
  } catch (error) {
    console.error('❌ Error:', error);
    res.status(500).json({ error: error.message });
  }
};
