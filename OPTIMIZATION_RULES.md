# Optimization Rules and Decision Matrices

Structured decision-making framework for Apple Search Ads optimization.

## Keyword Health Classification

### Status Categories

| Classification | Criteria | Action |
|----------------|----------|--------|
| **Star** | ROAS > 100%, IS < 90% | Scale aggressively, raise bid |
| **Cash Cow** | ROAS > 100%, IS >= 90% | Maintain, find new keywords |
| **Question Mark** | ROAS 50-100%, IS < 90% | Test higher bid, evaluate |
| **Dog** | ROAS < 50% | Pause or reduce bid |
| **Learning** | No conversions, spend < $40 | Wait for data |
| **Failing** | No conversions, spend >= $40 | Pause immediately |

### Classification Logic

```
if roas >= 100 and impression_share < 90:
    return "Star"
elif roas >= 100 and impression_share >= 90:
    return "Cash Cow"
elif roas >= 50 and roas < 100 and impression_share < 90:
    return "Question Mark"
elif roas < 50 and spend > 0:
    return "Dog"
elif conversions == 0 and spend < 40:
    return "Learning"
elif conversions == 0 and spend >= 40:
    return "Failing"
```

## Pause Rules

### Immediate Pause Conditions

```
# Rule 1: High spend, no conversions
if spend > 40 and conversions == 0:
    action = PAUSE
    reason = "Spend exceeds $40 with no conversions"

# Rule 2: High spend, very high CPA
if spend > 100 and cpa > 30:
    action = PAUSE
    reason = "CPA > $30 with spend > $100"

# Rule 3: Extreme CPA
if spend > 100 and cpa > 100:
    action = PAUSE
    reason = "CPA exceeds $100"

# Rule 4: Prolonged poor ROAS
if roas_30d < 30 and spend_30d > 100:
    action = PAUSE
    reason = "ROAS < 30% over 30 days"
```

### Early Warning Signals

| Signal | Threshold | Action |
|--------|-----------|--------|
| TTR too low | < 2% | Consider pausing |
| CPI above ARPU | CPI > expected LTV | Consider pausing |
| Trial cost too high | > 3x target | Lower bid or pause |
| 7d ROAS too low | < 20% | Evaluate for pause |

## Bid Adjustment Rules

### Increase Bid Conditions

```
# Rule 1: No impressions - kickstart spending
if impressions_3d < 20 and status == ACTIVE:
    new_bid = current_bid * 1.10
    frequency = "every 2 days"
    cap = 2.00  # USD max bid
    reason = "No impressions, need to kickstart"

# Rule 2: High ROAS, low IS - capture more traffic
if roas_30d >= 100 and impression_share < 90:
    new_bid = current_bid * 1.15
    reason = "Profitable with room to grow"

# Rule 3: Very efficient CPA
if cpa < 13:
    new_bid = current_bid * 1.10
    reason = "CPA below target, scale up"

# Rule 4: Star performer
if classification == "Star":
    new_bid = current_bid * 1.20
    target_is = 90
    reason = "Star performer, push to max IS"
```

### Decrease Bid Conditions

```
# Rule 1: Poor ROAS but still some value
if roas_30d >= 30 and roas_30d < 70:
    new_bid = current_bid * 0.85
    reason = "Marginal ROAS, reduce exposure"

# Rule 2: High IS, mediocre metrics
if impression_share > 80 and roas_30d < 80:
    new_bid = current_bid * 0.80
    reason = "High IS with poor returns"
```

## Discovery Pipeline Rules

### Search Term Processing

```
# When new search term appears in Discovery campaign
if search_term.is_new and search_term.spend > 5:
    # Add to Proxy campaign for ROAS tracking
    add_to_campaign = "{country}_proxy"
    match_type = "EXACT"
    initial_bid = discovery_campaign.default_bid

    # Also add as negative to Discovery to avoid duplicate bidding
    add_negative_to = "{country}_discovery"
```

### Proxy Evaluation

```
# After 30 days in Proxy campaign
if proxy_keyword.spend > 50:
    if proxy_keyword.roas > 100:
        move_to = "{country}_top"
        reason = "Profitable, promote to Top"
    elif proxy_keyword.roas < 30:
        action = PAUSE
        reason = "Failed to prove profitability"
    else:
        action = KEEP_TESTING
        reason = "Needs more data"
```

## Campaign-Level Rules

### Campaign Status Changes

```
# Pause entire campaign
if campaign.roas_30d < 20 and campaign.spend_30d > 500:
    action = PAUSE
    reason = "Campaign-level failure"

# Reactivate for retest
if campaign.status == PAUSED and days_paused > 30:
    action = CONSIDER_RETEST
    reason = "Auction dynamics may have changed"
```

### Budget Adjustments

```
# Increase daily budget
if campaign.roas_30d > 100 and campaign.is_hitting_budget_cap:
    new_budget = current_budget * 1.25
    reason = "Profitable and capped"

# Decrease daily budget
if campaign.roas_30d < 50:
    new_budget = current_budget * 0.75
    reason = "Poor performance, reduce exposure"
```

## Country Expansion Rules

### New Country Launch

```
# Tier 1 countries (start here)
tier_1 = ["HR", "CZ", "EE", "HU", "LV", "PL", "RO", "SK", "SI"]
initial_test_budget = 500  # USD total for testing

# Tier 2 countries (second wave)
tier_2 = ["AT", "BE", "DK", "FI", "FR", "DE", "IT", "NL", "NO", "ES", "SE", "CH"]
initial_test_budget = 750  # USD total for testing

# Tier 3 countries (last priority)
tier_3 = ["US", "GB", "CA", "AU", "NZ"]
initial_test_budget = 1000  # USD total for testing (more competitive)
```

### Country Evaluation

```
# After initial test period (14-30 days)
if country.roas > 100:
    action = SCALE
    create_campaigns = ["generic", "discovery", "brand", "competitors", "top", "proxy", "reco"]

elif country.roas >= 50 and country.roas < 100:
    action = OPTIMIZE
    focus = "test different keywords, adjust bids"

elif country.roas < 50:
    action = PAUSE_AND_REVISIT
    revisit_in = "60 days"
```

## Metric Calculations

### From API Response

```python
# Extract from API response
spend = row['total']['localSpend']['amount']
impressions = row['total']['impressions']
taps = row['total']['taps']
installs = row['total']['totalInstalls']

# Calculate metrics
ttr = (taps / impressions * 100) if impressions > 0 else 0
cr = (installs / taps * 100) if taps > 0 else 0
cpt = (spend / taps) if taps > 0 else 0
cpi = (spend / installs) if installs > 0 else 0

# ROAS requires revenue data (from RevenueCat or similar)
roas = (revenue / spend * 100) if spend > 0 else 0
```

### Impression Share Interpretation

```
if impression_share < 0.50:
    potential = "High growth potential"
    action_if_good = "Aggressively raise bid"
elif impression_share < 0.80:
    potential = "Moderate growth potential"
    action_if_good = "Raise bid"
elif impression_share < 0.90:
    potential = "Limited growth potential"
    action_if_good = "Push to 90%+"
else:  # >= 0.90
    potential = "Maxed out"
    action_if_good = "Maintain, expand elsewhere"
```

## Execution Priority

When making bulk changes, prioritize in this order:

1. **Pause failing keywords** (prevent waste)
2. **Raise bids on Stars** (capture opportunity)
3. **Lower bids on Dogs** (reduce exposure)
4. **Process Discovery pipeline** (find new winners)
5. **Evaluate Question Marks** (make decisions)
6. **Review Cash Cows** (maintain health)

## Timing Recommendations

| Action | Best Timing |
|--------|-------------|
| Bid adjustments | Once per day maximum |
| Pause decisions | After minimum spend threshold met |
| New keyword additions | Any time |
| Campaign structure changes | Weekly review |
| Country expansion | Monthly evaluation |
| Retest paused keywords | After 30-60 days |

## Red Flags

Immediate attention required:

- Sudden ROAS drop > 50% on a Star keyword
- Competitor appearing on brand keywords
- Discovery campaign generating only irrelevant terms
- Budget cap hit on underperforming campaign
- No impressions on previously active keywords
