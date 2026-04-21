# aws-cost-report

Creates a CUR export, Glue catalog, and Athena workgroup for full AWS cloud cost visibility via OpenCost. One per AWS account.

## Why CUR/Athena?

**Without CUR integration:**
- OpenCost only sees on-demand and spot compute pricing
- No visibility into reserved instance savings, savings plans, or data transfer costs
- Cost allocation is incomplete — only ~60-70% of actual AWS spend

**With CUR/Athena:**
- OpenCost queries the full AWS bill via Athena
- Accurate RI/SP amortization, data transfer, and service-level costs
- Complete cost attribution across teams and workloads

## What It Creates

- **S3 Bucket** — Receives CUR export data (Parquet) and stores Athena query results
- **BucketOwnershipControls** — Enforces bucket owner for all objects
- **BucketPublicAccessBlock** — Blocks all public access
- **BucketPolicy** — Allows AWS billing service (`billingreports.amazonaws.com`) to write CUR data
- **CUR ReportDefinition** — Daily Parquet export with Athena integration
- **IAM Role + Policy + RolePolicyAttachment** — Glue crawler credentials (S3 read + Glue catalog write)
- **Glue CatalogDatabase** — Database for CUR tables
- **Glue Crawler** — Auto-discovers CUR Parquet schema and creates Athena-queryable tables
- **Athena Workgroup** — Query execution with results stored in the same S3 bucket

## Quick Start

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: CostReport
metadata:
  name: hops-root-account
  namespace: default
spec:
  accountId: "123456789012"
  region: us-east-2
```

This creates all resources with sensible defaults. The bucket is named `hops-root-account-cur`, the CUR report is `hops_root_account_cur`, and the Glue database matches.

## Configuration

### Required Fields

| Field | Description |
|-------|-------------|
| `spec.accountId` | AWS Account ID |
| `spec.region` | AWS region for S3, Glue, and Athena resources |

### Optional Fields

| Field | Default | Description |
|-------|---------|-------------|
| `spec.bucketName` | `{name}-cur` | S3 bucket name |
| `spec.reportName` | `{name}_cur` | CUR report name (dashes auto-converted to underscores) |
| `spec.databaseName` | `{name}_cur` | Glue database name (dashes auto-converted to underscores) |
| `spec.providerConfigRef.name` | `"default"` | AWS ProviderConfig name |
| `spec.tags` | hops defaults | Additional AWS resource tags |

## Using with ObserveStack

Point your ObserveStack at the cost report resources to enable cloud cost integration in OpenCost:

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: ObserveStack
metadata:
  name: my-cluster
spec:
  clusterName: my-cluster
  aws:
    region: us-east-2
  cloudCosts:
    enabled: true
    bucketName: hops-root-account-cur
    accountId: "123456789012"
    region: us-east-2
    databaseName: hops_root_account_cur
    tableName: hops_root_account_cur
    workgroupName: hops-root-account-cur-workgroup
```

This creates a `cloud-integration.json` secret, adds Athena/Glue/S3 IAM permissions to the OpenCost PodIdentity, and enables cloud cost reporting in the OpenCost Helm values.

## Custom Names

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: CostReport
metadata:
  name: prod-billing
spec:
  accountId: "123456789012"
  region: us-east-2
  bucketName: my-org-cur-data
  reportName: my_org_daily_cur
  databaseName: my_org_billing
  tags:
    environment: production
```

## Importing Existing Resources

If you already have CUR infrastructure:

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: CostReport
metadata:
  name: existing
spec:
  accountId: "123456789012"
  region: us-east-2
  bucketName: existing-cur-bucket
  managementPolicies: [Create, Update, Observe, LateInitialize]
  bucket:
    externalName: existing-cur-bucket
  crawlerRole:
    externalName: existing-crawler-role-name
```

## Status

```yaml
status:
  ready: true
  bucketName: hops-root-account-cur
  bucketArn: arn:aws:s3:::hops-root-account-cur
  databaseName: hops_root_account_cur
  workgroupName: hops-root-account-cur-workgroup
  crawlerRoleArn: arn:aws:iam::123456789012:role/hops-root-account-cur-crawler
```

## Important Notes

- **One per account** — CUR is account-level; deploy one CostReport per AWS account
- **CUR delivery delay** — AWS takes up to 24 hours to start delivering CUR data after the report is created
- **Crawler scheduling** — The Glue crawler runs on-demand; you may need to trigger the first run manually after CUR data arrives
- **Athena costs** — Athena charges ~$5/TB scanned; CUR Parquet data is compressed so typical queries cost pennies
- **Name your XR meaningfully** — The XR name drives all resource naming (e.g., `hops-root-account` → `hops-root-account-cur`)

## Development

```bash
make render         # Render all examples
make test           # Run KCL composition tests
make e2e            # Run E2E tests (requires AWS credentials)
make validate       # Validate rendered output against schemas
```

## License

Apache-2.0
