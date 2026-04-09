import models.ai.com.ops.hops.aws.v1alpha1 as awsv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

_items = [
    # Test 1: Default bucket name derives from XR name
    metav1alpha1.CompositionTest {
        metadata.name = "default-bucket-name"
        spec = {
            compositionPath = "apis/costreports/composition.yaml"
            xrdPath = "apis/costreports/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.CostReport {
                metadata.name = "my-account"
                spec = {
                    accountId = "123456789012"
                    region = "us-east-2"
                }
            }
            assertResources = [
                {
                    apiVersion = "s3.aws.m.upbound.io/v1beta1"
                    kind = "Bucket"
                    metadata.name = "my-account-cur"
                    metadata.annotations = {
                        "crossplane.io/external-name" = "my-account-cur"
                    }
                }
            ]
        }
    }

    # Test 2: Custom bucket name overrides default
    metav1alpha1.CompositionTest {
        metadata.name = "custom-bucket-name"
        spec = {
            compositionPath = "apis/costreports/composition.yaml"
            xrdPath = "apis/costreports/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.CostReport {
                metadata.name = "my-account"
                spec = {
                    accountId = "123456789012"
                    region = "us-east-2"
                    bucketName = "custom-cur-bucket"
                }
            }
            assertResources = [
                {
                    apiVersion = "s3.aws.m.upbound.io/v1beta1"
                    kind = "Bucket"
                    metadata.name = "my-account-cur"
                    metadata.annotations = {
                        "crossplane.io/external-name" = "custom-cur-bucket"
                    }
                }
            ]
        }
    }

    # Test 3: Report name converts dashes to underscores via external-name
    metav1alpha1.CompositionTest {
        metadata.name = "report-name-underscores"
        spec = {
            compositionPath = "apis/costreports/composition.yaml"
            xrdPath = "apis/costreports/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.CostReport {
                metadata.name = "my-account"
                spec = {
                    accountId = "123456789012"
                    region = "us-east-2"
                }
            }
            assertResources = [
                {
                    apiVersion = "cur.aws.m.upbound.io/v1beta1"
                    kind = "ReportDefinition"
                    metadata.name = "my-account-cur-report"
                    metadata.annotations = {
                        "crossplane.io/external-name" = "my_account_cur"
                    }
                }
            ]
        }
    }

    # Test 4: CUR report s3Region matches user region
    metav1alpha1.CompositionTest {
        metadata.name = "cur-s3-region-matches-user"
        spec = {
            compositionPath = "apis/costreports/composition.yaml"
            xrdPath = "apis/costreports/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.CostReport {
                metadata.name = "my-account"
                spec = {
                    accountId = "123456789012"
                    region = "eu-west-1"
                }
            }
            assertResources = [
                {
                    apiVersion = "cur.aws.m.upbound.io/v1beta1"
                    kind = "ReportDefinition"
                    metadata.name = "my-account-cur-report"
                    spec.forProvider.s3Region = "eu-west-1"
                }
            ]
        }
    }

    # Test 5: Glue database name converts dashes to underscores
    metav1alpha1.CompositionTest {
        metadata.name = "database-name-underscores"
        spec = {
            compositionPath = "apis/costreports/composition.yaml"
            xrdPath = "apis/costreports/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.CostReport {
                metadata.name = "my-account"
                spec = {
                    accountId = "123456789012"
                    region = "us-east-2"
                }
            }
            assertResources = [
                {
                    apiVersion = "glue.aws.m.upbound.io/v1beta1"
                    kind = "CatalogDatabase"
                    metadata.name = "my-account-cur-db"
                    metadata.annotations = {
                        "crossplane.io/external-name" = "my_account_cur"
                    }
                }
            ]
        }
    }

    # Test 6: Crawler references correct S3 path and database
    metav1alpha1.CompositionTest {
        metadata.name = "crawler-references"
        spec = {
            compositionPath = "apis/costreports/composition.yaml"
            xrdPath = "apis/costreports/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.CostReport {
                metadata.name = "my-account"
                spec = {
                    accountId = "123456789012"
                    region = "us-east-2"
                }
            }
            assertResources = [
                {
                    apiVersion = "glue.aws.m.upbound.io/v1beta1"
                    kind = "Crawler"
                    metadata.name = "my-account-cur-crawler"
                    spec.forProvider.databaseName = "my_account_cur"
                    spec.forProvider.s3Target = [
                        {path = "s3://my-account-cur/cur/my_account_cur/"}
                    ]
                }
            ]
        }
    }

    # Test 7: Athena workgroup outputs to correct S3 location
    metav1alpha1.CompositionTest {
        metadata.name = "athena-workgroup-output"
        spec = {
            compositionPath = "apis/costreports/composition.yaml"
            xrdPath = "apis/costreports/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.CostReport {
                metadata.name = "my-account"
                spec = {
                    accountId = "123456789012"
                    region = "us-east-2"
                }
            }
            assertResources = [
                {
                    apiVersion = "athena.aws.m.upbound.io/v1beta1"
                    kind = "Workgroup"
                    metadata.name = "my-account-cur-workgroup"
                    spec.forProvider.region = "us-east-2"
                }
            ]
        }
    }

    # Test 8: Custom tags are merged with defaults
    metav1alpha1.CompositionTest {
        metadata.name = "custom-tags-merged"
        spec = {
            compositionPath = "apis/costreports/composition.yaml"
            xrdPath = "apis/costreports/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.CostReport {
                metadata.name = "tagged"
                spec = {
                    accountId = "123456789012"
                    region = "us-east-2"
                    tags = {
                        environment = "production"
                        team = "platform"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "s3.aws.m.upbound.io/v1beta1"
                    kind = "Bucket"
                    metadata.name = "tagged-cur"
                    spec.forProvider.tags = {
                        "hops.ops.com.ai/managed" = "true"
                        "hops.ops.com.ai/costreport" = "tagged"
                        "Name" = "tagged-cur"
                        environment = "production"
                        team = "platform"
                    }
                }
            ]
        }
    }

    # Test 9: Crawler IAM role has correct trust policy
    metav1alpha1.CompositionTest {
        metadata.name = "crawler-role-trust-policy"
        spec = {
            compositionPath = "apis/costreports/composition.yaml"
            xrdPath = "apis/costreports/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.CostReport {
                metadata.name = "my-account"
                spec = {
                    accountId = "123456789012"
                    region = "us-east-2"
                }
            }
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "my-account-cur-crawler"
                }
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Policy"
                    metadata.name = "my-account-cur-crawler"
                }
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "RolePolicyAttachment"
                    metadata.name = "my-account-cur-crawler"
                }
            ]
        }
    }
]
items = _items
