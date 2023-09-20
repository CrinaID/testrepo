provider "aws" {
  region = var.region
}
resource "aws_kms_key" "state_backend_bucket_kms_key" {
  description             = "Encrypt the state bucket objects"
  deletion_window_in_days = 10
}
resource "aws_s3_bucket" "state_backend_bucket" {
  bucket = "dm-gen-configuration"

}
resource "aws_s3_bucket_versioning" "state_backend_bucket_versioning" {
  bucket  = aws_s3_bucket.state_backend_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "state_backend_bucket_encryption" {
  bucket = aws_s3_bucket.state_backend_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state_backend_bucket_kms_key.arn
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# block S3 bucket public access per each Env's bucket
resource "aws_s3_bucket_public_access_block" "state_backend_bucket_acl" {
  bucket = aws_s3_bucket.state_backend_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// DEVOPS ROLE

# Create an IAM policy
resource "aws_iam_policy" "devops_iam_policy" {
  name = var.devops_policy_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create an IAM role
resource "aws_iam_role" "devops_role" {
  name = var.devops_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [ 
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::855859226163:root"
        }
        Action = "sts:AssumeRole",
        Condition = {
            Bool: {
                "aws:MultiFactorAuthPresent": "true"
            }
        }
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_policy_attachment" "devops_role_policy_attachment" {
  name = "Policy Attachement"
  policy_arn = aws_iam_policy.devops_iam_policy.arn
  roles       = [aws_iam_role.devops_role.name]
}


// DEVELOPER ROLE

# Create an IAM policy
resource "aws_iam_policy" "developer_iam_policy" {
  name = var.developer_policy_name

  policy = jsonencode({

	Version: "2012-10-17",
	Statement= [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"logs:GetDataProtectionPolicy",
				"logs:GetLogRecord",
				"logs:GetQueryResults",
				"logs:StartQuery",
				"logs:Unmask",
				"logs:FilterLogEvents",
				"logs:GetLogGroupFields",
				"logs:DescribeLogStreams",
				"logs:DescribeLogGroups"
			],
			"Resource": "arn:aws:logs:eu-west-2:855859226163:log-group:/tmp/docker/mygroup:*"
		},
		{
			"Sid": "VisualEditor1",
			"Effect": "Allow",
			"Action": [
				"logs:GetLogEvents",
				"logs:DescribeLogGroups"
			],
			"Resource": "arn:aws:logs:eu-west-2:855859226163:log-group:/tmp/docker/mygroup:*"
		},
		{
			"Sid": "VisualEditor2",
			"Effect": "Allow",
			"Action": [
				"logs:DescribeLogGroups",
				"logs:StartLiveTail",
				"logs:StopLiveTail",
				"logs:StopQuery",
				"logs:TestMetricFilter",
				"logs:GetLogDelivery",
				"logs:DescribeQueryDefinitions"
			],
			"Resource": "*"
		},
		{
			"Sid": "VisualEditor3",
			"Effect": "Allow",
			"Action": [
				"logs:DescribeLogStreams",
				"logs:GetLogEvents",
				"logs:DescribeLogGroups"
			],
			"Resource": "arn:aws:logs:eu-west-2:855859226163:log-group:/tmp/dm/docker/applications:*"
		}
	]

  })
}

# Create an IAM role
resource "aws_iam_role" "developer_role" {
  name = var.developer_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [ 
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::855859226163:root"
        }
        Action = "sts:AssumeRole",
        Condition = {
            Bool: {
                "aws:MultiFactorAuthPresent": "true"
            }
        }
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_policy_attachment" "developer_role_policy_attachment" {
  name = "Policy Attachement"
  policy_arn = aws_iam_policy.developer_iam_policy.arn
  roles       = [aws_iam_role.developer_role.name]
}

// READONLY ROLE

# Create an IAM policy
resource "aws_iam_policy" "readonly_iam_policy" {
  name = var.readonly_policy_name

  policy = jsonencode({

    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "a4b:Get*",
                "a4b:List*",
                "a4b:Search*",
                "access-analyzer:GetAccessPreview",
                "access-analyzer:GetAnalyzedResource",
                "access-analyzer:GetAnalyzer",
                "access-analyzer:GetArchiveRule",
                "access-analyzer:GetFinding",
                "access-analyzer:GetGeneratedPolicy",
                "access-analyzer:ListAccessPreviewFindings",
                "access-analyzer:ListAccessPreviews",
                "access-analyzer:ListAnalyzedResources",
                "access-analyzer:ListAnalyzers",
                "access-analyzer:ListArchiveRules",
                "access-analyzer:ListFindings",
                "access-analyzer:ListPolicyGenerations",
                "access-analyzer:ListTagsForResource",
                "access-analyzer:ValidatePolicy",
                "account:GetAccountInformation",
                "account:GetAlternateContact",
                "account:GetChallengeQuestions",
                "account:GetContactInformation",
                "account:GetRegionOptStatus",
                "account:ListRegions",
                "acm-pca:Describe*",
                "acm-pca:Get*",
                "acm-pca:List*",
                "acm:Describe*",
                "acm:Get*",
                "acm:List*",
                "airflow:ListEnvironments",
                "airflow:ListTagsForResource",
                "amplify:GetApp",
                "amplify:GetBranch",
                "amplify:GetDomainAssociation",
                "amplify:GetJob",
                "amplify:ListApps",
                "amplify:ListBranches",
                "amplify:ListDomainAssociations",
                "amplify:ListJobs",
                "aoss:BatchGetCollection",
                "aoss:BatchGetVpcEndpoint",
                "aoss:GetAccessPolicy",
                "aoss:GetAccountSettings",
                "aoss:GetPoliciesStats",
                "aoss:GetSecurityConfig",
                "aoss:GetSecurityPolicy",
                "aoss:ListAccessPolicies",
                "aoss:ListCollections",
                "aoss:ListSecurityConfigs",
                "aoss:ListSecurityPolicies",
                "aoss:ListTagsForResource",
                "aoss:ListVpcEndpoints",
                "apigateway:GET",
                "appconfig:GetApplication",
                "appconfig:GetConfiguration",
                "appconfig:GetConfigurationProfile",
                "appconfig:GetDeployment",
                "appconfig:GetDeploymentStrategy",
                "appconfig:GetEnvironment",
                "appconfig:GetHostedConfigurationVersion",
                "appconfig:ListApplications",
                "appconfig:ListConfigurationProfiles",
                "appconfig:ListDeployments",
                "appconfig:ListDeploymentStrategies",
                "appconfig:ListEnvironments",
                "appconfig:ListHostedConfigurationVersions",
                "appconfig:ListTagsForResource",
                "appfabric:GetAppAuthorization",
                "appfabric:GetAppBundle",
                "appfabric:GetIngestion",
                "appfabric:GetIngestionDestination",
                "appfabric:ListAppAuthorizations",
                "appfabric:ListAppBundles",
                "appfabric:ListIngestionDestinations",
                "appfabric:ListIngestions",
                "appfabric:ListTagsForResource",
                "appflow:DescribeConnector",
                "appflow:DescribeConnectorEntity",
                "appflow:DescribeConnectorFields",
                "appflow:DescribeConnectorProfiles",
                "appflow:DescribeConnectors",
                "appflow:DescribeFlow",
                "appflow:DescribeFlowExecution",
                "appflow:DescribeFlowExecutionRecords",
                "appflow:DescribeFlows",
                "appflow:ListConnectorEntities",
                "appflow:ListConnectorFields",
                "appflow:ListConnectors",
                "appflow:ListFlows",
                "appflow:ListTagsForResource",
                "application-autoscaling:Describe*",
                "application-autoscaling:ListTagsForResource",
                "applicationinsights:Describe*",
                "applicationinsights:List*",
                "appmesh:Describe*",
                "appmesh:List*",
                "apprunner:DescribeAutoScalingConfiguration",
                "apprunner:DescribeCustomDomains",
                "apprunner:DescribeObservabilityConfiguration",
                "apprunner:DescribeService",
                "apprunner:DescribeVpcConnector",
                "apprunner:DescribeVpcIngressConnection",
                "apprunner:ListAutoScalingConfigurations",
                "apprunner:ListConnections",
                "apprunner:ListObservabilityConfigurations",
                "apprunner:ListOperations",
                "apprunner:ListServices",
                "apprunner:ListTagsForResource",
                "apprunner:ListVpcConnectors",
                "apprunner:ListVpcIngressConnections",
                "appstream:Describe*",
                "appstream:List*",
                "appsync:Get*",
                "appsync:List*",
                "aps:DescribeAlertManagerDefinition",
                "aps:DescribeLoggingConfiguration",
                "aps:DescribeRuleGroupsNamespace",
                "aps:DescribeWorkspace",
                "aps:GetAlertManagerSilence",
                "aps:GetAlertManagerStatus",
                "aps:GetLabels",
                "aps:GetMetricMetadata",
                "aps:GetSeries",
                "aps:ListAlertManagerAlertGroups",
                "aps:ListAlertManagerAlerts",
                "aps:ListAlertManagerReceivers",
                "aps:ListAlertManagerSilences",
                "aps:ListAlerts",
                "aps:ListRuleGroupsNamespaces",
                "aps:ListRules",
                "aps:ListTagsForResource",
                "aps:ListWorkspaces",
                "aps:QueryMetrics",
                "arc-zonal-shift:GetManagedResource",
                "arc-zonal-shift:ListManagedResources",
                "arc-zonal-shift:ListZonalShifts",
                "artifact:GetReport",
                "artifact:GetReportMetadata",
                "artifact:GetTermForReport",
                "artifact:ListReports",
                "athena:Batch*",
                "athena:Get*",
                "athena:List*",
          
       
                "autoscaling-plans:Describe*",
                "autoscaling-plans:GetScalingPlanResourceForecastData",
                "autoscaling:Describe*",
                "autoscaling:GetPredictiveScalingForecast",
                "aws-portal:View*",
                "backup-gateway:ListGateways",
                "backup-gateway:ListHypervisors",
                "backup-gateway:ListTagsForResource",
                "backup-gateway:ListVirtualMachines",
                "backup:Describe*",
                "backup:Get*",
                "backup:List*",
                "batch:Describe*",
                "batch:List*",
                "billing:GetBillingData",
                "billing:GetBillingDetails",
                "billing:GetBillingNotifications",
                "billing:GetBillingPreferences",
                "billing:GetContractInformation",
                "billing:GetCredits",
                "billing:GetIAMAccessPreference",
                "billing:GetSellerOfRecord",
                "billing:ListBillingViews",
                "billingconductor:ListAccountAssociations",
                "billingconductor:ListBillingGroupCostReports",
                "billingconductor:ListBillingGroups",
                "billingconductor:ListCustomLineItems",
                "billingconductor:ListCustomLineItemVersions",
                "billingconductor:ListPricingPlans",
                "billingconductor:ListPricingPlansAssociatedWithPricingRule",
                "billingconductor:ListPricingRules",
                "billingconductor:ListPricingRulesAssociatedToPricingPlan",
                "billingconductor:ListResourcesAssociatedToCustomLineItem",
                "billingconductor:ListTagsForResource",
                
         
             
          
     
                
                "directconnect:Describe*",
                "discovery:Describe*",
                "discovery:Get*",
                "discovery:List*",
                "dlm:Get*",
                "dms:Describe*",
                "dms:List*",
                "dms:Test*",
                "drs:DescribeJobLogItems",
                "drs:DescribeJobs",
                "drs:DescribeLaunchConfigurationTemplates",
                "drs:DescribeRecoveryInstances",
                "drs:DescribeRecoverySnapshots",
                "drs:DescribeReplicationConfigurationTemplates",
                "drs:DescribeSourceNetworks",
                "drs:DescribeSourceServers",
                "drs:GetFailbackReplicationConfiguration",
                "drs:GetLaunchConfiguration",
                "drs:GetReplicationConfiguration",
                "drs:ListExtensibleSourceServers",
                "drs:ListLaunchActions",
                "drs:ListStagingAccounts",
                "drs:ListTagsForResource",
                "ds:Check*",
                "ds:Describe*",
                "ds:Get*",
                "ds:List*",
                "ds:Verify*",
                "dynamodb:BatchGet*",
                "dynamodb:Describe*",
                "dynamodb:Get*",
                "dynamodb:List*",
                "dynamodb:PartiQLSelect",
                "dynamodb:Query",
                "dynamodb:Scan",
                "ec2:Describe*",
                "ec2:Get*",
                "ec2:ListImagesInRecycleBin",
                "ec2:ListSnapshotsInRecycleBin",
                "ec2:SearchLocalGatewayRoutes",
                "ec2:SearchTransitGatewayRoutes",
                "ec2messages:Get*",
                "ecr-public:BatchCheckLayerAvailability",
                "ecr-public:DescribeImages",
                "ecr-public:DescribeImageTags",
                "ecr-public:DescribeRegistries",
                "ecr-public:DescribeRepositories",
                "ecr-public:GetAuthorizationToken",
                "ecr-public:GetRegistryCatalogData",
                "ecr-public:GetRepositoryCatalogData",
                "ecr-public:GetRepositoryPolicy",
                "ecr-public:ListTagsForResource",
                "ecr:BatchCheck*",
                "ecr:BatchGet*",
                "ecr:Describe*",
                "ecr:Get*",
                "ecr:List*",
                "ecs:Describe*",
                "ecs:List*",
                "eks:Describe*",
                "eks:List*",
                "elastic-inference:DescribeAcceleratorOfferings",
                "elastic-inference:DescribeAccelerators",
                "elastic-inference:DescribeAcceleratorTypes",
                "elastic-inference:ListTagsForResource",
                "elasticache:Describe*",
                "elasticache:List*",
                "elasticbeanstalk:Check*",
                "elasticbeanstalk:Describe*",
                "elasticbeanstalk:List*",
                "elasticbeanstalk:Request*",
                "elasticbeanstalk:Retrieve*",
                "elasticbeanstalk:Validate*",
                "elasticfilesystem:Describe*",
                "elasticfilesystem:ListTagsForResource",
                "elasticloadbalancing:Describe*",
                "elasticmapreduce:Describe*",
                "elasticmapreduce:GetBlockPublicAccessConfiguration",
                "elasticmapreduce:List*",
                "elasticmapreduce:View*",
                "elastictranscoder:List*",
                "elastictranscoder:Read*",
                "elemental-appliances-software:Get*",
                "elemental-appliances-software:List*",
                "emr-containers:DescribeJobRun",
                "emr-containers:DescribeManagedEndpoint",
                "emr-containers:DescribeVirtualCluster",
                "emr-containers:ListJobRuns",
                "emr-containers:ListManagedEndpoints",
                "emr-containers:ListTagsForResource",
                "emr-containers:ListVirtualClusters",
                "emr-serverless:GetApplication",
                "emr-serverless:GetDashboardForJobRun",
                "emr-serverless:GetJobRun",
                "emr-serverless:ListApplications",
                "emr-serverless:ListJobRuns",
                "emr-serverless:ListTagsForResource",
                
                "iam:Generate*",
                "iam:Get*",
                "iam:List*",
                "iam:Simulate*",
                "identity-sync:GetSyncProfile",
                "identity-sync:GetSyncTarget",
                "identity-sync:ListSyncFilters",
                "identitystore-auth:BatchGetSession",
                "identitystore-auth:ListSessions",
                "identitystore:DescribeGroup",
                "identitystore:DescribeGroupMembership",
                "identitystore:DescribeUser",
                "identitystore:GetGroupId",
                "identitystore:GetGroupMembershipId",
                "identitystore:GetUserId",
                "identitystore:IsMemberInGroups",
                "identitystore:ListGroupMemberships",
                "identitystore:ListGroupMembershipsForMember",
                "identitystore:ListGroups",
                "identitystore:ListUsers",
                "imagebuilder:Get*",
                "imagebuilder:List*",
                "importexport:Get*",
                "importexport:List*",
                "inspector:Describe*",
                "inspector:Get*",
                "inspector:List*",
                "inspector:Preview*",
                "inspector2:BatchGetAccountStatus",
                "inspector2:BatchGetFreeTrialInfo",
                "inspector2:DescribeOrganizationConfiguration",
                "inspector2:GetDelegatedAdminAccount",
                "inspector2:GetFindingsReportStatus",
                "inspector2:GetMember",
                "inspector2:ListAccountPermissions",
                "inspector2:ListCoverage",
                "inspector2:ListCoverageStatistics",
                "inspector2:ListDelegatedAdminAccounts",
                "inspector2:ListFilters",
                "inspector2:ListFindingAggregations",
                "inspector2:ListFindings",
                "inspector2:ListMembers",
                "inspector2:ListTagsForResource",
                "inspector2:ListUsageTotals",
                "internetmonitor:GetHealthEvent",
                "internetmonitor:GetMonitor",
                "internetmonitor:ListHealthEvents",
                "internetmonitor:ListMonitors",
                "internetmonitor:ListTagsForResource",
                "invoicing:GetInvoiceEmailDeliveryPreferences",
                "invoicing:GetInvoicePDF",
                "invoicing:ListInvoiceSummaries",
                
                
                "kms:Describe*",
                "kms:Get*",
                "kms:List*",
                "lambda:Get*",
                "lambda:List*",
                "launchwizard:DescribeAdditionalNode",
                "launchwizard:DescribeProvisionedApp",
                "launchwizard:DescribeProvisioningEvents",
                "launchwizard:DescribeSettingsSet",
                "launchwizard:GetInfrastructureSuggestion",
                "launchwizard:GetIpAddress",
                "launchwizard:GetResourceCostEstimate",
                "launchwizard:GetWorkloadAssets",
                "launchwizard:ListAdditionalNodes",
                "launchwizard:ListProvisionedApps",
                "launchwizard:ListSettingsSets",
                "launchwizard:ListWorkloadDeploymentOptions",
                "launchwizard:ListWorkloads",
                
                "license-manager:Get*",
                "license-manager:List*",
                
                "logs:Describe*",
                "logs:FilterLogEvents",
                "logs:Get*",
                "logs:ListTagsForResource",
                "logs:ListTagsLogGroup",
                "logs:StartLiveTail",
                "logs:StartQuery",
                "logs:StopLiveTail",
                "logs:StopQuery",
                "logs:TestMetricFilter",
                

                "network-firewall:DescribeFirewall",
                "network-firewall:DescribeFirewallPolicy",
                "network-firewall:DescribeLoggingConfiguration",
                "network-firewall:DescribeResourcePolicy",
                "network-firewall:DescribeRuleGroup",
                "network-firewall:DescribeRuleGroupMetadata",
                "network-firewall:DescribeTLSInspectionConfiguration",
                "network-firewall:ListFirewallPolicies",
                "network-firewall:ListFirewalls",
                "network-firewall:ListRuleGroups",
                "network-firewall:ListTagsForResource",
                "network-firewall:ListTLSInspectionConfigurations",
                "networkmanager:DescribeGlobalNetworks",
                "networkmanager:GetConnectAttachment",
                "networkmanager:GetConnections",
                "networkmanager:GetConnectPeer",
                "networkmanager:GetConnectPeerAssociations",
                "networkmanager:GetCoreNetwork",
                "networkmanager:GetCoreNetworkChangeEvents",
                "networkmanager:GetCoreNetworkChangeSet",
                "networkmanager:GetCoreNetworkPolicy",
                "networkmanager:GetCustomerGatewayAssociations",
                "networkmanager:GetDevices",
                "networkmanager:GetLinkAssociations",
                "networkmanager:GetLinks",
                "networkmanager:GetNetworkResourceCounts",
                "networkmanager:GetNetworkResourceRelationships",
                "networkmanager:GetNetworkResources",
                "networkmanager:GetNetworkRoutes",
                "networkmanager:GetNetworkTelemetry",
                "networkmanager:GetResourcePolicy",
                "networkmanager:GetRouteAnalysis",
                "networkmanager:GetSites",
                "networkmanager:GetSiteToSiteVpnAttachment",
                "networkmanager:GetTransitGatewayConnectPeerAssociations",
                "networkmanager:GetTransitGatewayPeering",
                "networkmanager:GetTransitGatewayRegistrations",
                "networkmanager:GetTransitGatewayRouteTableAttachment",
                "networkmanager:GetVpcAttachment",
                "networkmanager:ListAttachments",
                "networkmanager:ListConnectPeers",
                "networkmanager:ListCoreNetworkPolicyVersions",
                "networkmanager:ListCoreNetworks",
                "networkmanager:ListPeerings",
                "networkmanager:ListTagsForResource",
               
                "resource-groups:Get*",
                "resource-groups:List*",
                "resource-groups:Search*",
                "robomaker:BatchDescribe*",
                "robomaker:Describe*",
                "robomaker:Get*",
                "robomaker:List*",
                "route53-recovery-cluster:Get*",
                "route53-recovery-cluster:ListRoutingControls",
                "route53-recovery-control-config:Describe*",
                "route53-recovery-control-config:List*",
                "route53-recovery-readiness:Get*",
                "route53-recovery-readiness:List*",
                "route53:Get*",
                "route53:List*",
                "route53:Test*",
                "route53domains:Check*",
                "route53domains:Get*",
                "route53domains:List*",
                "route53domains:View*",
                "route53resolver:Get*",
                "route53resolver:List*",
                "rum:GetAppMonitor",
                "rum:GetAppMonitorData",
                "rum:ListAppMonitors",
                "s3-object-lambda:GetObject",
                "s3-object-lambda:GetObjectAcl",
                "s3-object-lambda:GetObjectLegalHold",
                "s3-object-lambda:GetObjectRetention",
                "s3-object-lambda:GetObjectTagging",
                "s3-object-lambda:GetObjectVersion",
                "s3-object-lambda:GetObjectVersionAcl",
                "s3-object-lambda:GetObjectVersionTagging",
                "s3-object-lambda:ListBucket",
                "s3-object-lambda:ListBucketMultipartUploads",
                "s3-object-lambda:ListBucketVersions",
                "s3-object-lambda:ListMultipartUploadParts",
                "s3:DescribeJob",
                "s3:Get*",
                "s3:List*",
                
                "sagemaker:Search",
                "savingsplans:DescribeSavingsPlanRates",
                "savingsplans:DescribeSavingsPlans",
                "savingsplans:DescribeSavingsPlansOfferingRates",
                "savingsplans:DescribeSavingsPlansOfferings",
                "savingsplans:ListTagsForResource",
                "scheduler:GetSchedule",
                "scheduler:GetScheduleGroup",
                "scheduler:ListScheduleGroups",
                "scheduler:ListSchedules",
                "scheduler:ListTagsForResource",
                "schemas:Describe*",
                "schemas:Get*",
                "schemas:List*",
                "schemas:Search*",
                "sdb:Get*",
                "sdb:List*",
                "sdb:Select*",
                "secretsmanager:Describe*",
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:List*",
                
                
                "ssm-contacts:DescribeEngagement",
                "ssm-contacts:DescribePage",
                "ssm-contacts:GetContact",
                "ssm-contacts:GetContactChannel",
                "ssm-contacts:ListContactChannels",
                "ssm-contacts:ListContacts",
                "ssm-contacts:ListEngagements",
                "ssm-contacts:ListPageReceipts",
                "ssm-contacts:ListPagesByContact",
                "ssm-contacts:ListPagesByEngagement",
                "ssm-incidents:GetIncidentRecord",
                "ssm-incidents:GetReplicationSet",
                "ssm-incidents:GetResourcePolicies",
                "ssm-incidents:GetResponsePlan",
                "ssm-incidents:GetTimelineEvent",
                "ssm-incidents:ListIncidentRecords",
                "ssm-incidents:ListRelatedItems",
                "ssm-incidents:ListReplicationSets",
                "ssm-incidents:ListResponsePlans",
                "ssm-incidents:ListTagsForResource",
                "ssm-incidents:ListTimelineEvents",
                "ssm:Describe*",
                "ssm:Get*",
                "ssm:List*",
                "sso-directory:Describe*",
                "sso-directory:List*",
                "sso-directory:Search*",
                "sso:Describe*",
                "sso:Get*",
                "sso:List*",
                "sso:Search*",
                "states:Describe*",
                "states:GetExecutionHistory",
                "states:List*",
                "storagegateway:Describe*",
                "storagegateway:List*",
                "sts:GetAccessKeyInfo",
                "sts:GetCallerIdentity",
                "sts:GetSessionToken",
                
                "vpc-lattice:GetAccessLogSubscription",
                "vpc-lattice:GetAuthPolicy",
                "vpc-lattice:GetListener",
                "vpc-lattice:GetResourcePolicy",
                "vpc-lattice:GetRule",
                "vpc-lattice:GetService",
                "vpc-lattice:GetServiceNetwork",
                "vpc-lattice:GetServiceNetworkServiceAssociation",
                "vpc-lattice:GetServiceNetworkVpcAssociation",
                "vpc-lattice:GetTargetGroup",
                "vpc-lattice:ListAccessLogSubscriptions",
                "vpc-lattice:ListListeners",
                "vpc-lattice:ListRules",
                "vpc-lattice:ListServiceNetworks",
                "vpc-lattice:ListServiceNetworkServiceAssociations",
                "vpc-lattice:ListServiceNetworkVpcAssociations",
                "vpc-lattice:ListServices",
                "vpc-lattice:ListTagsForResource",
                "vpc-lattice:ListTargetGroups",
                "vpc-lattice:ListTargets",
                "waf-regional:Get*",
                "waf-regional:List*",
                "waf:Get*",
                "waf:List*",
                "wafv2:CheckCapacity",
                "wafv2:Describe*",
                "wafv2:Get*",
                "wafv2:List*",
               
            ],
            "Resource": "*"
        }
    ]

  })
}

# Create an IAM role
resource "aws_iam_role" "readonly_role" {
  name = var.readonly_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [ 
      {
        Effect = "Allow"
        Principal = {
          Service = "arn:aws:iam::855859226163:root"
        }
        Action = "sts:AssumeRole",
        Condition = {
            Bool: {
                "aws:MultiFactorAuthPresent": "true"
            }
        }
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_policy_attachment" "readonly_role_policy_attachment" {
  name = "Policy Attachement"
  policy_arn = aws_iam_policy.readonly_iam_policy.arn
  roles       = [aws_iam_role.readonly_role.name]
}
