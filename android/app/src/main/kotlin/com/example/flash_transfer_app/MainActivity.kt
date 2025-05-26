package com.example.flash_transfer_app

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val WALLET_CHANNEL = "com.flash_transfer_app.wallet_channel"
    private val TAG = "FlashTransferWallet"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WALLET_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isPackageInstalled" -> {
                    val packageName = call.argument<String>("package_name")
                    if (packageName != null) {
                        val isInstalled = isPackageInstalled(packageName)
                        Log.d(TAG, "Package $packageName installed: $isInstalled")
                        result.success(isInstalled)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                
                "launchWallet" -> {
                    val walletId = call.argument<String>("wallet_id")
                    val walletPackage = call.argument<String>("wallet_package")
                    val walletScheme = call.argument<String>("wallet_scheme")
                    val params = call.argument<String>("params")
                    
                    Log.d(TAG, "Launch wallet request - ID: $walletId, Package: $walletPackage")
                    
                    if (walletId != null && walletPackage != null && walletScheme != null) {
                        val launched = launchWalletApp(walletId, walletPackage, walletScheme, params)
                        result.success(launched)
                    } else {
                        result.error("INVALID_ARGUMENT", "Required wallet parameters missing", null)
                    }
                }
                
                "handleDeepLink" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        Log.d(TAG, "Handling deep link: $uriString")
                        // Notify Flutter about the deep link
                        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WALLET_CHANNEL)
                            .invokeMethod("handleDeepLink", uriString)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "URI is required", null)
                    }
                }
                
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIncomingIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        // Handle intent when app is resumed
        intent?.let { handleIncomingIntent(it) }
    }

    private fun handleIncomingIntent(intent: Intent) {
        if (intent.action == Intent.ACTION_VIEW && intent.data != null) {
            val uri = intent.data.toString()
            Log.d(TAG, "Received deep link: $uri")
            
            // Notify Flutter about the deep link
            try {
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, WALLET_CHANNEL).invokeMethod("handleDeepLink", uri)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error sending deep link to Flutter: ${e.message}")
            }
        }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
            Log.d(TAG, "Package $packageName found via PackageManager")
            true
        } catch (e: PackageManager.NameNotFoundException) {
            Log.d(TAG, "Package $packageName not found: ${e.message}")
            false
        } catch (e: Exception) {
            Log.e(TAG, "Error checking package $packageName: ${e.message}")
            false
        }
    }

    private fun launchWalletApp(walletId: String, packageName: String, scheme: String, params: String?): Boolean {
        Log.d(TAG, "Attempting to launch wallet: $walletId with package: $packageName")
        
        return try {
            when (walletId) {
                "metamask" -> launchMetaMask(packageName, params)
                "trust" -> launchTrustWallet(packageName, params)
                "phantom" -> launchPhantom(packageName, params)
                "coinbase" -> launchCoinbase(packageName, params)
                "binance" -> launchBinance(packageName, params)
                else -> launchGenericWallet(packageName, scheme, params)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error launching wallet $walletId: ${e.message}")
            false
        }
    }

    private fun launchMetaMask(packageName: String, params: String?): Boolean {
        Log.d(TAG, "Launching MetaMask with specialized format")
        
        // Primary format: dApp connection that should trigger address sharing
        val dappUri = "metamask://dapp/flashtransfer.app?address_request=true&callback=flashtransferapp://connect&app_name=Flash%20Transfer"
        
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(dappUri))
            intent.setPackage(packageName)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            startActivity(intent)
            Log.d(TAG, "MetaMask launched successfully with dApp format")
            true
        } catch (e: Exception) {
            Log.w(TAG, "MetaMask dApp launch failed: ${e.message}, trying fallback")
            
            // Fallback 1: Simple dApp format
            try {
                val fallbackUri = "metamask://dapp/flashtransfer.app"
                val fallbackIntent = Intent(Intent.ACTION_VIEW, Uri.parse(fallbackUri))
                fallbackIntent.setPackage(packageName)
                fallbackIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(fallbackIntent)
                Log.d(TAG, "MetaMask launched with fallback format")
                true
            } catch (e2: Exception) {
                Log.w(TAG, "MetaMask fallback failed: ${e2.message}, trying minimal launch")
                
                // Fallback 2: Just open MetaMask
                launchAppDirectly(packageName)
            }
        }
    }

    private fun launchTrustWallet(packageName: String, params: String?): Boolean {
        Log.d(TAG, "Launching Trust Wallet")
        
        val callbackUrl = "flashtransferapp://connect"
        val connectUrl = "https://flashtransfer.app/connect?callback=${java.net.URLEncoder.encode(callbackUrl, "UTF-8")}&params=${java.net.URLEncoder.encode(params ?: "", "UTF-8")}"
        val trustUri = "trust://open_url?url=${java.net.URLEncoder.encode(connectUrl, "UTF-8")}"

        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(trustUri))
            intent.setPackage(packageName)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            Log.d(TAG, "Trust Wallet launched successfully")
            true
        } catch (e: Exception) {
            Log.w(TAG, "Trust Wallet launch failed: ${e.message}, trying direct launch")
            launchAppDirectly(packageName)
        }
    }

    private fun launchPhantom(packageName: String, params: String?): Boolean {
        Log.d(TAG, "Launching Phantom Wallet")
        
        val callbackUrl = "flashtransferapp://connect"
        val phantomUri = "phantom://connect?ref=${java.net.URLEncoder.encode(callbackUrl, "UTF-8")}&app=Flash%20Transfer&redirect=${java.net.URLEncoder.encode(callbackUrl, "UTF-8")}"

        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(phantomUri))
            intent.setPackage(packageName)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            Log.d(TAG, "Phantom Wallet launched successfully")
            true
        } catch (e: Exception) {
            Log.w(TAG, "Phantom launch failed: ${e.message}, trying direct launch")
            launchAppDirectly(packageName)
        }
    }

    private fun launchCoinbase(packageName: String, params: String?): Boolean {
        Log.d(TAG, "Launching Coinbase Wallet")
        
        val callbackUrl = "flashtransferapp://connect"
        val coinbaseUri = "cbwallet://dapp/flashtransfer.app?callback=${java.net.URLEncoder.encode(callbackUrl, "UTF-8")}"

        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(coinbaseUri))
            intent.setPackage(packageName)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            Log.d(TAG, "Coinbase Wallet launched successfully")
            true
        } catch (e: Exception) {
            Log.w(TAG, "Coinbase launch failed: ${e.message}, trying direct launch")
            launchAppDirectly(packageName)
        }
    }

    private fun launchBinance(packageName: String, params: String?): Boolean {
        Log.d(TAG, "Launching Binance Wallet")
        
        val callbackUrl = "flashtransferapp://connect"
        val binanceUri = "bnc://dapp?url=${java.net.URLEncoder.encode("https://flashtransfer.app/connect?callback=$callbackUrl", "UTF-8")}"

        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(binanceUri))
            intent.setPackage(packageName)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            Log.d(TAG, "Binance Wallet launched successfully")
            true
        } catch (e: Exception) {
            Log.w(TAG, "Binance launch failed: ${e.message}, trying direct launch")
            launchAppDirectly(packageName)
        }
    }

    private fun launchGenericWallet(packageName: String, scheme: String, params: String?): Boolean {
        Log.d(TAG, "Launching generic wallet with scheme: $scheme")
        
        val callbackUrl = "flashtransferapp://connect"
        val genericUri = "${scheme}connect?callback=${java.net.URLEncoder.encode(callbackUrl, "UTF-8")}&params=${java.net.URLEncoder.encode(params ?: "", "UTF-8")}"

        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(genericUri))
            intent.setPackage(packageName)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            Log.d(TAG, "Generic wallet launched successfully")
            true
        } catch (e: Exception) {
            Log.w(TAG, "Generic wallet launch failed: ${e.message}, trying direct launch")
            launchAppDirectly(packageName)
        }
    }

    private fun launchAppDirectly(packageName: String): Boolean {
        return try {
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            intent?.let {
                it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                startActivity(it)
                Log.d(TAG, "App launched directly: $packageName")
                true
            } ?: run {
                Log.e(TAG, "Could not get launch intent for $packageName")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error launching app directly: ${e.message}")
            false
        }
    }
}