# Email Notifications

Agent DVR supports automated email notifications when motion, sound, or system alerts occur.
**Note**: Native email sending may require an active iSpyConnect Pro license depending on your chosen delivery method.

## Setup Instructions

1. Define your SMTP configuration using the `.env.pro` file.
2. Ensure you only use **placeholders** in your repository. Do NOT commit your real SMTP passwords, tokens, or app passwords.
3. Example `.env.pro` values:
   ```env
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=your_email@gmail.com
   SMTP_PASSWORD=your_app_password_placeholder
   ```
4. Restart your stack and configure the Agent DVR web interface (Server Settings -> SMTP) with the matching variables.
5. In the Agent DVR UI, define **Actions** for your cameras that trigger "Send Email" on Motion Detected or Alert.
