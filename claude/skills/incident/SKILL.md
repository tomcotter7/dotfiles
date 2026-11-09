---
name: incident
description: |
  Create stakeholder-friendly incident summaries from multiple sources.
  Use when asked to 'write incident report', 'document outage', 'create incident summary',
  'post-mortem', 'incident.io summary', or 'outage report'.
argument-hint: "[incident.io-url] or [datadog-url] or [description]"
disable-model-invocation: false
user-invocable: true
compatibility: "Requires ~/.netrc for Confluence operations (via REST scripts). Optional: Embrace MCP (crash data), Datadog MCP (service health), AWS CLI + depop assume-aws-role (infrastructure data)"
metadata:
  author: depop
  version: "3.2.0"
  category: documentation
  mcp-server:
    - embrace
    - datadog
---

# Incident Documentation

Create stakeholder-friendly incident summaries from multiple sources.
Outputs structured JSON that gets rendered to markdown via templates.

## Critical: Output Format

**You MUST output valid JSON matching the schema.**

Do NOT output markdown directly. The template engine handles formatting.
Write the JSON to a file, then call the render script.

## Configuration

**Before publishing to Confluence**, read `~/.claude/team-config.md` for:
- **Incident Reports Parent Page ID** -> use as parent when creating pages
- **Confluence Space ID** -> use when creating pages

Do NOT ask the user for these values if the file exists.

## Required Skills

| Skill | Location |
|-------|----------|
| `confluence-conventions` | `~/.claude/skills/confluence-conventions.md` |

---

## Step 1: Gather Sources

Ask what information is available:

```
What sources do you have for this incident?
1. Description - I'll describe what happened
2. incident.io link - https://app.incident.io/depop/incidents/XXX
3. Datadog link - Service, monitor, or incident URL
4. Embrace crash data - Crash ID or "check top crashes"
5. AWS - ECS service issues, ALB errors, CloudWatch alarms, RDS/ElastiCache metrics
6. Multiple sources - I have several of these
```

### Datadog URL Patterns

| Type | Pattern | Data Retrieved |
|------|---------|----------------|
| Service | `https://app.datadoghq.com/apm/services/<service>` | Service health, monitors, recent incidents |
| Monitor | `https://app.datadoghq.com/monitors/<id>` | Monitor status, history, affected services |
| Incident | `https://app.datadoghq.com/incidents/<id>` | Incident details, timeline, affected services |
| Dashboard | `https://app.datadoghq.com/dashboard/<id>` | Context only (manual extraction) |

### Extracting Context from Datadog URLs

When a Datadog URL is provided, extract as much context as possible from the URL itself before attempting to fetch:
- **Monitor ID** from `/monitors/<id>`
- **Endpoint/service name** from query params (e.g., `endpointname:X`)
- **Variant** from query params (e.g., `variantname:X`)
- **Alert time window** from `from_ts` and `to_ts` params (epoch milliseconds — convert to UTC)

Present these extracted details to the user to confirm and fill in gaps.

---

## Single Source Flow

**Model:** claude-opus (in-process) - best for stakeholder communication

### Phase 1: Collection

Collect source information from user.

### Phase 2: Fetch External Data (if links provided)

**For incident.io:** Use WebFetch tool
- May require auth - if blocked, ask user to paste content

**For Datadog:** Use MCP tools (preferred). Search for Datadog tools using ToolSearch first.
- `mcp__datadog__search_datadog_monitors` - Get monitors and their status
- `mcp__datadog__search_datadog_services` - Get service context
- `mcp__datadog__search_datadog_logs` - Search raw error logs during incident window
- `mcp__datadog__analyze_datadog_logs` - SQL analysis of logs (counts, aggregations)
- `mcp__datadog__get_datadog_metric` - Get error rates, latency during incident window
- `mcp__datadog__get_datadog_incident` - Get Datadog incident details by ID
- **If MCP unavailable:** Datadog requires authentication — WebFetch will NOT work. Instead, extract context from the URL (see "Extracting Context from Datadog URLs") and ask the user to describe: what the monitor tracks, what triggered the alert, impact, duration, and resolution.

**Datadog log investigation strategy (for monitor alerts):**
When investigating a monitor alert, always search logs to find the actual error messages — these often reveal the root cause directly. Use the `from_ts`/`to_ts` from the monitor URL as the time window.
1. Search for error logs using the endpoint/service name extracted from the URL, excluding noise: `<service-or-endpoint-name> -status:(info OR warn)`
2. Use `analyze_datadog_logs` with a `GROUP BY` on the minute to confirm the exact error window and count
3. Read the raw error messages — they frequently contain the root cause (e.g., capacity errors, timeout messages, dependency failures)

**For AWS:** Use the AWS CLI after authenticating to the production account.

1. Authenticate first:
   ```bash
   eval "$(depop assume-aws-role --account-name app-production --role developer --export)"
   ```
2. Then query relevant AWS services depending on the incident:

| Scenario | Command |
|----------|---------|
| ECS service issues | `aws ecs describe-services --cluster <cluster> --services <service>` |
| ECS stopped tasks (crash/OOM) | `aws ecs describe-tasks --cluster <cluster> --tasks $(aws ecs list-tasks --cluster <cluster> --service-name <service> --desired-status STOPPED --query 'taskArns[:5]' --output text)` |
| ALB target health | `aws elbv2 describe-target-health --target-group-arn <arn>` |
| ALB 5xx errors | `aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name HTTPCode_Target_5XX_Count --dimensions Name=LoadBalancer,Value=<lb-id> --start-time <start> --end-time <end> --period 60 --statistics Sum` |
| CloudWatch alarms | `aws cloudwatch describe-alarms --state-value ALARM` |
| RDS status | `aws rds describe-db-instances --db-instance-identifier <id> --query 'DBInstances[0].{Status:DBInstanceStatus,CPU:ProcessorFeatures}'` |
| RDS metrics (CPU/connections) | `aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name CPUUtilization --dimensions Name=DBInstanceIdentifier,Value=<id> --start-time <start> --end-time <end> --period 60 --statistics Average` |
| ElastiCache status | `aws elasticache describe-cache-clusters --cache-cluster-id <id>` |
| Recent deployments (CodeDeploy) | `aws deploy list-deployments --application-name <app> --create-time-range start=<start> --query 'deployments[:3]' --output text` |
| CloudWatch Logs (errors) | `aws logs filter-log-events --log-group-name <group> --start-time <epoch-ms> --end-time <epoch-ms> --filter-pattern "ERROR"` |

- Adapt commands based on what the user describes (e.g., if they mention a specific service, cluster, or alarm)
- Use `--query` JMESPath filters to keep output concise
- Convert incident time window to ISO 8601 (`--start-time`, `--end-time`) or epoch milliseconds as needed

**For Embrace crash data:** Use MCP tools:
- `mcp__embrace__list_crashes` - Get crash list
- `mcp__embrace__get_crash_details` - Get specific crash
- `mcp__embrace__get_crash_stack_samples` - Get stack traces

### Phase 3: Generate JSON Output

**Execute directly** (you are Claude Opus):

1. Transform collected data into JSON matching the schema
2. Translate technical details into stakeholder language
3. Mark unknowns with placeholder values (see Unknown Values section)
4. Write JSON to `/tmp/incident-output.json`

### Phase 4: Render, Save, and Review

1. Render markdown:
   ```bash
   ~/.local/pipx/venvs/chevron/bin/python3 ~/.claude/scripts/render-template.py \
     --template ~/.claude/skills/incident/assets/incident.mustache \
     --data /tmp/incident-output.json
   ```
2. Save the rendered markdown to `~/Documents/incidents/YYYY-MM-DD-short-description.md`
   - Create `~/Documents/incidents/` if it doesn't exist
   - Use the incident date for `YYYY-MM-DD`
   - Derive `short-description` from the title: lowercase, hyphens for spaces, no special chars (e.g., `2026-03-02-sellers-category-prediction-unavailable.md`)
3. Clean up: `rm /tmp/incident-output.json`
4. Present rendered output to user, noting the saved file path
5. Get explicit approval before publishing

### Phase 5: Publish

After approval:
1. Apply `confluence-conventions.md` formatting
2. Publish via REST script:
```bash
echo '<storage-format-body>' | ~/.claude/scripts/confluence-create.py \
    --server [SERVER_URL] --space-id [SPACE_ID] \
    --parent-id [PARENT_ID] --title "[TITLE]" --body-stdin
```

---

## Multiple Sources Flow

### Phase 1: Collection

Collect all available source URLs/IDs from user.

### Phase 2: Data Gathering (PARALLEL where possible)

**Embrace crash data:**
- Use Embrace MCP tools

**Datadog data:**
- Use Datadog MCP tools (preferred):
  - `mcp__datadog__search_datadog_monitors` - Monitor status
  - `mcp__datadog__search_datadog_logs` - Search raw error logs during incident window
  - `mcp__datadog__analyze_datadog_logs` - SQL analysis of logs (counts, aggregations)
  - `mcp__datadog__get_datadog_metric` - Metrics during incident window
  - `mcp__datadog__get_datadog_incident` - Datadog incident details by ID
- Follow the **Datadog log investigation strategy** from Single Source Flow Phase 2 to search for error logs and identify root cause
- **If MCP unavailable:** Extract context from URL and ask user to describe details (see Single Source Flow Phase 2)

**AWS infrastructure data:**
- Authenticate: `eval "$(depop assume-aws-role --account-name app-production --role developer --export)"`
- Query relevant services (ECS, ALB, CloudWatch, RDS, ElastiCache) — see Single Source Flow Phase 2 for command reference
- Useful for: deployment correlation, container crashes/OOM, target health, infrastructure metrics

**incident.io:**
- Use WebFetch
- If auth blocked, ask user to paste

### Phase 3: Root Cause Analysis (if complex)

**Model:** gpt-5.2-pro (cli) - best for multi-step reasoning

```bash
source ~/.claude/scripts/load-api-keys.sh 2>/dev/null && \
  ~/.claude/scripts/query-model.py -m gpt-5.2-pro \
  -p "Analyze these incident data points for root cause. Timeline: [TIMELINE]. Metrics: [METRICS]. Crash data: [CRASHES]. Identify the most likely root cause and contributing factors." \
  -s "You are a senior SRE performing incident root cause analysis. Be precise about what's confirmed vs suspected." -q
```

### Phase 4: Generate JSON Output

**Execute directly** (you are Claude Opus):

1. Synthesize all sources into JSON matching the schema
2. Cross-reference timelines - note any discrepancies
3. Identify root cause (confirmed or suspected)
4. Write JSON to `/tmp/incident-output.json`

### Phase 5: Render, Save, and Review

1. Render markdown:
   ```bash
   ~/.local/pipx/venvs/chevron/bin/python3 ~/.claude/scripts/render-template.py \
     --template ~/.claude/skills/incident/assets/incident.mustache \
     --data /tmp/incident-output.json
   ```
2. Save the rendered markdown to `~/Documents/incidents/YYYY-MM-DD-short-description.md`
   - Create `~/Documents/incidents/` if it doesn't exist
   - Use the incident date for `YYYY-MM-DD`
   - Derive `short-description` from the title: lowercase, hyphens for spaces, no special chars
3. Clean up: `rm /tmp/incident-output.json`
4. Present complete draft with sources listed, noting the saved file path
5. Get explicit approval

### Phase 6: Publish

After approval, publish to Confluence.

---

## Schema

**Schema:** `schemas/incident.json`
**Template:** `assets/incident.mustache`
**Output file:** `/tmp/incident-output.json`

Read `schemas/incident.json` for the full schema before generating output. See `assets/incident.mustache` for the rendered format.

## Required JSON Structure

```json
{
  "title": "Checkout Unavailable",
  "incident_id": "INC-456",
  "date": "2025-01-22",
  "severity": "Critical",
  "duration": "2h 15m",
  "status": "Resolved",
  "what_happened": "Between 14:00 and 16:15 UTC, users were unable to complete purchases on iOS.",
  "impact": {
    "users_affected": "~15,000 users",
    "duration": "2 hours 15 minutes",
    "features_impacted": ["Checkout", "Buy Now"],
    "business_impact": "Estimated GMV impact: $45,000",
    "platforms": ["iOS"]
  },
  "timeline": [
    {"time": "14:03", "event": "First user reports"},
    {"time": "15:10", "event": "Root cause identified"},
    {"time": "16:15", "event": "Service restored"}
  ],
  "timezone": "UTC",
  "root_cause": "Misconfigured timeout in iOS payment SDK.",
  "resolution": "Reverted timeout config via remote config.",
  "next_steps": ["Post-mortem scheduled", "Add timeout to release checklist"],
  "sources": ["https://app.incident.io/depop/incidents/INC-456"]
}
```

---

## Severity Definitions

| Severity | Criteria | Examples |
|----------|----------|----------|
| **Critical** | Business-critical down, significant GMV impact, data breach | Checkout unavailable, payment processing failed |
| **Major** | Important feature degraded, moderate impact, workaround exists | Search returning errors for some users |
| **Minor** | Limited impact, non-critical feature | Profile images slow to load |

---

## Field Guidelines

### What Happened
- Plain language for non-technical stakeholders
- Focus on user experience, not technical details
- 1-2 paragraphs maximum
- Answer: What broke? What did users experience?

**Good:**
> Between 14:00 and 15:30 UTC on January 15th, users were unable to complete purchases on the iOS app. Users who tapped "Buy Now" saw an error message and could not proceed to payment.

**Bad:**
> The CartService threw a NullPointerException when the PaymentGateway returned a malformed response.

### Impact
- Include all metrics available
- Use "Assessing" for unknown business impact
- Be specific about affected platforms
- Quantify where possible (percentages, counts)

### Timeline
- Use consistent timezone (note which one in `timezone` field)
- Include all significant events
- Use HH:MM format
- Order chronologically

### Root Cause
- Explain in plain language
- If still investigating: `"[Under investigation]"`
- Never speculate - state what's confirmed vs suspected

### Next Steps
- Actionable items
- Include post-mortem scheduling
- Add preventive measures where known

---

## Unknown Values

Use these placeholder values when information is not available:

| Field | Placeholder |
|-------|-------------|
| incident_id | `""` (empty string) |
| duration | `""` (renders as "TBD") |
| root_cause | `"[Under investigation]"` |
| resolution | `"[Pending]"` |
| business_impact | `""` (renders as "Assessing") |

**Never guess or fabricate values.**

---

## Output Format

After rendering, present:

```markdown
## Incident Summary Draft

**Sources used:** [incident.io, Embrace, user description, etc.]

---

[Rendered markdown from template]

---

Ready to publish to Confluence? (yes/no/changes needed)
```

---

## Critical Rules

**Never include:**
- PII (names of affected users)
- Credentials or API keys
- Internal infrastructure details not needed for the summary

**Always include:**
- Timeline with specific times
- User impact (number affected, duration)
- Root cause (confirmed or "suspected")
- Remediation status

---

## Error Handling

| Failure | Action |
|---------|--------|
| incident.io auth required | Ask user to paste incident details |
| Datadog MCP not configured | Extract context from URL, ask user to describe details |
| Datadog auth required (WebFetch) | Extract context from URL, ask user to describe details |
| Datadog incident not found | Verify incident ID, check if user has access |
| AWS auth fails (`depop assume-aws-role`) | Ask user to run `! eval "$(depop assume-aws-role --account-name app-production --role developer --export)"` manually, then retry |
| AWS CLI error | Note which AWS data is unavailable, proceed with other sources |
| Embrace API error | Note "Stability data unavailable", proceed with other sources |
| Confluence publish fails | Provide draft as markdown |
| Incomplete information | Use placeholder values per Unknown Values section |
| Schema validation fails | Read error, fix JSON, retry write |
| Draft rejected | Ask what changes needed, revise |
| CLI script not found | Report error, ask user to check `~/.claude/scripts/` setup |
| CLI model API error | Report error with details, then fall back to Claude analysis with attribution |

---

## User Context

$ARGUMENTS
