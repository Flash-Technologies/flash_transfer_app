package com.example.flash_transfer_app

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.flash_transfer_app.wallet_channel"
    private val TAG = "FlashTransferWallet"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "launchWallet" -> {
                        val walletId = call.argument<String>("wallet_id")
                        val walletPackage = call.argument<String>("wallet_package")
                        val walletScheme = call.argument<String>("wallet_scheme")
                        val params = call.argument<String>("params")
                        
                        Log.d(TAG, "Launch wallet request - ID: $walletId, Package: $walletPackage")
                        
                        val success = launchWalletWithEnhancedProtocol(
                            walletId, walletPackage, walletScheme, params
                        )
                        result.success(success)
                    }
                    "checkWalletInstalled" -> {
                        val packageName = call.argument<String>("package_name")
                        val isInstalled = isWalletInstalled(packageName)
                        result.success(isInstalled)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun launchWalletWithEnhancedProtocol(
        walletId: String?,
        walletPackage: String?,
        walletScheme: String?,
        params: String?
    ): Boolean {
        return try {
            Log.d(TAG, "Attempting to launch wallet: $walletId with package: $walletPackage")
            
            when (walletId) {
                "metamask" -> launchMetaMaskWithProperProtocol(walletPackage, params)
                "trust" -> launchTrustWalletWithProperProtocol(walletPackage, params)
                "phantom" -> launchPhantomWithProperProtocol(walletPackage, params)
                "coinbase" -> launchCoinbaseWithProperProtocol(walletPackage, params)
                else -> launchGenericWallet(walletPackage, walletScheme, params)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error launching wallet: ${e.message}")
            false
        }
    }

    private fun launchMetaMaskWithProperProtocol(packageName: String?, params: String?): Boolean {
        Log.d(TAG, "Launching MetaMask with specialized format")
        
        // Method 1: Try WalletConnect format if params contain WC URI
        if (params?.contains("wc:") == true) {
            val wcUri = extractWcUriFromParams(params)
            if (wcUri != null) {
                val wcIntent = Intent(Intent.ACTION_VIEW, Uri.parse("metamask://wc?uri=${Uri.encode(wcUri)}"))
                if (canLaunchIntent(wcIntent)) {
                    startActivity(wcIntent)
                    Log.d(TAG, "MetaMask launched with WalletConnect URI")
                    return true
                }
            }
        }

        // Method 2: Try dApp connection format
        val dappIntent = Intent(Intent.ACTION_VIEW, Uri.parse("metamask://dapp/flash.closedsource.in"))
        if (canLaunchIntent(dappIntent)) {
            startActivity(dappIntent)
            Log.d(TAG, "MetaMask launched with dApp format")
            return true
        }

        // Method 3: Try package launch
        if (packageName != null) {
            return launchAppByPackage(packageName)
        }

        Log.w(TAG, "All MetaMask launch methods failed")
        return false
    }

    private fun launchTrustWalletWithProperProtocol(packageName: String?, params: String?): Boolean {
        Log.d(TAG, "Launching Trust Wallet with enhanced format")
        
        // Method 1: Try WalletConnect format
        if (params?.contains("wc:") == true) {
            val wcUri = extractWcUriFromParams(params)
            if (wcUri != null) {
                val wcIntent = Intent(Intent.ACTION_VIEW, Uri.parse("trust://wc?uri=${Uri.encode(wcUri)}"))
                if (canLaunchIntent(wcIntent)) {
                    startActivity(wcIntent)
                    Log.d(TAG, "Trust Wallet launched with WalletConnect URI")
                    return true
                }
            }
        }

        // Method 2: Try deep link format
        val deepLinkIntent = Intent(Intent.ACTION_VIEW, Uri.parse("trust://open_url?coin_id=60&url=${Uri.encode("https://flash.closedsource.in")}"))
        if (canLaunchIntent(deepLinkIntent)) {
            startActivity(deepLinkIntent)
            Log.d(TAG, "Trust Wallet launched with deep link format")
            return true
        }

        // Method 3: Try package launch
        if (packageName != null) {
            return launchAppByPackage(packageName)
        }

        return false
    }

    private fun launchPhantomWithProperProtocol(packageName: String?, params: String?): Boolean {
        Log.d(TAG, "Launching Phantom with v1/connect API")
        
        // Method 1: Try v1/connect format (triggers proper connection prompt)
        val connectIntent = Intent(Intent.ACTION_VIEW, Uri.parse("phantom://v1/connect?app_url=${Uri.encode("https://flash.closedsource.in")}&redirect_link=${Uri.encode("flashtransferapp://connect")}"))
        if (canLaunchIntent(connectIntent)) {
            startActivity(connectIntent)
            Log.d(TAG, "Phantom launched with v1/connect API")
            return true
        }

        // Method 2: Try WalletConnect format
        if (params?.contains("wc:") == true) {
            val wcUri = extractWcUriFromParams(params)
            if (wcUri != null) {
                val wcIntent = Intent(Intent.ACTION_VIEW, Uri.parse("phantom://wc?uri=${Uri.encode(wcUri)}"))
                if (canLaunchIntent(wcIntent)) {
                    startActivity(wcIntent)
                    Log.d(TAG, "Phantom launched with WalletConnect URI")
                    return true
                }
            }
        }

        // Method 3: Try package launch
        if (packageName != null) {
            return launchAppByPackage(packageName)
        }

        return false
    }

    private fun launchCoinbaseWithProperProtocol(packageName: String?, params: String?): Boolean {
        Log.d(TAG, "Launching Coinbase Wallet")
        
        // Method 1: Try WalletConnect format
        if (params?.contains("wc:") == true) {
            val wcUri = extractWcUriFromParams(params)
            if (wcUri != null) {
                val wcIntent = Intent(Intent.ACTION_VIEW, Uri.parse("cbwallet://wc?uri=${Uri.encode(wcUri)}"))
                if (canLaunchIntent(wcIntent)) {
                    startActivity(wcIntent)
                    Log.d(TAG, "Coinbase launched with WalletConnect URI")
                    return true
                }
            }
        }

        // Method 2: Try dApp format
        val dappIntent = Intent(Intent.ACTION_VIEW, Uri.parse("cbwallet://dapp?cb_url=${Uri.encode("https://flash.closedsource.in")}"))
        if (canLaunchIntent(dappIntent)) {
            startActivity(dappIntent)
            Log.d(TAG, "Coinbase launched with dApp format")
            return true
        }

        // Method 3: Try package launch
        if (packageName != null) {
            return launchAppByPackage(packageName)
        }

        return false
    }

    private fun launchGenericWallet(packageName: String?, scheme: String?, params: String?): Boolean {
        // Try WalletConnect format first
        if (params?.contains("wc:") == true && scheme != null) {
            val wcUri = extractWcUriFromParams(params)
            if (wcUri != null) {
                val wcIntent = Intent(Intent.ACTION_VIEW, Uri.parse("${scheme}wc?uri=${Uri.encode(wcUri)}"))
                if (canLaunchIntent(wcIntent)) {
                    startActivity(wcIntent)
                    return true
                }
            }
        }

        // Try package launch
        if (packageName != null) {
            return launchAppByPackage(packageName)
        }

        return false
    }

    private fun launchAppByPackage(packageName: String): Boolean {
        return try {
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            if (launchIntent != null) {
                // Add connection intent data
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                launchIntent.putExtra("action", "connect")
                launchIntent.putExtra("app", "Flash Transfer")
                launchIntent.putExtra("callback", "flashtransferapp://connect")
                
                startActivity(launchIntent)
                Log.d(TAG, "App launched via package: $packageName")
                return true
            } else {
                Log.w(TAG, "No launch intent found for package: $packageName")
                return false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error launching app by package: ${e.message}")
            false
        }
    }

    private fun extractWcUriFromParams(params: String): String? {
        return try {
            // Extract WalletConnect URI from params JSON
            val startIndex = params.indexOf("wc:")
            if (startIndex != -1) {
                val endIndex = params.indexOf("\"", startIndex)
                if (endIndex != -1) {
                    params.substring(startIndex, endIndex)
                } else {
                    params.substring(startIndex)
                }
            } else {
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting WC URI: ${e.message}")
            null
        }
    }

    private fun canLaunchIntent(intent: Intent): Boolean {
        return packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY).isNotEmpty()
    }

    private fun isWalletInstalled(packageName: String?): Boolean {
        if (packageName == null) return false
        
        return try {
            packageManager.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIncomingIntent(intent)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        intent?.let { handleIncomingIntent(it) }
    }

    private fun handleIncomingIntent(intent: Intent) {
        val data = intent.data
        if (data != null) {
            Log.d(TAG, "Received deep link: $data")
            
            // Forward deep link to Flutter through method channel
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod("handleDeepLink", data.toString())
            }
        }
    }
}