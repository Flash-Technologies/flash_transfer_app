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
                                    boolean launched = launchWalletApp(walletId, walletPackage, walletScheme,
                                            paramsString);
                                    result.success(launched);
                                } catch (Exception e) {
                                    Log.e(TAG, "Error launching wallet: " + e.getMessage(), e);
                                    result.error("LAUNCH_ERROR", "Error launching wallet: " + e.getMessage(), null);
                                }
                            } else if (call.method.equals("isPackageInstalled")) {
                                try {
                                    String packageName = call.argument("package_name");
                                    if (packageName == null) {
                                        result.error("INVALID_ARGUMENTS", "Missing package name", null);
                                        return;
                                    }

                                    boolean isInstalled = isPackageInstalled(packageName, getPackageManager());
                                    result.success(isInstalled);
                                } catch (Exception e) {
                                    Log.e(TAG, "Error checking package: " + e.getMessage(), e);
                                    result.error("PACKAGE_CHECK_ERROR", "Error checking package: " + e.getMessage(),
                                            null);
                                }
                            } else if (call.method.equals("getMetaMaskAddress")) {
                                try {
                                    // This is a workaround for MetaMask - we can't directly get the address
                                    // But we'll make an attempt to launch a browser that might have auth cookies
                                    // Or recommend the user to copy their address manually

                                    // First, check if MetaMask is installed
                                    boolean isMetaMaskInstalled = isPackageInstalled("io.metamask",
                                            getPackageManager());
                                    if (!isMetaMaskInstalled) {
                                        result.error("METAMASK_NOT_INSTALLED", "MetaMask is not installed", null);
                                        return;
                                    }

                                    // Launch a very specific MetaMask URL
                                    Intent intent = new Intent(Intent.ACTION_VIEW);
                                    intent.setData(Uri.parse("metamask://send"));
                                    intent.setPackage("io.metamask");
                                    startActivity(intent);

                                    // The best we can do is return success but with no address
                                    // The Flutter side will need to show a dialog asking the user to copy their
                                    // address
                                    result.success("MANUAL_COPY_REQUIRED");
                                } catch (Exception e) {
                                    Log.e(TAG, "Error getting MetaMask address: " + e.getMessage(), e);
                                    result.error("METAMASK_ERROR", "Error getting MetaMask address: " + e.getMessage(),
                                            null);
                                }
                            } else {
                                result.notImplemented();
                            }
                        });
    }

    private boolean launchWalletApp(String walletId, String walletPackage, String walletScheme, String params) {
        Log.d(TAG, "Attempting to launch wallet: " + walletId);
        Log.d(TAG, "Params: " + params);

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
                    // MetaMask requires a specific dapp URL format to properly show connect dialog
                    try {
                        // Extract callback URL from params
                        String callbackUrl = "flashtransferapp://connect";
                        String dappUrl = "https://flash.closedsource.in";

                        try {
                            // Parse the JSON to extract parameters
                            org.json.JSONObject jsonParams = new org.json.JSONObject(params);
                            if (jsonParams.has("redirect")) {
                                callbackUrl = jsonParams.getString("redirect");
                            }
                            if (jsonParams.has("dappUrl")) {
                                dappUrl = jsonParams.getString("dappUrl");
                            }
                        } catch (Exception e) {
                            Log.e(TAG, "Error parsing params JSON: " + e.getMessage());
                        }

                        // The correct format for MetaMask connect is:
                        // metamask://dapp/{encoded-dapp-url}
                        // This will trigger the connection dialog in MetaMask
                        String encodedDappUrl = Uri.encode(dappUrl);
                        String encodedCallback = Uri.encode(callbackUrl);

                        // Format: metamask://dapp/{dapp-url}?redirect={callback-url}
                        String finalUri = walletScheme + "dapp/" + encodedDappUrl +
                                "?redirect=" + encodedCallback;

                        Log.d(TAG, "Launching MetaMask with URI: " + finalUri);
                        uri = Uri.parse(finalUri);
                    } catch (Exception e) {
                        Log.e(TAG, "Error creating MetaMask URI: " + e.getMessage());
                        // Fallback to basic format - less likely to work
                        uri = Uri.parse(walletScheme + "dapp?url=" +
                                Uri.encode("https://flash.closedsource.in") +
                                "&redirect=" + Uri.encode("flashtransferapp://connect"));
                    }
                    break;

                case "trust":
                    // Trust Wallet format - may need specific parameters
                    uri = Uri.parse(walletScheme + "open_url?url="
                            + Uri.encode("https://flash.closedsource.in/connect?params=" + Uri.encode(params)));
                    break;

                case "phantom":
                    // Phantom format for Solana wallet
                    uri = Uri.parse(walletScheme + "connect?params=" + Uri.encode(params));
                    break;

                case "coinbase":
                    // Coinbase Wallet format
                    uri = Uri.parse(walletScheme + "wc?uri=" + Uri.encode("wc:00e46b69-d0cc-4b3e-b6a2-cee442f97188@1"));
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

                // Add package explicitly to ensure it opens the right app
                intent.setPackage(walletPackage);

                // Try to launch the wallet app
                startActivity(intent);
                Log.d(TAG, "Successfully launched wallet: " + walletId + " with URI: " + uri.toString());
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

        // Extract wallet address and other params for better debugging
        try {
            String address = uri.getQueryParameter("address");
            String signature = uri.getQueryParameter("signature");

            if (address != null) {
                Log.d(TAG, "Found wallet address in URI: " + address);
            } else {
                // Try alternate parameter names that different wallets might use
                address = uri.getQueryParameter("wallet_address");
                if (address != null) {
                    Log.d(TAG, "Found wallet_address in URI: " + address);
                } else {
                    address = uri.getQueryParameter("account");
                    if (address != null) {
                        Log.d(TAG, "Found account in URI: " + address);
                    } else {
                        Log.d(TAG, "No wallet address found in URI parameters");

                        // Log all parameters for debugging
                        for (String key : uri.getQueryParameterNames()) {
                            Log.d(TAG, "URI parameter - " + key + ": " + uri.getQueryParameter(key));
                        }
                    }
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error extracting parameters from URI: " + e.getMessage(), e);
        }

        // Process deep link - send to Flutter
        if (getFlutterEngine() != null) {
            new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
                    .invokeMethod("handleDeepLink", uri.toString());
        }
    }
}