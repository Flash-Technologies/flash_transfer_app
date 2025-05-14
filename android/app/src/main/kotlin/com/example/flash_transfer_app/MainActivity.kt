package com.example.flash_transfer_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.flash_transfer_app.wallet_channel"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchWallet" -> {
                    try {
                        // Get wallet details from the method call arguments
                        val walletId = call.argument<String>("wallet_id")
                        val walletPackage = call.argument<String>("wallet_package")
                        val walletScheme = call.argument<String>("wallet_scheme")
                        val paramsObj = call.argument<Any>("params")

                        if (walletId == null || walletPackage == null || walletScheme == null) {
                            result.error("INVALID_ARGUMENTS", "Missing required wallet parameters", null)
                            return@setMethodCallHandler
                        }

                        // Convert params to JSON string if it's not already a string
                        var paramsString = ""
                        if (paramsObj is String) {
                            paramsString = paramsObj
                        } else if (paramsObj != null) {
                            paramsString = paramsObj.toString()
                        }

                        // Launch wallet with deep link
                        val launched = launchWalletApp(walletId, walletPackage, walletScheme, paramsString)
                        result.success(launched)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error launching wallet: ${e.message}", e)
                        result.error("LAUNCH_ERROR", "Error launching wallet: ${e.message}", null)
                    }
                }
                "isPackageInstalled" -> {
                    try {
                        val packageName = call.argument<String>("package_name")
                        if (packageName == null) {
                            result.error("INVALID_ARGUMENTS", "Missing package name", null)
                            return@setMethodCallHandler
                        }

                        val isInstalled = isPackageInstalled(packageName, packageManager)
                        result.success(isInstalled)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error checking package: ${e.message}", e)
                        result.error("PACKAGE_CHECK_ERROR", "Error checking package: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun launchWalletApp(walletId: String, walletPackage: String, walletScheme: String, params: String): Boolean {
        Log.d(TAG, "Attempting to launch wallet: $walletId")
        Log.d(TAG, "Params: $params")

        // Check if the wallet app is installed
        val isInstalled = isPackageInstalled(walletPackage, packageManager)

        if (!isInstalled) {
            Log.d(TAG, "Wallet app not installed: $walletPackage")
            return false
        }

        try {
            // Try to construct a deep link URI based on wallet type
            var uri: Uri? = null

            // Different wallets have different deep link formats
            when (walletId) {
                "metamask" -> {
                    // Try multiple MetaMask deep link formats to trigger the connection dialog
                    try {
                        // Format 1: WalletConnect format (most reliable for newer versions)
                        val wcUri = "metamask://wc?uri=wc:00000000-0000-0000-0000-000000000000@1?bridge=https://flashtransfer.app&key=12345"
                        Log.d(TAG, "Trying WalletConnect format: $wcUri")
                        uri = Uri.parse(wcUri)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error with WalletConnect format: ${e.message}")
                        
                        try {
                            // Format 2: Direct dapp format
                            val directUri = "${walletScheme}dapp/https://flashtransfer.app"
                            Log.d(TAG, "Trying direct dapp format: $directUri")
                            uri = Uri.parse(directUri)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error with direct format: ${e.message}")
                            
                            try {
                                // Format 3: Chain-specific format
                                val chainUri = "${walletScheme}dapp/https://flashtransfer.app?chainId=1"
                                Log.d(TAG, "Trying with chainId: $chainUri")
                                uri = Uri.parse(chainUri)
                            } catch (e: Exception) {
                                Log.e(TAG, "Error with chain format: ${e.message}")
                                
                                // Minimal fallback
                                val minimalUri = "${walletScheme}dapp"
                                Log.d(TAG, "Trying minimal URI: $minimalUri")
                                uri = Uri.parse(minimalUri)
                            }
                        }
                    }
                }
                "trust" -> {
                    // Trust Wallet format - may need specific parameters
                    uri = Uri.parse("${walletScheme}open_url?url=${Uri.encode("https://flashtransfer.app/connect?params=${Uri.encode(params)}")}")
                }
                "phantom" -> {
                    // Phantom format for Solana wallet
                    uri = Uri.parse("${walletScheme}connect?params=${Uri.encode(params)}")
                }
                else -> {
                    // Default format
                    uri = Uri.parse("${walletScheme}connect?params=${Uri.encode(params)}")
                }
            }

            if (uri != null) {
                val intent = Intent(Intent.ACTION_VIEW, uri)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

                // Add package explicitly to ensure it opens the right app
                intent.setPackage(walletPackage)

                // Try to launch the wallet app
                startActivity(intent)
                Log.d(TAG, "Successfully launched wallet: $walletId with URI: ${uri}")
                return true
            }

            return false
        } catch (e: Exception) {
            Log.e(TAG, "Error launching wallet app: ${e.message}", e)
            return false
        }
    }

    private fun isPackageInstalled(packageName: String, packageManager: PackageManager): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Handle incoming intents (for deep link handling)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null || intent.data == null) {
            return
        }

        // Get the URI from the intent
        val uri = intent.data
        Log.d(TAG, "Received deep link: $uri")

        // Extract wallet address and other params for better debugging
        try {
            var address = uri?.getQueryParameter("address")
            
            if (address != null) {
                Log.d(TAG, "Found wallet address in URI: $address")
            } else {
                // Try alternate parameter names that different wallets might use
                address = uri?.getQueryParameter("wallet_address")
                if (address != null) {
                    Log.d(TAG, "Found wallet_address in URI: $address")
                } else {
                    address = uri?.getQueryParameter("account")
                    if (address != null) {
                        Log.d(TAG, "Found account in URI: $address")
                    } else {
                        Log.d(TAG, "No wallet address found in URI parameters")

                        // Log all parameters for debugging
                        uri?.queryParameterNames?.forEach { key ->
                            Log.d(TAG, "URI parameter - $key: ${uri.getQueryParameter(key)}")
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting parameters from URI: ${e.message}", e)
        }

        // Process deep link - send to Flutter
        if (flutterEngine != null) {
            MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                .invokeMethod("handleDeepLink", uri.toString())
        }
    }
}
