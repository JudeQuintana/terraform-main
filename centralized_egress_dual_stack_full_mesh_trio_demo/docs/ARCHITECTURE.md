# Centralized Egress Dual Stack Full Mesh Trio Architecture

## Executive Summary

This architecture demonstrates a **production-grade, self-organizing multi-region VPC mesh** that transforms infrastructure configuration from O(n²) imperative Terraform to O(n) automated Terraform through composable pure function modules. It manages **9 VPCs across 3 AWS regions** with:

- **92% code reduction**: 174 lines vs. ~2,000 lines of imperative Terraform (measured)
- **67% cost savings**: Centralized NAT Gateway architecture ($4,730/year measured)
- **120× faster deployment**: 15.75 minutes vs. 31.2 hours for 9-VPC setup (development + deployment)
  - Terraform v1.11.4 + M1 ARM architecture + AWS Provider v5.95.0
  - 1,308 resources in 12.55 minutes terraform apply time
- **Near-zero errors**: Mathematical generation eliminates manual mistakes

**Note:** References to "measured in Section 7" refer to evaluation metrics documented in the companion WHITEPAPER.md (Section 7: Evaluation).

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Three-Region Full Mesh                       │
│                                                                 │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐   │
│  │  us-east-1   │◄────►│  us-east-2   │◄────►│  us-west-2   │   │
│  │              │      │              │      │              │   │
│  │  3 VPCs      │      │  3 VPCs      │      │  3 VPCs      │   │
│  │  - app3      │      │  - app1      │      │  - app2      │   │
│  │  - infra3    │      │  - infra1    │      │  - infra2    │   │
│  │  - general3  │      │  - general1  │      │  - general2  │   │
│  │    (egress)  │      │    (egress)  │      │    (egress)  │   │
│  └──────────────┘      └──────────────┘      └──────────────┘   │
│         │                      │                      │         │
│         └──────────────────────┴──────────────────────┘         │
│                    TGW Peering (50 Gbps each)                   │
└─────────────────────────────────────────────────────────────────┘

Regional Architecture (per region):
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  App VPC          Infra VPC        Egress VPC (General)         │
│  ┌────────┐      ┌────────┐       ┌──────────────────┐          │
│  │Private │      │Private │       │Private │ Public  │          │
│  │Subnets │      │Subnets │       │Subnets │ + NAT GW│          │
│  └───┬────┘      └───┬────┘       └───┬────┴─────┬───┘          │
│      │               │                │          │              │
│      └───────────────┴────────────────┘          │              │
│                      │                           │              │
│                 ┌────▼────┐                      │              │
│                 │   TGW   │                      │              │
│                 └────┬────┘                      │              │
│                      │                           │              │
│           0.0.0.0/0 route to TGW        0.0.0.0/0 to Internet   │
│           (centralized egress)          (IPv4 via NAT GW)       │
│                                          (IPv6 via EIGW)        │
└─────────────────────────────────────────────────────────────────┘
```

## Key Design Principles

### 1. **Composition Over Configuration**
- Small, focused modules that compose into complex topologies
- Each module has a single responsibility
- Output of one module feeds input of another

### 2. **Declarative Infrastructure**
- Describe desired state (VPC topology), not steps (individual resource blocks)
- Pure function modules generate resources programmatically
- Idempotent operations with mathematical correctness guarantees

### 3. **Cost-Aware Architecture**
- Centralized vs. decentralized decisions based on cost model
- Hybrid connectivity (TGW + VPC Peering)
- AZ-aware traffic routing

### 4. **Security by Default**
- Automatic security group rule generation
- Intra-VPC security groups for all VPCs
- Stateful firewall optimization

### 5. **Scalability Through Abstraction**
- O(n) configuration generates O(n²) resources (vs imperative O(n²) resource blocks)
- Pure function transformations prevent manual authoring errors
- Adding VPCs requires 15 lines (vs 100+ imperative resource blocks)

## Module Architecture

### Core Modules

#### **Tiered VPC-NG**
- **Purpose**: IPAM-driven VPC creation with flexible subnet patterns
- **Input**: VPC specification (network CIDRs, AZs, subnet definitions)
- **Output**: Complete VPC with route tables, subnets, security groups
- **Innovation**: Supports primary + secondary CIDRs for both IPv4 and IPv6
- **Repository**: [terraform-aws-tiered-vpc-ng](https://github.com/JudeQuintana/terraform-aws-tiered-vpc-ng)

**Default DNS Configuration:**

All VPCs are created with DNS enabled by default:
- `enable_dns_support = true` (enables AWS DNS resolver at VPC+2 address)
- `enable_dns_hostnames = true` (assigns public DNS hostnames to EC2 instances)

These defaults are critical for:
- Private DNS resolution between VPCs in the mesh
- EC2 instance hostname assignment and service discovery
- VPC Peering DNS resolution (when `allow_remote_vpc_dns_resolution = true`)
- Simplified microservices communication using DNS names instead of IP addresses

```hcl
module "vpcs_use1" {
  source = "JudeQuintana/tiered-vpc-ng/aws"

  for_each = { for t in local.tiered_vpcs : t.name => t }
  tiered_vpc = each.value
}
```

**Subnet Types:**

Tiered VPC-NG supports three subnet patterns, each with distinct routing behavior:

| Subnet Type | Internet Routing | Use Cases | Route Table Scope |
|-------------|-----------------|-----------|-------------------|
| **Private** | Via NAT Gateway (IPv4) or EIGW (IPv6) | Application tiers, worker nodes with internet access | Per-AZ |
| **Public** | Via Internet Gateway (IPv4/IPv6) | Load balancers, bastion hosts, NAT Gateways | Shared across VPC |
| **Isolated** | **No internet routes** | Kubernetes nodes, databases, air-gapped workloads | Per-AZ |

**Isolated Subnets** are particularly useful for:
- **Kubernetes clusters**: Worker nodes that only need mesh connectivity (tag subnets for EKS/Karpenter discovery)
- **Database tiers**: Read replicas and internal databases with no external access requirements
- **Compliance workloads**: HIPAA, PCI-DSS, or other regulations requiring network isolation
- **Internal services**: Microservices that communicate only within the mesh
- **Secrets management**: HashiCorp Vault, AWS Secrets Manager endpoints
- **Data processing**: Spark clusters, data pipelines that only access S3 via VPC endpoints

**Key characteristics:**
- Isolated subnets receive **only** mesh routes (VPC local + Transit Gateway routes)
- No `0.0.0.0/0` or `::/0` default routes are added
- Can be dual-stack (IPv4 + IPv6)
- Participate fully in mesh networking via Transit Gateway
- Have dedicated route tables per AZ (not shared with private/public)
- **No automatic route table creation for internet access** — completely air-gapped from public internet

**Configuration Example:**
```hcl
azs = {
  a = {
    isolated_subnets = [
      { name = "db11", cidr = "172.18.9.0/24", ipv6_cidr = "2600:1f28:3d:c880::/60" },
      { name = "secrets", cidr = "172.18.10.0/24", ipv6_cidr = "2600:1f28:3d:c890::/60" }
    ]
  }
}
```

**Routing Behavior:**
- ✅ Can reach other VPCs in the mesh via TGW
- ✅ Can reach other subnets in same VPC
- ❌ Cannot reach public internet (no NAT GW, no IGW, no EIGW routes)
- ❌ Cannot be reached from public internet

This provides **maximum security** for data plane workloads that should never have internet exposure, even accidental.

#### **Centralized Router**
- **Purpose**: Regional TGW mesh with intelligent route generation
- **Input**: Map of VPCs, centralized egress configuration
- **Output**: TGW + attachments + routes
- **Innovation**: Embedded `generate_routes_to_other_vpcs` function module

```hcl
module "centralized_router_use1" {
  source = "JudeQuintana/centralized-router/aws"

  centralized_router = {
    name = "mystique"
    vpcs = module.vpcs_use1
  }
}
```

##### **generate_routes_to_other_vpcs (Embedded Function Module)**
- **Type**: Pure function (zero resources)
- **Input**: Map of VPC objects
- **Output**: `toset([{route_table_id, destination_cidr_block}, ...])`
- **Mathematics**: Generates N×(N-1) routes automatically
- **Innovation**: First-class functional approach to relationship generation
- **Theory**: Mirrors compiler IR transforms (see [COMPILER_TRANSFORM_ANALOGY.md](./COMPILER_TRANSFORM_ANALOGY.md))

#### **Full Mesh Trio**
- **Purpose**: Cross-region TGW peering orchestration with automatic route propagation
- **Input**: Three centralized router modules (one per region)
- **Output**: 3 TGW peering connections + bidirectional cross-region routes + route table associations
- **Innovation**: Automatic transitive routing across 3 regions with comprehensive validation
- **Repository**: [terraform-aws-full-mesh-trio](https://github.com/JudeQuintana/terraform-aws-full-mesh-trio)

```hcl
module "full_mesh_trio" {
  source = "JudeQuintana/full-mesh-trio/aws"

  # Multi-provider configuration (one per region)
  providers = {
    aws.one   = aws.use1
    aws.two   = aws.use2
    aws.three = aws.usw2
  }

  full_mesh_trio = {
    one   = { centralized_router = module.centralized_router_use1 }
    two   = { centralized_router = module.centralized_router_use2 }
    three = { centralized_router = module.centralized_router_usw2 }
  }
}
```

**What Full Mesh Trio Creates:**

| Component | Count | Description |
|-----------|-------|-------------|
| **TGW Peering Attachments** | 3 | one↔two, two↔three, three↔one |
| **Peering Accepters** | 3 | Automatic cross-region acceptance |
| **TGW Route Table Associations** | 6 | Each peering associated with both TGW route tables |
| **TGW Routes (IPv4)** | 6 sets | Routes to remote VPC CIDRs (primary + secondary) |
| **TGW Routes (IPv6)** | 6 sets | Routes to remote VPC IPv6 CIDRs (primary + secondary) |
| **VPC Routes (IPv4)** | 6 sets | Routes in all VPC route tables to remote VPCs |
| **VPC Routes (IPv6)** | 6 sets | IPv6 routes in all VPC route tables |

**Total resources per deployment:** ~150+ (varies with VPC count and CIDR complexity)

**Key Features:**

1. **Comprehensive Validation**: Extensive preconditions ensure:
   - TGW names are unique across regions
   - VPC names are unique across regions
   - CIDRs don't overlap (IPv4 and IPv6, primary and secondary)
   - All regions have compatible configurations

2. **Dual-Stack Support**: Handles both IPv4 and IPv6 with:
   - Primary network CIDRs
   - Secondary CIDRs (for CIDR expansion)
   - Separate route resources for each IP version

3. **Automatic Bidirectional Routing**: Creates routes in 6 directions:
   - Region 1 → Region 2 (and reverse)
   - Region 2 → Region 3 (and reverse)
   - Region 3 → Region 1 (and reverse)

4. **Transitive Routing**: VPC in Region 1 can reach VPC in Region 3 via:
   - Direct path: use1 → usw2 peering (1 hop)
   - Indirect path: use1 → use2 → usw2 (2 hops, if preferred by BGP)

5. **Zero Manual Coordination**: No manual peering acceptance or route table updates required

#### **Intra-VPC Security Group Rules**
- **Purpose**: Regional security group rule generation with self-exclusion
- **Input**: Rule definition + all VPCs in region
- **Output**: N×(N-1) security group rules per protocol
- **Innovation**: Self-exclusion algorithm (VPC doesn't allow traffic from itself)

```hcl
module "intra_vpc_security_group_rules_use1" {
  source = "JudeQuintana/intra-vpc-security-group-rule/aws"

  for_each = local.intra_vpc_security_group_rules

  intra_vpc_security_group_rule = {
    rule = each.value  # Single protocol
    vpcs = module.vpcs_use1  # All VPCs
  }
}
```

#### **Full Mesh Intra-VPC Security Group Rules**
- **Purpose**: Cross-region security group rule coordination
- **Input**: Three regional intra-VPC security group rule modules
- **Output**: Bidirectional security group rules between all region pairs
- **Innovation**: Six cross-region rule operations (one→two, one→three, etc.)

```hcl
module "full_mesh_intra_vpc_security_group_rules" {
  source = "JudeQuintana/full-mesh-intra-vpc-security-group-rules/aws"

  full_mesh_intra_vpc_security_group_rules = {
    one   = { intra_vpc_security_group_rules = module.intra_vpc_sg_rules_use1 }
    two   = { intra_vpc_security_group_rules = module.intra_vpc_sg_rules_use2 }
    three = { intra_vpc_security_group_rules = module.intra_vpc_sg_rules_usw2 }
  }
}
```

#### **VPC Peering Deluxe**
- **Purpose**: Selective high-bandwidth paths with granular routing
- **Input**: Two VPCs + optional subnet-level routing restrictions
- **Output**: VPC peering + bidirectional routes
- **Innovation**: `only_route` feature for micro-segmentation

```hcl
module "vpc_peering_deluxe_usw2_app2_to_general2" {
  source = "JudeQuintana/vpc-peering-deluxe/aws"

  vpc_peering_deluxe = {
    local = { vpc = lookup(module.vpcs_usw2, "app2") }
    peer  = { vpc = lookup(module.vpcs_usw2, "general2") }
  }
}
```

## Module Dependency Graph

```
Tiered VPC-NG (9 VPCs)
    ↓
├─── Centralized Router (per region)
│    └─── generate_routes_to_other_vpcs (embedded)
│         └─── Generates N² routes from N VPCs
│
├─── Intra-VPC Security Group Rules (per region, per protocol)
│    └─── Generates N×(N-1) rules with self-exclusion
│
└─── (VPC outputs feed both paths)

Regional Outputs Feed Cross-Region Modules:
    ↓
├─── Full Mesh Trio
│    └─── Creates 3 TGW peerings + cross-region routes
│
└─── Full Mesh Intra-VPC Security Group Rules
     └─── Creates 6 bidirectional rule sets

Optional Layer:
VPC Peering Deluxe
└─── Direct VPC-to-VPC bypass for high-volume paths
```

## Configuration Pattern

### Current Deployment (9 VPCs, 3 Regions)

```
Configuration Lines: 174 (measured)
Generated Resources: 1,308 (measured deployment)
  - Theoretical capacity: ~1,800 resources
  - Utilization: 73% (optimized configuration)
Amplification Factor: 7.5× measured (10.3× at full capacity)

Route Entries: 852 (measured)
  - Theoretical capacity: 1,152 routes
  - Utilization: 74% (reflects actual routing needs)
Security Group Rules: 108 (measured)
  - Theoretical capacity: 432 rules
  - Utilization: 25% (selective protocol deployment)
NAT Gateways: 6 (centralized, constant with respect to VPC count)
TGW Attachments: 12 (9 VPC + 3 peerings)
```

### Scaling Characteristics

```
VPCs    Config Lines    Resources (capacity)    Deploy Time    Dev+Deploy Time
  3          60               ~600                 5-6 min        N/A
  6         105             ~1,200                 9-11 min       N/A
  9         174             ~1,800 (1,308 measured) 15.75 min     31.2 hrs (imperative)
 12         195             ~2,400                20-22 min       N/A
 15         240             ~3,000                25-28 min       N/A

Pattern: O(n) configuration for O(n²) relationships
Note: Config lines = VPC definitions (~15-20 per VPC) + regional/cross-region setup (~15-39 lines)
Deploy time measured with Terraform v1.11.4, M1 ARM, local state
```

## Centralized Egress Architecture

### Concept

Instead of every VPC having NAT Gateways (expensive), designate **one egress VPC per region** with centralized NAT Gateways. Private VPCs route internet-bound traffic through TGW to egress VPC NAT Gateways.

### Configuration

**Egress VPC:**
```hcl
centralized_egress = {
  central = true  # This VPC is the egress point
}

# Validation enforces:
# - Must have NAT Gateway per AZ
# - Must have private subnet with special = true per AZ
```

**Private VPCs:**
```hcl
centralized_egress = {
  private = true  # This VPC uses centralized egress
}

# Validation enforces:
# - Cannot have NAT Gateway
# - Centralized Router adds 0.0.0.0/0 → TGW route
```

**AZ Lifecycle Management (Egress VPC):**

When removing an AZ from an egress VPC, use the `remove_az` flag to bypass NAT Gateway validation:

```hcl
centralized_egress = {
  central = true
  remove_az = true  # Escape hatch during AZ decommissioning
}
```

This prevents validation errors while NAT Gateways and associated infrastructure are being destroyed. After resource cleanup completes, remove the flag. This is critical for operational flexibility when scaling down infrastructure.

### AZ-Aware Routing

**Optimal Path (Relative AZ):**
```
app1-use2 AZ-a private subnet
  → TGW (same AZ)
  → general1-use2 AZ-a NAT GW
  → Internet

Cost: TGW processing only ($0.02/GB)
```

**Failover Path (Non-Relative AZ):**
```
app1-use2 AZ-b private subnet (no egress VPC NAT in AZ-b)
  → TGW
  → Load balanced across general1-use2 AZ-a and AZ-c NAT GWs
  → Internet

Cost: TGW processing + cross-AZ transfer ($0.02 + $0.01/GB)
```

### Cost Analysis

**Imperative Terraform Approach (per-VPC NAT):**
```
9 VPCs × 2 AZs × NAT Gateway = 18 NAT GWs
Cost: 18 × $32.85/month = $591.30/month (us-east-1 rates)
Annual: $7,095.60
Configuration: 18 aws_nat_gateway + 18 aws_eip resource blocks
```

**Automated Terraform Approach (centralized egress):**
```
3 Egress VPCs × 2 AZs × NAT Gateway = 6 NAT GWs
Cost: 6 × $32.85/month = $197.10/month (us-east-1 rates)
Annual: $2,365.20

Savings: $4,730.40/year (67% reduction, measured in Section 7)
```

**Note:** Pricing based on us-east-1 rates as of November 2025. Regional variations exist ($32.40-$32.85/month).

## Dual Stack Strategy

### IPv4: Centralized
- All private subnets route `0.0.0.0/0` through TGW to egress VPC NAT Gateways
- Consolidates NAT Gateway costs
- Requires NAT (private IPv4 exhaustion)

### IPv6: Decentralized
- Each VPC with `eigw = true` routes `::/0` to its own Egress-only Internet Gateway
- EIGW cost: $0/hour (free)
- No NAT needed (IPv6 globally routable)
- Reduces cross-region TGW charges for IPv6 traffic

### Configuration Example

```hcl
azs = {
  a = {
    eigw = true  # IPv6 egress via local EIGW
    private_subnets = [
      {
        name      = "cluster1"
        cidr      = "10.0.64.0/24"      # IPv4
        ipv6_cidr = "2600:../64"        # IPv6
      }
    ]
  }
}
```

**Result:**
- IPv4 traffic → TGW → Egress VPC NAT GW
- IPv6 traffic → Local EIGW (direct, no TGW hop for internet)

## Isolated Subnets for Air-Gapped Workloads

### Concept

**Isolated subnets** provide complete network isolation from the internet while maintaining full mesh connectivity through Transit Gateway. Unlike private subnets (which route `0.0.0.0/0` to NAT Gateway), isolated subnets receive **only** VPC-local and Transit Gateway routes.

### Use Cases

**Kubernetes Clusters:**
```hcl
azs = {
  a = {
    isolated_subnets = [
      {
        name      = "k8s-workers-a"
        cidr      = "10.60.128.0/20"
        ipv6_cidr = "2600:1f28:1d3:1680::/64"
        tags = {
          "kubernetes.io/role/internal-elb" = "1"
          "karpenter.sh/discovery"          = "my-cluster"
        }
      }
    ]
  }
}
```

**Database Tier (No Internet Access):**
```hcl
azs = {
  a = {
    isolated_subnets = [
      {
        name      = "postgres-primary"
        cidr      = "10.60.144.0/24"
        ipv6_cidr = "2600:1f28:1d3:1690::/64"
      },
      {
        name      = "postgres-replica"
        cidr      = "10.60.145.0/24"
        ipv6_cidr = "2600:1f28:1d3:1691::/64"
      }
    ]
  }
}
```

### Routing Behavior

**Isolated subnet route table contains:**
- ✅ VPC local routes (automatic)
- ✅ Transit Gateway routes to other VPCs (via Centralized Router)
- ✅ Cross-region routes (via TGW peering)
- ❌ **No** `0.0.0.0/0` → NAT Gateway
- ❌ **No** `::/0` → EIGW
- ❌ **No** internet connectivity

**Example route table:**
```
Destination         Target
10.60.0.0/18        local
10.61.0.0/18        tgw-12345      # Other VPC in region
10.62.0.0/18        tgw-12345      # Another VPC in region
172.16.0.0/18       tgw-12345      # Cross-region VPC
2600:1f28:../56     local          # IPv6 local
2600:1f28:../56     tgw-12345      # IPv6 mesh routes
# Note: No default routes (0.0.0.0/0 or ::/0)
```

### Comparison: Private vs. Isolated

| Feature | Private Subnets | Isolated Subnets |
|---------|----------------|------------------|
| **Internet egress (IPv4)** | ✅ Via NAT GW or centralized egress | ❌ None |
| **Internet egress (IPv6)** | ✅ Via EIGW (if enabled) | ❌ None |
| **Mesh connectivity** | ✅ Via TGW | ✅ Via TGW |
| **Cross-region routing** | ✅ Via TGW peering | ✅ Via TGW peering |
| **Use case** | Apps needing internet access | Databases, internal services, K8s nodes |
| **Route table scope** | Per-AZ | Per-AZ |

### Benefits

1. **Enhanced security**: Complete isolation from internet attack surface
2. **Compliance**: Meets air-gap requirements for regulated workloads
3. **Cost optimization**: No NAT Gateway costs for subnets that don't need internet
4. **Kubernetes integration**: Tag subnets for controller discovery
5. **Dual-stack support**: IPv4 and IPv6 mesh routing without internet exposure

### Migration Pattern

**Phase 1: Start with private subnets**
```hcl
private_subnets = [
  { name = "db-tier", cidr = "10.60.10.0/24" }
]
```

**Phase 2: Identify subnets with no internet traffic**
```bash
# Analyze VPC Flow Logs
aws ec2 describe-flow-logs --filter "Name=resource-id,Values=subnet-xyz"
# If destination is only internal IPs → candidate for isolated
```

**Phase 3: Convert to isolated (gradual rollout)**
```hcl
isolated_subnets = [
  { name = "db-tier", cidr = "10.60.10.0/24" }
]
# Remove NAT Gateway route, keeping only mesh routes
```

## Hybrid Connectivity: TGW + VPC Peering

### Strategy Matrix

| Traffic Pattern | Method | Cost/GB | Use Case |
|----------------|--------|---------|----------|
| **Dynamic mesh** | TGW | $0.02 | Any-to-any, unknown paths |
| **Cross-region high-volume** | VPC Peering | $0.01 | 50% savings vs TGW |
| **Intra-region same-AZ** | VPC Peering | $0.00 | Free! |

### Example Implementation

**Cross-Region (Selective Subnets):**
```hcl
only_route = {
  subnet_cidrs      = ["192.168.65.0/24"]  # Only specific subnet
  ipv6_subnet_cidrs = ["2600:1f28:../64"]
}
```

**Intra-Region (All Subnets, Free Data Transfer):**
```hcl
# No only_route specified = route all subnets
# Same region + same AZ = $0 data transfer
```

### Cost Example (10TB/month)

**via TGW:**
```
10TB × $0.02/GB = $200/month
+ $36/month attachment fee
= $236/month
```

**via VPC Peering (same AZ):**
```
10TB × $0/GB = $0/month
Savings: $236/month ($2,832/year per high-volume pair)
```

### Routing Priority

```
Most specific routes win (automatic):
1. VPC Peering: /24 or /28 routes (direct path)
2. TGW: /18 or /16 routes (mesh path)
3. IGW: 0.0.0.0/0 (default route)

Traffic automatically selects optimal path!
```

## Multi-Region Coordination

### The Challenge of Cross-Region Mesh

Connecting multiple regions in a full mesh with imperative Terraform requires coordinating:

**Imperative Terraform Process (3 regions):**
1. Create TGW peering request in Region 1 → Region 2
2. Accept peering in Region 2 (different AWS API endpoint)
3. Add routes in Region 1 TGW route table for Region 2 VPCs
4. Add routes in Region 2 TGW route table for Region 1 VPCs
5. Add routes in all Region 1 VPC route tables for Region 2 CIDRs
6. Add routes in all Region 2 VPC route tables for Region 1 CIDRs
7. Repeat steps 1-6 for Region 2 ↔ Region 3
8. Repeat steps 1-6 for Region 3 ↔ Region 1
9. Test connectivity in all 6 directions
10. Troubleshoot asymmetric routing issues

**Time:** ~4-6 hours per region pair × 3 pairs = **12-18 hours**

### Full Mesh Trio Automation

The Full Mesh Trio module reduces this to a single module call:

```hcl
module "full_mesh_trio" {
  source = "JudeQuintana/full-mesh-trio/aws"

  providers = {
    aws.one   = aws.use1
    aws.two   = aws.use2
    aws.three = aws.usw2
  }

  full_mesh_trio = {
    one   = { centralized_router = module.centralized_router_use1 }
    two   = { centralized_router = module.centralized_router_use2 }
    three = { centralized_router = module.centralized_router_usw2 }
  }
}
```

**Time:** ~30 minutes (automatic)
**Speedup:** 24-36× faster

### Configuration Safety

Full Mesh Trio includes **built-in validation** to prevent common misconfigurations:

- ✅ **Uniqueness enforcement**: TGW and VPC names must be unique across all regions
- ✅ **Regional consistency**: Each region must have at least one configured VPC
- ✅ **IPv6 consistency**: Either all regions use IPv6 or none (no mixed dual-stack)
- ✅ **CIDR responsibility**: Users must ensure non-overlapping CIDR allocations

**Error detection happens at plan time**, preventing invalid configurations from being applied.

### Multi-Provider Pattern

The module uses **provider aliasing** to coordinate cross-region operations:

```hcl
# In your root module
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "use2"
  region = "us-east-2"
}

provider "aws" {
  alias  = "usw2"
  region = "us-west-2"
}

# Full Mesh Trio receives all three
module "full_mesh_trio" {
  providers = {
    aws.one   = aws.use1
    aws.two   = aws.use2
    aws.three = aws.usw2
  }
  # ...
}
```

**Benefits:**
- Single Terraform state manages all regions
- Atomic operations (all-or-nothing deployment)
- No manual cross-region coordination
- Consistent validation across all regions

### Route Propagation Mathematics

**For N VPCs per region (total 3N VPCs):**

```
Cross-region TGW routes:
  Each TGW needs routes to 2N remote VPCs
  3 TGWs × 2N remote VPCs × C CIDRs per VPC = 6NC TGW routes

Cross-region VPC routes:
  Each VPC needs routes to 2N remote VPCs
  3N VPCs × 2N remote VPCs × R route tables per VPC × C CIDRs = 6N²RC VPC routes

Total cross-region routes: 6NC + 6N²RC ≈ O(N²) (dominated by VPC routes)

Example (N=3, R=4, C=4):
  TGW routes: 6 × 3 × 4 = 72 routes
  VPC routes: 6 × 9 × 4 × 4 = 864 routes
  Total: 936 cross-region routes (generated from 3 module references)
```

### Transitive Routing Behavior

**Direct vs. Indirect Paths:**

```
VPC in us-east-1 reaching VPC in us-west-2:

Option 1 (Direct): use1 → usw2 peering → destination
  Latency: ~65-75ms
  Cost: $0.02/GB (single TGW hop)

Option 2 (Indirect): use1 → use2 → usw2 → destination
  Latency: ~80-90ms (two TGW hops)
  Cost: $0.04/GB (two TGW hops)

AWS BGP automatically selects shortest path (Option 1)
```

**Why provide both paths?**
- **Redundancy**: If direct peering fails, traffic reroutes via intermediate region
- **Multi-homing**: Applications can prefer specific paths via route metrics
- **Gradual rollout**: Can test connectivity through intermediate region first

## Security Architecture

### Hierarchical Security Group Rules

**Layer 1: Regional (Intra-VPC)**
```
Per protocol, per region:
- Create N×(N-1) rules with self-exclusion
- VPC A receives rules from VPC B and C (not from A)
- Handles primary + secondary CIDRs automatically
```

**Layer 2: Cross-Region (Full Mesh)**
```
Between region pairs:
- Create bidirectional rules
- 6 combinations (one↔two, one↔three, two↔three)
- Maintains protocol consistency validation
```

### Security Group Rule Mathematics

**Regional Rules (per region) - Theoretical Maximum:**
```
N = 3 VPCs
P = 2 protocols (SSH, ICMP)
I = 2 IP versions (IPv4, IPv6)
C̄ = 1.5 average CIDRs per VPC

Rules = N × (N-1) × P × I × C̄
      = 3 × 2 × 2 × 2 × 1.5
      = 36 rules per region

Total regional capacity: 36 × 3 regions = 108 rules
```

**Cross-Region Rules - Theoretical Maximum:**
```
Region pairs: 3
VPCs per region: 3
Rules per pair (bidirectional): 3 × 3 × 4 protocols × 1.5 CIDRs × 2 directions
                                = 108 rules per pair

Total cross-region capacity: 108 × 3 = 324 rules

Grand Total Capacity: 108 + 324 = 432 security group rules
Actual Deployment: 108 rules (25% utilization, selective protocol deployment)
Generated from: 12 lines of rule definitions
```

### Protocol Definitions

**IPv4:**
```hcl
security_group_rules = [
  { label = "ssh",  protocol = "tcp",  from_port = 22, to_port = 22 },
  { label = "ping", protocol = "icmp", from_port = 8,  to_port = 0  }
]
```

**IPv6:**
```hcl
ipv6_security_group_rules = [
  { label = "ssh6",  protocol = "tcp",     from_port = 22, to_port = 22 },
  { label = "ping6", protocol = "icmpv6", from_port = -1, to_port = -1 }  # All ICMPv6
]
```

**Note:** IPv6 ICMP uses `-1` (all types) because ICMPv6 is essential for IPv6 operation (neighbor discovery, path MTU, etc.).

### Inbound-Only Design

Security groups are **stateful**:
- Only ingress rules created (108 measured, 432 capacity)
- Return traffic automatically allowed
- If using stateless NACLs: would need 216 rules (ingress + egress for measured deployment)
- **50% rule reduction** by leveraging AWS statefulness

## Operational Procedures

### Adding a VPC

**Steps:**
1. Add VPC definition to `tiered_vpcs` list (~15 lines)
2. `terraform apply`
   - Modules automatically generate routes to/from new VPC
   - Security group rules automatically propagate
   - TGW attachment created
   - Cross-region routes added via Full Mesh Trio

**Time:** 15-30 minutes
**Risk:** Minimal (only adding, not modifying existing)

### Adding a Protocol

**Steps:**
1. Add protocol definition to `security_group_rules` (2 lines for IPv4 + IPv6)
2. `terraform apply`
   - Modules generate new security group rules automatically
   - Example: Adding SSH+ICMP generated 108 rules in this deployment
   - Capacity: Up to 432 rules for full protocol matrix

**Time:** 5-10 minutes
**Risk:** Zero (atomic security group rule creation)

### Controlled Demolition: Removing a VPC

**Safe Process:**
1. Remove `special = true` from all VPC subnets
2. Apply VPCs → removes TGW attachment capability
3. Apply Centralized Router → removes VPC from regional mesh
4. Apply Full Mesh Trio → removes VPC from cross-region mesh
5. Remove VPC definition from code
6. Apply VPCs → deletes VPC cleanly

**Why:** AWS won't delete subnets with active TGW attachments. This ensures clean state transitions.

### Removing an AZ

**Egress VPC AZ Removal:**
```hcl
centralized_egress = {
  central   = true
  remove_az = true  # Bypass validation temporarily
}
```

**Process:**
1. Set `remove_az = true` in egress VPC config
2. Remove `special = true` from AZ subnet
3. Apply → isolates AZ from mesh
4. Remove AZ definition
5. Apply → deletes AZ

**Effect:** Traffic from other VPCs automatically load balances to remaining egress VPC AZs.

## Validation & Testing

### AWS Route Analyzer

Use [AWS Network Manager Route Analyzer](https://console.aws.amazon.com/networkmanager) (free) to validate:

**Test Paths:**
1. Cross-region (use1 → use2)
2. Different VPC types (app → egress)
3. IPv4 and IPv6 separately
4. Same AZ vs. cross AZ

**Expected Results:**
- Forward path: Connected
- Return path: Connected
- Latency: Appropriate for distance

### Terraform Validation

```bash
# Validate configuration
terraform validate

# Check what will change
terraform plan

# Apply with target for staged rollout
terraform apply -target module.vpcs_use1

# Inspect state
terraform state list
terraform state show module.vpcs_use1["app1"]
```

## Performance Characteristics

### Bandwidth Limits

**Per VPC Attachment:** Up to 50 Gbps
**Per TGW Peering:** Up to 50 Gbps

**Your Architecture:**
- 9 VPC attachments × 50 Gbps = 450 Gbps intra-region aggregate
- 3 TGW peerings × 50 Gbps = 150 Gbps cross-region aggregate
- **Total theoretical:** 600 Gbps

**Practical sustained:** ~60% = 360 Gbps (exceeds most enterprise needs by 10-100×)

### Latency

**Intra-Region via TGW:**
- Same AZ: ~1ms additional latency
- Cross AZ: ~2-3ms additional latency

**Cross-Region via TGW Peering:**
- use1 ↔ use2 (Virginia ↔ Ohio): ~10-15ms
- use1 ↔ usw2 (Virginia ↔ Oregon): ~65-75ms
- use2 ↔ usw2 (Ohio ↔ Oregon): ~55-65ms

**VPC Peering (Direct):**
- Same AZ: <1ms (nearly direct)
- Cross region: Same as TGW but no processing overhead

### High Availability

**Component SLAs:**
- VPC: 99.99%
- TGW: 99.95%
- NAT Gateway: 99.95%
- VPC Peering: 99.99%

**Multi-AZ Availability:**
```
With 2 AZs:
P(both fail) = (1 - 0.9999)² = 0.00000001
Availability = 99.9999% (6 nines)
```

**End-to-End Path (use1 → use2):**
```
Components in series:
- Source VPC: 99.99%
- TGW use1: 99.95%
- TGW peering: 99.95%
- TGW use2: 99.95%
- Dest VPC: 99.99%

Path availability: 99.84%
Expected downtime: ~14 hours/year
```

## Cost Summary

### Monthly Costs (Baseline)

**TGW Infrastructure:**
```
TGWs: 3 × $36 = $108
VPC Attachments: 9 × $36 = $324
TGW Peerings: 3 × $36 = $108
Subtotal: $540/month
```

**NAT Gateways (Centralized):**
```
NAT GWs: 6 × $32.85 = $197.10/month (us-east-1 rates)
```

**VPC Peering:**
```
2 peering connections: $0 (no hourly charge)
```

**Total Fixed Costs:** $734.40/month ($8,813/year)

### Variable Costs (Data Processing)

**TGW Data Processing:** $0.02/GB
**NAT Gateway Data Processing:** $0.045/GB
**VPC Peering (cross-region):** $0.01/GB
**VPC Peering (intra-region, same AZ):** $0/GB

**Example (5TB inter-VPC + 2TB internet egress/month):**
```
TGW: 5,000 GB × $0.02 = $100
NAT GW: 2,000 GB × $0.045 = $90
Total variable: $190/month

Monthly total: $734 + $190 = $924/month
Annual: ~$11,088
```

### Cost Comparison

**Imperative Terraform (per-VPC NAT):**
```
18 NAT GWs × $32.85 = $591.30/month (us-east-1 pricing)
Additional annual cost: $4,730.40 (67% higher than centralized)
Configuration: 18 explicit aws_nat_gateway resource blocks
```

**Imperative Terraform (Development Time):**
```
Initial development: 31.2 hours @ $125/hr = $3,900 (estimated)
  - Writing explicit resource blocks for 852 routes + 108 SG rules
  - Debugging, testing, validation
Annual maintenance: ~80 hours @ $125/hr = $10,000
Total: $13,900 first year, $10,000 annually thereafter
```

**Automated Terraform (This Architecture):**
```
Initial deployment: 0.26 hours @ $125/hr = $33 (measured)
  - 15.75 minutes total (development + deployment)
Annual maintenance: ~10 hours @ $125/hr = $1,250
Total: $1,283 first year, $1,250 annually thereafter
```

**Total Annual Savings:** ~$13,447
- Infrastructure: $4,730 (67% NAT Gateway reduction)
- Engineering time: $8,717 (120× faster development + lower maintenance)

**Note:** All measurements from WHITEPAPER.md Section 7 (Evaluation). Deployment time measured with Terraform v1.11.4, M1 MacBook Pro, AWS Provider v5.95.0, local state.

## IPAM Configuration

### Structure

**IPv4 (Private Scope):**
- Manual allocation per region
- Pools configured per region locale
- `/18` per VPC (supports 4 AZs with `/20` subnets)

**IPv6 (Public Scope):**
- `/52` regional pool → `/56` per VPC → `/64` per subnet
- Amazon-owned IPv6 allocated to your account
- Auto-assigned or specified

### Capacity Planning

**IPv6 Growth Capacity:**
```
/52 = 4,096 /64 subnets available
/56 per VPC = 256 /64 subnets per VPC
Can support 16 VPCs per region with full /56 allocations
```

**IPv4 Address Space:**
```
/18 per VPC = 16,379 usable IPs
9 VPCs × 16,379 = 147,411 IPs
+ Secondary CIDRs = additional ~20,455 IPs
Total: ~167,866 private IPv4 addresses
```

## Source Modules

All modules are open source and published on Terraform Registry:

- **Tiered VPC-NG:** `JudeQuintana/tiered-vpc-ng/aws`
- **Centralized Router:** `JudeQuintana/centralized-router/aws`
- **Full Mesh Trio:** `JudeQuintana/full-mesh-trio/aws`
- **VPC Peering Deluxe:** `JudeQuintana/vpc-peering-deluxe/aws`
- **Intra-VPC Security Group Rule:** `JudeQuintana/intra-vpc-security-group-rule/aws`
- **Full Mesh Intra-VPC Security Group Rules:** `JudeQuintana/full-mesh-intra-vpc-security-group-rules/aws`
- **IPv6 Intra-VPC Security Group Rule:** `JudeQuintana/ipv6-intra-vpc-security-group-rule/aws`
- **IPv6 Full Mesh Intra-VPC Security Group Rules:** `JudeQuintana/ipv6-full-mesh-intra-vpc-security-group-rules/aws`

GitHub: https://github.com/JudeQuintana/terraform-main

## Key Takeaways

1. **Compositional modules** enable self-organizing topologies through pure function transformations
2. **Functional route generation** eliminates O(n²) imperative resource block authoring
3. **Centralized egress** reduces NAT Gateway costs by 67% ($4,730/year measured in us-east-1)
4. **Dual-stack strategy** optimizes IPv4 (centralized) and IPv6 (decentralized) independently
5. **Hierarchical security** with self-exclusion prevents circular references
6. **Hybrid connectivity** (TGW + VPC Peering) optimizes for cost and performance
7. **Mathematical elegance** transforms imperative O(n²) to automated O(n) configuration
   - 174 lines generate 1,308 resources (7.5× amplification measured)
   - Theoretical capacity: 1,800 resources (10.3× amplification)
8. **120× faster deployment** (31.2 hours → 15.75 minutes) includes development + deployment
   - Eliminates manual resource block authoring (852 routes, 108 SG rules)
   - Terraform v1.11.4 deployment optimization on M1 ARM architecture

This architecture represents a **domain-specific language for AWS mesh networking** that replaces imperative resource block authoring with declarative topology specification.

**See WHITEPAPER.md for complete mathematical analysis, formal proofs, and detailed evaluation metrics.**
