# Apple Search Ads Skill for Claude Code

A pure bash/shell skill for managing Apple Search Ads campaigns directly from Claude Code. No Ruby, Python, or other dependencies - just bash, curl, and openssl.

## Features

- **Full API Coverage**: Create, update, pause campaigns and ad groups
- **Keyword Management**: Add keywords, update bids, pause underperformers
- **Performance Reports**: Pull keyword and search term reports
- **Custom Product Pages**: Create creatives and ads for CPP testing
- **Expert Knowledge**: Built-in optimization rules and decision matrices

## Quick Start

### 1. Install

Copy to your Claude Code skills directory:

```bash
git clone https://github.com/YOUR_USERNAME/apple-search-ads-skill.git ~/.claude/skills/apple-ads
```

### 2. Configure

Add your credentials to `~/.claude/.env`:

```bash
# Apple Search Ads OAuth 2.0 Credentials
APPLE_ADS_CLIENT_ID=SEARCHADS.xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APPLE_ADS_TEAM_ID=SEARCHADS.xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APPLE_ADS_KEY_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APPLE_ADS_PRIVATE_KEY="-----BEGIN EC PRIVATE KEY-----\n...\n-----END EC PRIVATE KEY-----"
APPLE_ADS_ORG_ID=1234567
```

See [SETUP.md](SETUP.md) for detailed credential setup instructions.

### 3. Test

```bash
# List all campaigns
~/.claude/skills/apple-ads/scripts/list-campaigns.sh

# Get keyword report
~/.claude/skills/apple-ads/scripts/get-report.sh --campaign-id 123 --adgroup-id 456 --days 7
```

## Available Scripts

### Read Operations

| Script | Description |
|--------|-------------|
| `list-campaigns.sh` | List all campaigns with status and budget |
| `get-ad-groups.sh` | List ad groups for a campaign |
| `get-keywords.sh` | List keywords for an ad group |
| `get-report.sh` | Keyword performance report (spend, installs, CPA) |
| `get-search-terms.sh` | Search terms report (Discovery campaigns) |

### Write Operations

| Script | Description |
|--------|-------------|
| `create-campaign.sh` | Create new campaign with budget and countries |
| `update-campaign.sh` | Update campaign budget, name, or status |
| `pause-campaign.sh` | Pause or enable a campaign |
| `create-ad-group.sh` | Create ad group with default bid |
| `add-keywords.sh` | Add keywords to an ad group |
| `add-negative-keywords.sh` | Add negative keywords |
| `update-keyword-bid.sh` | Update a keyword's bid |
| `pause-keyword.sh` | Pause or enable a keyword |
| `create-creative.sh` | Create creative for Custom Product Page |
| `create-ad.sh` | Create ad using a creative |

## Usage Examples

### Create a Campaign

```bash
./scripts/create-campaign.sh \
  --name "USA_generic" \
  --adam-id 123456789 \
  --countries US \
  --budget 5000 \
  --daily-budget 100
```

### Add Keywords

```bash
./scripts/add-keywords.sh \
  --campaign-id 123 \
  --adgroup-id 456 \
  --keywords "fitness app,workout tracker,exercise" \
  --bid 1.50
```

### Update Keyword Bid

```bash
./scripts/update-keyword-bid.sh \
  --campaign-id 123 \
  --adgroup-id 456 \
  --keyword-id 789 \
  --bid 2.00
```

### Pause Underperforming Keyword

```bash
./scripts/pause-keyword.sh \
  --campaign-id 123 \
  --adgroup-id 456 \
  --keyword-id 789
```

### Pull Search Terms (Discovery Flow)

```bash
./scripts/get-search-terms.sh \
  --campaign-id 123 \
  --days 30
```

## Claude Code Integration

When used as a Claude Code skill, Claude can:

1. **Analyze campaigns** - Pull reports and identify optimization opportunities
2. **Execute changes** - Update bids, pause keywords, add negatives
3. **Apply expert rules** - Use built-in optimization matrices
4. **Provide recommendations** - Suggest actions based on ROAS, CPA, and IS

Trigger the skill by asking Claude about:
- "Show me my Apple Search Ads performance"
- "What keywords should I pause?"
- "Increase bids on profitable keywords"
- "Add these keywords to my campaign"

## Requirements

- `bash` 4.0+
- `curl`
- `openssl` (for ES256 JWT signing)
- `jq` (optional, for pretty output)

## Documentation

- [SETUP.md](SETUP.md) - Detailed credential setup
- [SKILL.md](SKILL.md) - Claude Code skill definition
- [EXPERT_GUIDE.md](EXPERT_GUIDE.md) - Campaign optimization strategies
- [OPTIMIZATION_RULES.md](OPTIMIZATION_RULES.md) - Decision matrices
- [API_REFERENCE.md](API_REFERENCE.md) - Apple Search Ads API v5 documentation

## License

MIT - See [LICENSE](LICENSE)
