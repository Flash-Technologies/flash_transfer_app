package com.flash_transfer_app;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.content.pm.PackageManager;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.flash_transfer_app.wallet_channel";
    private static final String TAG = "MainActivity";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    if (call.method.equals("launchWallet")) {
                        try {
                            // Get wallet details from the method call arguments
                            String walletId = call.argument("wallet_id");
                            String walletPackage = call.argument("wallet_package");
                            String walletScheme = call.argument("wallet_scheme");
                            Object paramsObj = call.argument("params");
                            
                            if (walletId == null || walletPackage == null || walletScheme == null) {
                                result.error("INVALID_ARGUMENTS", "Missing required wallet parameters", null);
                                return;
                            }
                            
                            // Convert params to JSON string if it's not already a string
                            String paramsString = "";
                            if (paramsObj instanceof String) {
                                paramsString = (String) paramsObj;
                            } else if (paramsObj != null) {
                                paramsString = paramsObj.toString();
                            }
                            
                            // Launch wallet with deep link
                            boolean launched = launchWalletApp(walletId, walletPackage, walletScheme, paramsString);
                            result.success(launched);
                        } catch (Exception e) {
                            Log.e(TAG, "Error launching wallet: " + e.getMessage(), e);
                            result.error("LAUNCH_ERROR", "Error launching wallet: " + e.getMessage(), null);
                        }
                    } else {
                        result.notImplemented();
                    }
                }
            );
    }

    private boolean launchWalletApp(String walletId, String walletPackage, String walletScheme, String params) {
        Log.d(TAG, "Attempting to launch wallet: " + walletId);
        
        // Check if the wallet app is installed
        PackageManager pm = getPackageManager();
        boolean isInstalled = isPackageInstalled(walletPackage, pm);
        
        if (!isInstalled) {
            Log.d(TAG, "Wallet app not installed: " + walletPackage);
            return false;
        }
        
        try {
            // Try to construct a deep link URI based on wallet type
            Uri uri = null;
            
            // Different wallets have different deep link formats
            switch (walletId) {
                case "metamask":
                    // MetaMask format
                    uri = Uri.parse(walletScheme + "connect?params=" + Uri.encode(params));
                    break;
                    
                case "trust":
                    // Trust Wallet format
                    uri = Uri.parse(walletScheme + "connect?params=" + Uri.encode(params));
                    break;
                    
                case "phantom":
                    // Phantom format
                    uri = Uri.parse(walletScheme + "connect?params=" + Uri.encode(params));
                    break;
                    
                case "coinbase":
                    // Coinbase format 
                    uri = Uri.parse(walletScheme + "connect?params=" + Uri.encode(params));
                    break;
                    
                case "binance":
                    // Binance format
                    uri = Uri.parse(walletScheme + "connect?params=" + Uri.encode(params));
                    break;
                    
                default:
                    // Default format
                    uri = Uri.parse(walletScheme + "connect?params=" + Uri.encode(params));
                    break;
            }
            
            if (uri != null) {
                Intent intent = new Intent(Intent.ACTION_VIEW, uri);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                
                // Try to launch the wallet app
                startActivity(intent);
                Log.d(TAG, "Successfully launched wallet: " + walletId);
                return true;
            }
            
            return false;
        } catch (Exception e) {
            Log.e(TAG, "Error launching wallet app: " + e.getMessage(), e);
            return false;
        }
    }
    
    private boolean isPackageInstalled(String packageName, PackageManager packageManager) {
        try {
            packageManager.getPackageInfo(packageName, 0);
            return true;
        } catch (PackageManager.NameNotFoundException e) {
            return false;
        }
    }
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Handle incoming intents (for deep link handling)
        handleIntent(getIntent());
    }
    
    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        handleIntent(intent);
    }
    
    private void handleIntent(Intent intent) {
        if (intent == null || intent.getData() == null) {
            return;
        }
        
        // Get the URI from the intent
        Uri uri = intent.getData();
        Log.d(TAG, "Received deep link: " + uri.toString());
        
        // Process deep link - send to Flutter
        if (getFlutterEngine() != null) {
            new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
                .invokeMethod("handleDeepLink", uri.toString());
        }
    }
}