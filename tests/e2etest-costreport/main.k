# e2etest-costreport - AWS Cost Report E2E Test
# ================================================
# Tests CostReport XRD by importing the persistent cost report resources.
#
# CUR is one-per-account, so this test imports existing resources rather than
# creating new ones. Uses orphan policy (no Delete) so resources persist
# after test cleanup.
#
# The persistent resources were created by the hops-root-account CostReport XR
# and live in the shared CI account.

import models.ai.com.ops.hops.aws.v1alpha1 as hops
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

import file
import base64

# Read AWS credentials from local file (must be created manually, gitignored)
_awsCredsRaw = file.read("secrets/aws-creds")
_awsCreds = base64.encode(_awsCredsRaw)

# AWS account ID and region for testing
_testAccountId = file.read("env/AWS_ACCOUNT_ID").strip()
_testRegion = file.read("env/AWS_REGION").strip()

# Persistent resource names from GitHub variables
_bucketName = file.read("env/COST_REPORT_BUCKET_NAME").strip()
_reportExternalName = file.read("env/COST_REPORT_REPORT_EXTERNAL_NAME").strip()
_databaseExternalName = file.read("env/COST_REPORT_DATABASE_EXTERNAL_NAME").strip()
_crawlerRoleExternalName = file.read("env/COST_REPORT_CRAWLER_ROLE_EXTERNAL_NAME").strip()

# Orphan policy - no Delete means resources persist in AWS after claim deletion
_orphan = ["Create", "Observe", "Update", "LateInitialize"]

_test_name = "e2e-cost-report"

_items = [
    metav1alpha1.E2ETest {
        metadata.name = "costreport-e2e"
        spec = {
            crossplane = {
                autoUpgrade.channel = "Rapid"
            }
            defaultConditions = ["Ready"]
            skipDelete = False
            timeoutSeconds = 4500

            # Extra resources: AWS credentials secret and ProviderConfig
            extraResources = [
                # AWS credentials secret
                {
                    apiVersion = "v1"
                    kind = "Secret"
                    metadata = {
                        name = "aws-creds"
                        namespace = "default"
                    }
                    type = "Opaque"
                    data.creds = _awsCreds
                }
                # ProviderConfig for AWS
                {
                    apiVersion = "aws.m.upbound.io/v1beta1"
                    kind = "ProviderConfig"
                    metadata = {
                        name = "default"
                        namespace = "default"
                    }
                    spec = {
                        credentials = {
                            source = "Secret"
                            secretRef = {
                                name = "aws-creds"
                                namespace = "default"
                                key = "creds"
                            }
                        }
                    }
                }
            ]

            # The CostReport claim — imports existing persistent resources
            manifests = [
                hops.CostReport {
                    metadata = {
                        name = _test_name
                        namespace = "default"
                    }
                    spec = {
                        accountId = _testAccountId
                        region = _testRegion
                        bucketName = _bucketName
                        reportName = _reportExternalName
                        databaseName = _databaseExternalName
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                        managementPolicies = _orphan
                        bucket = {
                            externalName = _bucketName
                        }
                        crawlerRole = {
                            externalName = _crawlerRoleExternalName
                        }
                        tags = {
                            "hops.ops.com.ai/test-repo": "https://github.com/hops-ops/aws-cost-report"
                            "hops.ops.com.ai/persistent": "true"
                        }
                    }
                }
            ]
        }
    }
]
items = _items
