# Welcome to YugTalk

## yugtalk_app background

A Filipino-based bilingual AAC app for pediatrics with speech and developmental disorders.

## setting up terminal-env variables

Set this up when VScode doesn't recognize environment variables set from PC:

1. Create dev folder to contain project in C:
2. Do the following:
    1. Download flutter, npm, nodejs, java (optional)
    2. Locate paths of such
3. On VSCode, follow these steps:

   - Navigate to:

     ```json
     File > Preferences > Settings
     ```

   - Search for settings and enter the following code if it doesn't exist in `settings.json`:

     ```json
     "terminal.integrated.env.windows": {
         "PATH": "C:\\dev\\flutter\\bin;C:\\Program Files\\Git\\bin;C:\\dev\\flutter\\bin\\cache\\dart-sdk\\bin;C:\\Users\\*user*\\AppData\\Local\\Pub\\Cache\\bin;C:\\Users\\*user*\\AppData\\Roaming\\npm;C:\\Program Files\\nodejs;C:\\WINDOWS\\system32;C:\\Users\\*user*\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\Windows PowerShell;C:\\Program Files\\Java\\jdk-11\\bin"
     }
     ```
