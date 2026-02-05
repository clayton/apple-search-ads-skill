# Apple Search Ads Credential Setup

This guide walks through obtaining the required credentials for the Apple Search Ads API.

## Prerequisites

1. **Apple Developer Account** - Member or Admin role
2. **App Store Connect Access** - For your app(s)
3. **Apple Search Ads Account** - With API access enabled

## Step 1: Create API Credentials in Apple Search Ads

1. Go to [Apple Search Ads](https://searchads.apple.com)
2. Click your account name (top right) -> **Settings**
3. Navigate to **API** section
4. Click **Create API Certificate**

You'll receive:
- **Client ID** - Starts with `SEARCHADS.`
- **Team ID** - Starts with `SEARCHADS.`
- **Key ID** - UUID format

Download the private key file (`.pem` or `.p8`).

## Step 2: Get Your Organization ID

1. In Apple Search Ads, go to **Settings**
2. Your **Org ID** is displayed at the top of the page (numeric ID)

## Step 3: Prepare the Private Key

The private key needs to be formatted for use in an environment variable.

### Option A: One-liner format

Convert newlines to `\n`:

```bash
cat your-key.pem | awk '{printf "%s\\n", $0}'
```

This outputs something like:
```
-----BEGIN EC PRIVATE KEY-----\nMHQCAQE...\n-----END EC PRIVATE KEY-----\n
```

### Option B: Keep as-is (multiline)

You can also use the key as-is with proper quoting in your `.env` file.

## Step 4: Configure Environment

Create or edit `~/.claude/.env`:

```bash
# Apple Search Ads OAuth 2.0 Credentials
# Get these from: Apple Search Ads > Settings > API

APPLE_ADS_CLIENT_ID=SEARCHADS.xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APPLE_ADS_TEAM_ID=SEARCHADS.xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APPLE_ADS_KEY_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APPLE_ADS_ORG_ID=1234567

# Private key - use \n for newlines
APPLE_ADS_PRIVATE_KEY="-----BEGIN EC PRIVATE KEY-----\nMHQCAQEEIBc...<base64>...\n-----END EC PRIVATE KEY-----"
```

> **Important**: The key must be an EC (Elliptic Curve) private key, not RSA. Apple Search Ads uses ES256 (ECDSA P-256).

## Step 5: Test the Connection

Run the token generation script:

```bash
~/.claude/skills/apple-ads/scripts/get-token.sh
```

If successful, you'll see an access token (a long JWT string).

Then test listing campaigns:

```bash
~/.claude/skills/apple-ads/scripts/list-campaigns.sh
```

## Troubleshooting

### "Error: invalid_client"

- Check that CLIENT_ID and TEAM_ID both start with `SEARCHADS.`
- Verify KEY_ID matches the key you downloaded
- Make sure the private key is properly formatted

### "401 Unauthorized"

- Token may have expired (they last 1 hour)
- Verify ORG_ID is correct
- Check API access is enabled for your account

### "Missing required environment variables"

- Ensure all 5 variables are set
- Check for typos in variable names
- If using `.env`, make sure it's being sourced

### Private key issues

Common key format problems:

```bash
# Wrong (RSA key):
-----BEGIN RSA PRIVATE KEY-----

# Wrong (generic format):
-----BEGIN PRIVATE KEY-----

# Correct (EC key):
-----BEGIN EC PRIVATE KEY-----
```

If you have a PKCS#8 format key (`BEGIN PRIVATE KEY`), convert it:

```bash
openssl ec -in your-key.pem -out ec-key.pem
```

## Environment Loading

The scripts check for environment variables in this order:

1. Shell environment (already exported)
2. `~/.claude/.env`
3. `~/.env`
4. `.env` (current directory)

The first file found is sourced.

## Security Notes

- Never commit your `.env` file to version control
- The private key should be kept secure
- Access tokens are valid for 1 hour
- Consider using a secrets manager for production use

## API Limits

- Apple Search Ads has rate limits (not publicly documented)
- The scripts don't implement automatic retry
- Space out bulk operations if you hit 429 errors

## Need Help?

- [Apple Search Ads API Documentation](https://developer.apple.com/documentation/apple_search_ads)
- [API Status Page](https://developer.apple.com/system-status/)
