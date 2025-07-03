# YouTube API Setup Guide

## 🔑 Getting Your YouTube Data API v3 Key

### Step 1: Google Cloud Console Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Click "Select Project" at the top

### Step 2: Enable YouTube Data API v3
1. In the left sidebar, go to **APIs & Services** > **Library**
2. Search for "YouTube Data API v3"
3. Click on it and press **Enable**

### Step 3: Create API Key
1. Go to **APIs & Services** > **Credentials**
2. Click **+ CREATE CREDENTIALS** > **API Key**
3. Copy the generated API key
4. (Optional) Click **Restrict Key** to add restrictions for security

### Step 4: Configure Your App
1. Open `YTApp/Config.swift`
2. Replace `"YOUR_YOUTUBE_API_KEY_HERE"` with your actual API key:

```swift
static let youtubeAPIKey = "AIzaSyC-your-actual-api-key-here"
```

### Step 5: Test the Integration
1. Build and run the app
2. Go to the **Debug** tab
3. Test channel fetching with a YouTube channel URL
4. Check the debug output for any errors

## 🚨 Important Notes

### API Quotas
- YouTube Data API v3 has daily quotas
- Default quota: 10,000 units per day
- Channel search: ~100 units per request
- Video listing: ~1-5 units per video

### Security Best Practices
1. **Restrict your API key** in Google Cloud Console:
   - Add HTTP referrer restrictions for web apps
   - Add iOS bundle ID restrictions for mobile apps
2. **Never commit API keys** to version control
3. Consider using environment variables for production

### Common Issues
1. **"API key missing" error**: Check Config.swift has the correct key
2. **"Quota exceeded" error**: You've hit the daily limit
3. **"Invalid response" error**: Check network connection and API key validity
4. **"Channel not found" error**: Verify the YouTube channel URL is correct

## 🧪 Testing Channels

Good test channels for development:
- `https://www.youtube.com/@mkbhd` (MKBHD)
- `https://www.youtube.com/@veritasium` (Veritasium)  
- `https://www.youtube.com/@3blue1brown` (3Blue1Brown)

## 📊 Monitoring Usage

Monitor your API usage in Google Cloud Console:
1. Go to **APIs & Services** > **Dashboard**
2. Click on **YouTube Data API v3**
3. View quotas and usage statistics

## 🔧 Troubleshooting

If you're still having issues:
1. Check the Debug tab in the app
2. Look at Xcode console for error messages
3. Verify API key permissions in Google Cloud Console
4. Test API key with a simple curl request:

```bash
curl "https://www.googleapis.com/youtube/v3/channels?part=snippet&forUsername=mkbhd&key=YOUR_API_KEY"
```
