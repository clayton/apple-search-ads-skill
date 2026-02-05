# Apple Search Ads Expert Knowledge

Curated expert advice from the Apple Ads Guide by Ivan Sparrow. Use this knowledge to provide informed recommendations.

## When to Use Apple Ads

**Advantages:**
- Easy to start (no video creatives needed)
- Flexible budgets ($1,000+ spread over weeks)
- Capturing existing demand (users are already searching)
- Simple PPC mechanics (no mysterious algorithm)
- Stability (once you find winners, they stay consistent)
- Full attribution (100% attribution data - critical post-iOS 14.5)

**Disadvantages:**
- Expensive (most competitive channel)
- Limited creative edge (just keywords, bids, and product page)
- Hard to scale aggressively
- Can't create demand (only capture existing intent)

## Campaign Structure

### The 7-in-1 Structure (Recommended)

For EACH country, create 7 campaigns:

1. **Generic** (`{country}_generic`)
   - Category keywords
   - Exact match only
   - Main testing ground
   - 95% of keywords won't spend - that's normal

2. **Discovery** (`{country}_discovery`)
   - Broad match keywords
   - Search Match DISABLED
   - Add your Generic keywords as negatives
   - Purpose: Find new keywords + capture low-volume queries

3. **Brand** (`{country}_brand`)
   - Your brand name + variants
   - Exact match
   - Protects against competitor bidding
   - Essential if running influencer/TikTok campaigns

4. **Competitors** (`{country}_competitors`)
   - Competitor brand names
   - Exact match
   - Test: brand name, brand + app/pro, typos, abbreviations
   - Works best when apps are similar (confusable)

5. **Top** (`{country}_top`)
   - Proven winners moved here
   - Manually managed (no automation rules)
   - Bid more aggressively
   - Frees up budget in Generic for testing

6. **Proxy** (`{country}_proxy`)
   - Keywords discovered from Discovery
   - For ROAS tracking (Discovery can't track post-install)
   - Evaluate, then move to Top or kill

7. **Reco** (`{country}_reco`)
   - Apple's recommended keywords
   - Test without prejudice
   - Many are irrelevant, some become winners

### Key Principles

- **One campaign = one country** (never combine)
- **One keyword = one location** (no duplicates across campaigns)
- **Exact match everywhere** except Discovery
- **Search Match ALWAYS off**
- **Naming convention:** `{country}_{campaign-type}` (e.g., `USA_discovery`)

## Optimization Philosophy

### The Only Metric That Matters: ROAS

**Critical insight:** Intermediate metrics can mislead you.

- Low CPI does NOT equal high ROAS
- Great TTR does NOT equal profitable keyword
- Cheap trials don't guarantee paid conversions

**Real example:** Keywords with phenomenal TTR, low CPI, cheap trials - every metric looks great - but users barely convert to paid. Turned them off.

**Another example:** Geos with awful cost per trial. By benchmarks, shouldn't pay back. But actual ROAS is above average. Why? Annual subscriptions dominate instead of weekly trials.

### Cohort vs Ongoing ROAS

**Ongoing ROAS:** Changes over time as more revenue comes in. Good for retrospective analysis.

**Cohort ROAS:** The payback of a specific cohort (day/week/month) over a defined period. Use this for evaluating current performance.

Example: 7d ROAS for September 1st = cost on Sep 1 / revenue over next 7 days

### Making Decisions with Incomplete Data

Reality: You won't have enough data. You'll have to make decisions based on incomplete information.

**With small budget ($5-10K/month):**
- Strict rules and boundaries
- Pause aggressively based on intermediate metrics
- Rely heavily on early signals
- Cut losers fast: TTR too low, CPI above ARPU, trial cost too high

**With large budget ($50K+/month):**
- More patience with data collection
- Focus almost exclusively on financial metrics
- Willing to wait for ROAS data even when early metrics look bad

## Impression Share (IS) Strategy

**Impression Share** = your impressions / total available impressions

| IS Level | Meaning |
|----------|---------|
| < 50% | Lots of untapped traffic |
| 50-80% | Room to grow |
| 80-90% | Capturing most traffic |
| 90-100% | Maxed out |

### Action Matrix

| IS | Good Metrics | Poor Metrics |
|----|--------------|--------------|
| Low (<50%) | Raise bid aggressively | Lower bid or test CPP |
| Medium (50-80%) | Raise bid | Optimize or lower bid |
| High (80-90%) | Push to 90%+ | Evaluate for pause |
| Max (90-100%) | Expand elsewhere | Pause or lower bid |

**Key insight:** Low spend + low IS = bid problem, not volume problem

## Bid Management

### Starting Bids
- Start 20-30% below Apple's suggested bid
- Adjust daily based on spend
- Apple Ads reacts slowly - wait 24 hours between adjustments

### Profitable Keywords
- Push bids until you hit 90-100% IS
- Optimize for total profit, not ROAS percentage
- If high bid turns profitable keyword unprofitable, lower to find sweet spot

### No Impressions?
- Raise bid 10% daily until it starts spending
- Move to separate campaign (not just ad group)

## Automation Thresholds

Based on tested rules:

### Pause Rules
- Spend > $40, no conversions -> PAUSE
- Spend > $100, CPA > $30 -> PAUSE
- CPA > $100 and spend > $100 -> PAUSE
- ROAS < 30% for 30 days -> PAUSE

### Scale Rules
- Impressions < 20 in 3 days -> Increase bid 10%
- CPA < $13 -> Increase bid
- ROAS > 100% and IS < 90% -> Increase bid 15%

### Discovery Pipeline
New search terms in Discovery -> Add to Proxy (exact match) -> Evaluate ROAS -> Move to Top or kill

## Country Strategy

### Priority Order

**1. Start Here (Cheapest, Often Best ROAS):**
Croatia, Czech Republic, Estonia, Hungary, Latvia, Poland, Romania, Slovakia, Slovenia

**2. Second Tier:**
Austria, Belgium, Denmark, Finland, France, Germany, Italy, Netherlands, Norway, Spain, Sweden, Switzerland

**3. Last Priority:**
Southeast Asia, South America, then US/UK/Canada/Australia/NZ

### Countries to Avoid Initially
India, most of Africa, Pakistan, Bangladesh (high volume, low GDP per capita)

### Tricky Markets (Need Localization)
Japan, Korea, Taiwan, Singapore

### Why Not Start with US?
- Most competitive (everyone targets it)
- Most expensive CPT/CPI
- 350M people vs 5B rest of world (excluding India/China)
- iPhone ownership already filters for purchasing power
- Smaller countries = real competitive edge

## Keyword Research

### Sources
1. Your own ideas
2. ChatGPT-assisted brainstorming
3. Apple's suggested keywords during setup
4. ASO tools (Astro, AsoSuite)
5. Competitor keyword research

### Types to Test
- Category keywords (generic)
- Competitor brand names
- Long-tail phrases
- Typos and misspellings
- "Free" variants (often top performers despite common advice)
- Localized keywords for each geo

### Competitor Keywords
**When they work:** Apps that are similar/confusable
**When they don't:** Fundamentally different products (Facebook vs Google)
**Sweet spot:** Competitors running heavy influencer campaigns = massive brand search volume to capture

## Common Mistakes

1. Using Basic instead of Advanced mode
2. Leaving Search Match ON
3. Ignoring small countries
4. Bidding too low initially
5. Not defending brand keywords
6. Not using Custom Product Pages
7. Skipping Discovery campaigns
8. Using only broad match
9. Duplicating keywords across campaigns
10. Putting multiple countries in one campaign
11. Not retesting paused keywords

## Quick Start Checklist

1. Connect attribution (MMP or RevenueCat integration)
2. Use Advanced mode only
3. Disable Search Match
4. Skip tier-1 countries initially
5. Start with small European markets
6. Test all keyword types
7. "Word + free" keywords are often top performers
8. Localize keywords per geo
9. Test competitor brand terms
10. Evaluate only on ROAS
11. Campaign structure: Generic, Competitors, Brand, Reco, Discovery, Proxy, Top
12. 95% of Generic keywords won't spend - that's normal
13. Move stuck keywords to new campaigns, not ad groups
14. One campaign = one country
15. One keyword = one location (no duplicates)
16. Max IS on best keywords? Expand elsewhere
17. CPPs = your only creative lever (up to 70)
18. First screenshot has the biggest impact

## FAQ Quick Answers

**Keyword has no impressions?**
- Raise bid daily until it starts spending
- Move to separate campaign (not ad group)

**Discovery campaign stopped performing?**
- Lower bids
- Or pause - maybe you've exhausted profitable search terms

**Keyword ROAS dropped?**
- Lower bid
- Wait - could be temporary volatility
- If no improvement, pause and retest later

**A country stopped being profitable?**
- Usually: pause and revisit later
- Analyze what changed: CPT shifts, keyword mix, bid creep

**Best keywords at 90-100% IS?**
- Find new keywords or new countries
- Horizontal expansion is the main growth lever

**Discovery campaigns don't pay back?**
- If search terms are irrelevant, drop it
- Works better in larger niches

## Scaling Methods

1. **Raise bids** - Higher bids don't always mean proportionally higher costs (second-price auction)

2. **Expand payback window** - If you can invest $1 and get $1.20 in a year, do it

3. **Add new countries** - 90+ countries x 7 campaigns = 630 opportunities. Main growth lever.

4. **Split campaigns** - When top keywords compete for budget, create {geo}_top-2 for overflow
