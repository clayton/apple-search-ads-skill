# Apple Search Ads API v5 Reference

Complete API endpoint documentation for the Apple Search Ads skill.

## Base Configuration

- **API Base URL**: `https://api.searchads.apple.com/api/v5/`
- **Auth URL**: `https://appleid.apple.com/auth/oauth2/token`
- **API Version**: v5 (REQUIRED - v4 returns 410 Gone)

## Required Headers

Every API request must include:

```
Authorization: Bearer {access_token}
X-AP-Context: orgId={org_id}
Content-Type: application/json
```

## Authentication Flow

### Step 1: Generate ES256 JWT Client Secret

```ruby
# JWT Header
{ "alg": "ES256", "kid": KEY_ID }

# JWT Payload
{
  "iss": TEAM_ID,
  "iat": CURRENT_TIMESTAMP,
  "exp": CURRENT_TIMESTAMP + 3600,
  "aud": "https://appleid.apple.com",
  "sub": CLIENT_ID
}
```

Sign with EC P-256 private key using ES256 algorithm.

### Step 2: Exchange for Access Token

```bash
curl -X POST https://appleid.apple.com/auth/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$APPLE_ADS_CLIENT_ID" \
  -d "client_secret=$JWT" \
  -d "scope=searchadsorg"
```

Response:
```json
{
  "access_token": "...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

## READ Endpoints

### List Campaigns

```bash
GET /campaigns?limit=1000&offset=0
```

Response:
```json
{
  "data": [
    {
      "id": 123456789,
      "name": "USA_generic",
      "status": "ENABLED",
      "displayStatus": "RUNNING",
      "countriesOrRegions": ["US"],
      "dailyBudgetAmount": {
        "amount": "100.00",
        "currency": "USD"
      },
      "budgetOrders": [...],
      "supplySources": ["APPSTORE_SEARCH_RESULTS"]
    }
  ],
  "pagination": {
    "totalResults": 42,
    "startIndex": 0,
    "itemsPerPage": 1000
  }
}
```

### Get Campaign Details

```bash
GET /campaigns/{campaignId}
```

### List Ad Groups

```bash
GET /campaigns/{campaignId}/adgroups?limit=1000&offset=0
```

Response:
```json
{
  "data": [
    {
      "id": 987654321,
      "name": "generic_keywords",
      "status": "ENABLED",
      "defaultBidAmount": {
        "amount": "1.50",
        "currency": "USD"
      },
      "automatedKeywordsOptIn": false
    }
  ]
}
```

### List Keywords

```bash
GET /campaigns/{campaignId}/adgroups/{adgroupId}/targetingkeywords?limit=1000&offset=0
```

Response:
```json
{
  "data": [
    {
      "id": 111222333,
      "text": "fitness app",
      "matchType": "EXACT",
      "status": "ACTIVE",
      "bidAmount": {
        "amount": "1.50",
        "currency": "USD"
      }
    }
  ]
}
```

### Keyword Performance Report

```bash
POST /reports/campaigns/{campaignId}/adgroups/{adgroupId}/keywords
```

Request Body:
```json
{
  "startTime": "2024-01-01",
  "endTime": "2024-01-31",
  "selector": {
    "orderBy": [
      {"field": "localSpend", "sortOrder": "DESCENDING"}
    ],
    "pagination": {
      "offset": 0,
      "limit": 1000
    }
  },
  "returnRowTotals": true,
  "returnRecordsWithNoMetrics": false
}
```

Response Structure:
```json
{
  "data": {
    "reportingDataResponse": {
      "row": [
        {
          "metadata": {
            "keyword": "fitness app",
            "keywordId": 111222333,
            "matchType": "EXACT",
            "keywordStatus": "ACTIVE"
          },
          "total": {
            "localSpend": {
              "amount": "125.50",
              "currency": "USD"
            },
            "impressions": 5000,
            "taps": 250,
            "totalInstalls": 45,
            "avgCPA": {
              "amount": "2.79",
              "currency": "USD"
            },
            "avgCPT": {
              "amount": "0.50",
              "currency": "USD"
            },
            "conversionRate": 0.18,
            "tapThroughRate": 0.05,
            "impressionShare": 0.75
          }
        }
      ]
    }
  }
}
```

**IMPORTANT**: All metrics are in the `total` object, NOT at the root level.

### Campaign Performance Report

```bash
POST /reports/campaigns
```

Request Body:
```json
{
  "startTime": "2024-01-01",
  "endTime": "2024-01-31",
  "selector": {
    "conditions": [
      {
        "field": "campaignId",
        "operator": "IN",
        "values": ["123", "456"]
      }
    ],
    "orderBy": [
      {"field": "localSpend", "sortOrder": "DESCENDING"}
    ],
    "pagination": {
      "offset": 0,
      "limit": 1000
    }
  },
  "groupBy": ["CAMPAIGN"],
  "returnRowTotals": true,
  "returnGrandTotals": true
}
```

## WRITE Endpoints

### Update Campaign

**IMPORTANT**: Use PUT (not PATCH). PATCH returns 403 Forbidden. Body must be nested under a `"campaign"` key.

```bash
PUT /campaigns/{campaignId}
```

Request Body:
```json
{
  "campaign": {
    "status": "PAUSED",
    "dailyBudgetAmount": {
      "amount": "200.00",
      "currency": "USD"
    }
  }
}
```

### Update Ad Group

```bash
PATCH /campaigns/{campaignId}/adgroups/{adgroupId}
```

Request Body:
```json
{
  "status": "ENABLED",
  "defaultBidAmount": {
    "amount": "2.00",
    "currency": "USD"
  }
}
```

### Add Keywords

**IMPORTANT**: Use the `/bulk` endpoint. The non-bulk endpoint returns RESOURCE_NOT_FOUND.

```bash
POST /campaigns/{campaignId}/adgroups/{adgroupId}/targetingkeywords/bulk
```

Request Body:
```json
[
  {
    "text": "fitness tracker",
    "matchType": "EXACT",
    "bidAmount": {
      "amount": "1.50",
      "currency": "USD"
    }
  },
  {
    "text": "workout app",
    "matchType": "EXACT",
    "bidAmount": {
      "amount": "1.25",
      "currency": "USD"
    }
  }
]
```

Match Types: `EXACT`, `BROAD`

### Update Keywords (Bid or Status)

**IMPORTANT**: Use the `/bulk` PUT endpoint. The single-resource PATCH endpoint returns RESOURCE_NOT_FOUND.

```bash
PUT /campaigns/{campaignId}/adgroups/{adgroupId}/targetingkeywords/bulk
```

Request Body (update bid):
```json
[
  {
    "id": 111222333,
    "bidAmount": {
      "amount": "2.50",
      "currency": "USD"
    }
  }
]
```

Request Body (pause keyword):
```json
[
  {
    "id": 111222333,
    "status": "PAUSED"
  }
]
```

### Add Negative Keywords

```bash
POST /campaigns/{campaignId}/adgroups/{adgroupId}/negativekeywords
```

Request Body:
```json
[
  {
    "text": "free",
    "matchType": "EXACT"
  },
  {
    "text": "cheap",
    "matchType": "BROAD"
  }
]
```

### Delete Keyword

```bash
DELETE /campaigns/{campaignId}/adgroups/{adgroupId}/targetingkeywords/{keywordId}
```

## Error Handling

### Common HTTP Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | - |
| 400 | Bad Request | Check required fields, body format |
| 401 | Unauthorized | Refresh access token |
| 403 | Forbidden | Check org permissions |
| 404 | Not Found | Invalid campaign/adgroup/keyword ID |
| 410 | Gone | Using old API version (must use v5) |
| 429 | Rate Limited | Back off, retry after delay |

### Error Response Format

```json
{
  "error": {
    "messageCode": "INVALID_REQUEST",
    "message": "The request body contains invalid parameters"
  }
}
```

Or array format:
```json
{
  "errors": [
    {
      "field": "bidAmount",
      "message": "Bid amount must be positive"
    }
  ]
}
```

## Rate Limits

- Apple Search Ads has rate limits but doesn't publish exact numbers
- Implement exponential backoff on 429 responses
- Cache responses where appropriate (campaigns list: 1 hour, reports: 15 minutes)

## Pagination

All list endpoints support pagination:

```
?limit=1000&offset=0
```

- `limit`: Max 1000 per request
- `offset`: Starting position (0-indexed)

Response includes pagination info:
```json
{
  "pagination": {
    "totalResults": 5000,
    "startIndex": 0,
    "itemsPerPage": 1000
  }
}
```

## Field Reference

### Campaign Status Values
- `ENABLED` - Campaign is active
- `PAUSED` - Campaign is paused

### Keyword Status Values
- `ACTIVE` - Keyword is active
- `PAUSED` - Keyword is paused

### Match Types
- `EXACT` - Only exact search terms
- `BROAD` - Related search terms included

### Available Sort Fields (Reports)
- `localSpend`
- `impressions`
- `taps`
- `totalInstalls`
- `avgCPA`
- `avgCPT`
