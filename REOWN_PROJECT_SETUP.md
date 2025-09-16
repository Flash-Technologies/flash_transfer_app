# 🔐 Reown Project Setup Guide

## ⚠️ IMPORTANT: You Need Your Own Project ID

The app is showing "Project not found" errors because you need to register your own project with Reown.

## 📝 Steps to Get Your Project ID:

### 1. Create Reown Account
1. Go to **[https://cloud.reown.com](https://cloud.reown.com)**
2. Click "Sign Up" or "Sign In"
3. Complete registration with your email

### 2. Create Your Project
1. Click **"New Project"** button
2. Fill in the details:
   - **Project Name**: Flash Transfer App
   - **Homepage URL**: https://flash-transfer.com (or your domain)
   - **Project Type**: Select "dApp"
   - **SDK**: Select "AppKit"
   - **Platform**: Select "Flutter"

### 3. Copy Your Project ID
1. After creation, you'll see your **Project ID** (32 characters)
2. It looks like: `abc123def456ghi789jkl012mno345pq`
3. Copy this ID

### 4. Update Your App
Replace the project ID in `/lib/core/services/reown_service.dart`:

```dart
// Line 10 - Replace with your actual project ID
static const String projectId = 'YOUR_PROJECT_ID_HERE';
```

Example:
```dart
static const String projectId = 'abc123def456ghi789jkl012mno345pq';
```

## 🔧 Optional: Configure Project Settings

In the Reown Dashboard, you can also:

### Configure Allowed Domains (for Universal Links)
1. Go to your project settings
2. Add allowed domains:
   - `flash-transfer.com`
   - `flashtransferapp://` (your deep link scheme)

### Set Up Analytics
1. Enable analytics to track wallet connections
2. Monitor usage and errors

### Configure Wallet Preferences
1. Set featured wallets (MetaMask, Trust, etc.)
2. Configure chain preferences (Ethereum, Polygon, BSC)

## 🧪 Testing Without Real Wallets

For testing in emulator without real wallets:

### Option 1: Use WalletConnect Test Wallet
1. Install from: https://github.com/WalletConnect/test-wallet
2. It's a test wallet for development

### Option 2: Install Real Wallets on Emulator
1. Download APKs:
   - MetaMask: https://metamask.io/download/
   - Trust Wallet: https://trustwallet.com/download
2. Drag APK to emulator to install

### Option 3: Test on Real Device
1. Install your app on a real phone
2. Install actual wallet apps
3. Test the complete flow

## ✅ Verification

After updating the Project ID, you should see:
- ✅ No more "Project not found" errors
- ✅ Modal opens with wallet options
- ✅ Events tracking works (optional)
- ✅ Wallet connection successful

## 🚨 Common Issues

### Still Getting "Project not found"
- Verify project ID is exactly 32 characters
- Check you copied it correctly (no spaces)
- Ensure project is active in dashboard

### 403 Forbidden Errors
- Normal if analytics is disabled
- Won't affect wallet connections
- Can be ignored for development

### No Wallets Showing
- Install wallet apps on device/emulator
- Check deep linking configuration
- Verify project settings in dashboard

## 📞 Support

- Reown Docs: https://docs.reown.com
- Support: https://reown.com/support
- Discord: https://discord.gg/reown

---

## 🎉 Once Set Up

Your app will:
1. Show available wallets in modal
2. Connect to user's wallet
3. Send transactions successfully
4. Track analytics (if enabled)

Remember: Each project gets 1,000 free connections per month, which is plenty for development!