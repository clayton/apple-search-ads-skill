---
name: apple-ads
description: Manage Apple Search Ads campaigns - fetch performance data, analyze ROAS, update bids, pause keywords, and add new keywords. Use when the user asks about Apple Search Ads, campaign performance, keyword optimization, bid adjustments, ROAS analysis, or wants to make changes to their ASA campaigns.
---

# Apple Search Ads Campaign Manager

Full read/write access to Apple Search Ads API v5 for campaign analysis and optimization.

## When to Use This Skill

**Trigger on requests about:**
- Campaign performance, ROAS, CPA, or spend
- Keyword performance or impression share
- Updating bids or bid strategy
- Pausing/enabling keywords or campaigns
- Adding new keywords or negative keywords
- Apple Search Ads optimization recommendations
- Analyzing why campaigns aren't performing
- Scaling profitable campaigns

## Required Environment Variables

```bash
APPLE_ADS_CLIENT_ID=SEARCHADS.xxx-xxx-xxx
APPLE_ADS_TEAM_ID=SEARCHADS.xxx-xxx-xxx
APPLE_ADS_KEY_ID=xxx-xxx-xxx
APPLE_ADS_PRIVATE_KEY="-----BEGIN EC PRIVATE KEY-----\n...\n-----END EC PRIVATE KEY-----"
APPLE_ADS_ORG_ID=12345678
```

Set these in your shell environment or `~/.claude/.env`.

## Quick Operations

### 1. List All Campaigns
```bash
bash ~/.claude/skills/apple-ads/scripts/list-campaigns.sh
bash ~/.claude/skills/apple-ads/scripts/list-campaigns.sh --format json
bash ~/.claude/skills/apple-ads/scripts/list-campaigns.sh --status ENABLED
```

### 2. Get Keyword Performance Report
```bash
bash ~/.claude/skills/apple-ads/scripts/get-report.sh --campaign-id 123 --adgroup-id 456
bash ~/.claude/skills/apple-ads/scripts/get-report.sh --campaign-id 123 --adgroup-id 456 --days 7
bash ~/.claude/skills/apple-ads/scripts/get-report.sh --campaign-id 123 --adgroup-id 456 --format json
```

### 3. Update Keyword Bid
```bash
bash ~/.claude/skills/apple-ads/scripts/update-keyword-bid.sh \
  --campaign-id 123 --adgroup-id 456 --keyword-id 789 --bid 1.50
```

### 4. Pause a Keyword
```bash
bash ~/.claude/skills/apple-ads/scripts/pause-keyword.sh \
  --campaign-id 123 --adgroup-id 456 --keyword-id 789
```

### 5. Enable a Keyword
```bash
bash ~/.claude/skills/apple-ads/scripts/pause-keyword.sh \
  --campaign-id 123 --adgroup-id 456 --keyword-id 789 --enable
```

### 6. Add Keywords
```bash
bash ~/.claude/skills/apple-ads/scripts/add-keywords.sh \
  --campaign-id 123 --adgroup-id 456 \
  --keywords "fitness app,workout tracker" --bid 1.00
```

### 7. Add Negative Keywords
```bash
bash ~/.claude/skills/apple-ads/scripts/add-negative-keywords.sh \
  --campaign-id 123 --adgroup-id 456 \
  --keywords "free,cheap"
```

### 8. Create Campaign
```bash
bash ~/.claude/skills/apple-ads/scripts/create-campaign.sh \
  --name "USA_generic" --adam-id 123456789 \
  --countries US --budget 5000 --daily-budget 100
```

### 9. Get Ad Groups
```bash
bash ~/.claude/skills/apple-ads/scripts/get-ad-groups.sh --campaign-id 123
```

### 10. Create Ad Group
```bash
bash ~/.claude/skills/apple-ads/scripts/create-ad-group.sh \
  --campaign-id 123 --name "generic_keywords" --default-bid 1.50
```

### 11. Get Keywords
```bash
bash ~/.claude/skills/apple-ads/scripts/get-keywords.sh \
  --campaign-id 123 --adgroup-id 456
```

### 12. Get Search Terms (Discovery Flow)
```bash
bash ~/.claude/skills/apple-ads/scripts/get-search-terms.sh \
  --campaign-id 123 --days 30
```

### 13. Pause Campaign
```bash
bash ~/.claude/skills/apple-ads/scripts/pause-campaign.sh --campaign-id 123
```

## Analysis Workflow

When analyzing campaigns:

1. **List all campaigns** to see the account overview
2. **For each campaign**, get ad groups with `api_get "/campaigns/{id}/adgroups"`
3. **For each ad group**, run the keyword report to see performance
4. **Calculate metrics**:
   - CPA = Spend / Installs
   - CPT = Spend / Taps
   - TTR = Taps / Impressions * 100
   - CR = Installs / Taps * 100
5. **Apply decision matrix** (see below) to identify actions
6. **Execute changes** using update/pause scripts

## Expert Knowledge Summary

### Campaign Structure (7-in-1)

For each country, create 7 campaigns:
1. **Generic** - Category keywords, exact match
2. **Discovery** - Broad match keywords for finding new terms
3. **Brand** - Your brand keywords (defend against competitors)
4. **Competitors** - Competitor brand names
5. **Top** - Proven winners, manually managed
6. **Proxy** - Keywords from Discovery for ROAS tracking
7. **Reco** - Apple's recommended keywords

**Naming convention:** `{country}_{campaign-type}` (e.g., `USA_discovery`)

### The Only Metric That Matters: ROAS

- Intermediate metrics (CPT, CPI, TTR) can mislead
- Low CPI does NOT equal high ROAS
- Great TTR does NOT equal profitable keyword
- ALWAYS evaluate on ROAS when data is available

### Quick Decision Matrix

| Situation | Action |
|-----------|--------|
| Low IS + good ROAS | Raise bid aggressively |
| High IS + poor ROAS | Lower bid or pause |
| No impressions (3 days) | Raise bid 10% |
| Spend > $40, no conversions | Pause |
| Spend > $100, CPA > $30 | Pause |
| ROAS < 30% (30 days) | Pause |
| CPA < $13 | Increase bid |

### Impression Share (IS) Interpretation

| IS Level | With Good Metrics | With Poor Metrics |
|----------|-------------------|-------------------|
| < 50% | Raise bid aggressively | Lower bid or test CPP |
| 50-80% | Raise bid | Optimize or lower bid |
| 80-90% | Push to 90%+ | Evaluate for pause |
| 90-100% | Maxed out, expand elsewhere | Pause or lower bid |

### Common Mistakes to Avoid

1. Using Basic instead of Advanced mode
2. Leaving Search Match ON (always disable)
3. Ignoring small countries (often cheapest traffic)
4. Bidding too low initially
5. Not defending brand keywords
6. Duplicating keywords across campaigns
7. Putting multiple countries in one campaign
8. Not retesting paused keywords

### Country Strategy (Priority Order)

1. **Start here:** Croatia, Czech Republic, Estonia, Hungary, Latvia, Poland, Romania, Slovakia, Slovenia
2. **Second tier:** Austria, Belgium, Denmark, Finland, France, Germany, Italy, Netherlands, Norway, Spain, Sweden, Switzerland
3. **Last priority:** US, UK, Canada, Australia, NZ

**Avoid initially:** India, most of Africa, Pakistan, Bangladesh (high volume, low GDP)

## Response Format

Structure all campaign analysis responses as:

**Summary**: What was found or recommended (2-3 sentences)

**Data**: Metrics in tables with key columns:
- Keyword | Spend | Installs | CPA | IS | Status

**Actions**: Prioritized steps with exact commands to run

**Rationale**: Why, based on Apple Ads best practices

## Additional Reference

See companion files:
- `API_REFERENCE.md` - Complete API endpoint documentation
- `EXPERT_GUIDE.md` - Detailed expert knowledge from Apple Ads Guide
- `OPTIMIZATION_RULES.md` - Decision matrices and automation thresholds
