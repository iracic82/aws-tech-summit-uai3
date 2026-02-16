#!/usr/bin/env bash
# ============================================================
# AWS Resource Inventory — UAI3 Tech Summit Lab
# Scans all deployment regions and produces a formatted report
# with IP addresses, resource counts, and a grand summary.
#
# Usage:
#   ./inventory.sh                          # full 10-region scan
#   ./inventory.sh --region eu-central-1    # single-region scan
#   ./inventory.sh --no-color               # disable ANSI colors
#   ./inventory.sh --no-color > report.txt  # pipe to file
# ============================================================
set -euo pipefail

# --- Deployment regions (matches Terraform providers) ---------------------

ALL_REGIONS=(
  us-east-1
  us-west-2
  eu-central-1
  eu-west-1
  ap-southeast-1
  ap-northeast-1
  sa-east-1
  ca-central-1
  ap-south-1
  eu-north-1
)

# --- Color helpers --------------------------------------------------------

USE_COLOR=true

setup_colors() {
  if [[ "$USE_COLOR" == true ]] && [[ -t 1 ]]; then
    CYAN='\033[0;36m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    WHITE='\033[1;37m'
    RED='\033[0;31m'
    DIM='\033[2m'
    BOLD='\033[1m'
    NC='\033[0m'
  else
    CYAN='' GREEN='' YELLOW='' WHITE='' RED='' DIM='' BOLD='' NC=''
  fi
}

# --- Argument parsing -----------------------------------------------------

SCAN_REGIONS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-color)
      USE_COLOR=false
      shift
      ;;
    --region)
      [[ -z "${2:-}" ]] && { echo "Error: --region requires a value"; exit 1; }
      SCAN_REGIONS+=("$2")
      shift 2
      ;;
    -h|--help)
      echo "Usage: $(basename "$0") [--no-color] [--region <name>]"
      echo ""
      echo "  --no-color          Disable ANSI color output"
      echo "  --region <name>     Scan only the specified region (repeatable)"
      echo "  -h, --help          Show this help"
      echo ""
      echo "Default: scans all 10 deployment regions."
      exit 0
      ;;
    *)
      echo "Unknown option: $1"; exit 1
      ;;
  esac
done

# Default to all regions if none specified
if [[ ${#SCAN_REGIONS[@]} -eq 0 ]]; then
  SCAN_REGIONS=("${ALL_REGIONS[@]}")
fi

setup_colors

# --- Utility functions ----------------------------------------------------

header() {
  printf "\n${CYAN}${BOLD}══════════════════════════════════════════════════════════════${NC}\n"
  printf "${CYAN}${BOLD}  %s${NC}\n" "$1"
  printf "${CYAN}${BOLD}══════════════════════════════════════════════════════════════${NC}\n"
}

section() {
  printf "\n  ${GREEN}── %s ──${NC}\n" "$1"
}

warn() {
  printf "  ${YELLOW}%s${NC}\n" "$1"
}

# Helper: run AWS CLI with region, return JSON
aws_q() {
  local region="$1"; shift
  aws --region "$region" --output json "$@" 2>/dev/null
}

# Safe jq: returns empty array on null/error
safe_jq() {
  jq -r "$@" 2>/dev/null || true
}

# --- Grand-total accumulators ---------------------------------------------

declare -A TOTAL_EC2 TOTAL_EIP TOTAL_ENI TOTAL_VPC TOTAL_SUBNET TOTAL_IGW
declare -A TOTAL_LB TOTAL_NAT TOTAL_VGW TOTAL_SG TOTAL_RT

GRAND_EC2=0 GRAND_EIP=0 GRAND_ENI=0 GRAND_VPC=0 GRAND_SUBNET=0 GRAND_IGW=0
GRAND_LB=0 GRAND_NAT=0 GRAND_VGW=0 GRAND_SG=0 GRAND_RT=0

# ============================================================
# Per-region scan
# ============================================================

scan_region() {
  local region="$1"
  local rc2=0 reip=0 reni=0 rvpc=0 rsub=0 rigw=0 rlb=0 rnat=0 rvgw=0 rsg=0 rrt=0

  header "Region: ${region}"

  # --- EC2 Instances ------------------------------------------------------
  section "EC2 Instances"
  local ec2_json
  ec2_json=$(aws_q "$region" ec2 describe-instances \
    --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query 'Reservations[].Instances[]')

  if [[ -z "$ec2_json" ]] || [[ "$ec2_json" == "[]" ]] || [[ "$ec2_json" == "null" ]]; then
    warn "  (none)"
  else
    rc2=$(echo "$ec2_json" | jq 'length')
    printf "  ${DIM}%-40s %-20s %-12s %-10s %-16s %-16s${NC}\n" \
      "Name" "Instance ID" "Type" "State" "Private IP" "Public IP"
    printf "  ${DIM}%-40s %-20s %-12s %-10s %-16s %-16s${NC}\n" \
      "$(printf '%0.s─' {1..40})" "$(printf '%0.s─' {1..20})" "$(printf '%0.s─' {1..12})" \
      "$(printf '%0.s─' {1..10})" "$(printf '%0.s─' {1..16})" "$(printf '%0.s─' {1..16})"
    echo "$ec2_json" | jq -r '
      .[] | [
        ((.Tags // []) | map(select(.Key == "Name")) | .[0].Value // "-"),
        .InstanceId,
        .InstanceType,
        .State.Name,
        (.PrivateIpAddress // "-"),
        (.PublicIpAddress // "-")
      ] | @tsv' | while IFS=$'\t' read -r name iid itype state priv pub; do
        printf "  %-40s %-20s %-12s %-10s ${YELLOW}%-16s${NC} ${YELLOW}%-16s${NC}\n" \
          "$name" "$iid" "$itype" "$state" "$priv" "$pub"
      done
  fi

  # --- Elastic IPs --------------------------------------------------------
  section "Elastic IPs (EIP)"
  local eip_json
  eip_json=$(aws_q "$region" ec2 describe-addresses)

  local eip_list
  eip_list=$(echo "$eip_json" | safe_jq '.Addresses')

  if [[ -z "$eip_list" ]] || [[ "$eip_list" == "[]" ]] || [[ "$eip_list" == "null" ]]; then
    warn "  (none)"
  else
    reip=$(echo "$eip_list" | jq 'length')
    printf "  ${DIM}%-24s %-16s %-22s %-22s${NC}\n" \
      "Allocation ID" "Public IP" "Instance" "ENI"
    printf "  ${DIM}%-24s %-16s %-22s %-22s${NC}\n" \
      "$(printf '%0.s─' {1..24})" "$(printf '%0.s─' {1..16})" \
      "$(printf '%0.s─' {1..22})" "$(printf '%0.s─' {1..22})"
    echo "$eip_list" | jq -r '
      .[] | [
        .AllocationId,
        (.PublicIp // "-"),
        (.InstanceId // "-"),
        (.NetworkInterfaceId // "-")
      ] | @tsv' | while IFS=$'\t' read -r aid pip inst eni; do
        printf "  %-24s ${YELLOW}%-16s${NC} %-22s %-22s\n" "$aid" "$pip" "$inst" "$eni"
      done
  fi

  # --- Network Interfaces -------------------------------------------------
  section "Network Interfaces (ENI)"
  local eni_json
  eni_json=$(aws_q "$region" ec2 describe-network-interfaces \
    --query 'NetworkInterfaces')

  if [[ -z "$eni_json" ]] || [[ "$eni_json" == "[]" ]] || [[ "$eni_json" == "null" ]]; then
    warn "  (none)"
  else
    reni=$(echo "$eni_json" | jq 'length')
    printf "  ${DIM}%-24s %-16s %-16s %-10s %-30s${NC}\n" \
      "ENI ID" "Private IP" "Public IP" "Status" "Description"
    printf "  ${DIM}%-24s %-16s %-16s %-10s %-30s${NC}\n" \
      "$(printf '%0.s─' {1..24})" "$(printf '%0.s─' {1..16})" \
      "$(printf '%0.s─' {1..16})" "$(printf '%0.s─' {1..10})" "$(printf '%0.s─' {1..30})"
    echo "$eni_json" | jq -r '
      .[] | [
        .NetworkInterfaceId,
        (.PrivateIpAddress // "-"),
        (.Association.PublicIp // "-"),
        .Status,
        (.Description // "-")[0:30]
      ] | @tsv' | while IFS=$'\t' read -r eid priv pub stat desc; do
        printf "  %-24s ${YELLOW}%-16s${NC} ${YELLOW}%-16s${NC} %-10s %-30s\n" \
          "$eid" "$priv" "$pub" "$stat" "$desc"
      done
  fi

  # --- VPCs ---------------------------------------------------------------
  section "VPCs"
  local vpc_json
  vpc_json=$(aws_q "$region" ec2 describe-vpcs --query 'Vpcs')

  if [[ -z "$vpc_json" ]] || [[ "$vpc_json" == "[]" ]] || [[ "$vpc_json" == "null" ]]; then
    warn "  (none)"
  else
    rvpc=$(echo "$vpc_json" | jq 'length')
    printf "  ${DIM}%-24s %-20s %-30s${NC}\n" "VPC ID" "CIDR" "Name"
    printf "  ${DIM}%-24s %-20s %-30s${NC}\n" \
      "$(printf '%0.s─' {1..24})" "$(printf '%0.s─' {1..20})" "$(printf '%0.s─' {1..30})"
    echo "$vpc_json" | jq -r '
      .[] | [
        .VpcId,
        .CidrBlock,
        ((.Tags // []) | map(select(.Key == "Name")) | .[0].Value // "-")
      ] | @tsv' | while IFS=$'\t' read -r vid cidr name; do
        printf "  %-24s %-20s %-30s\n" "$vid" "$cidr" "$name"
      done
  fi

  # --- Subnets ------------------------------------------------------------
  section "Subnets"
  local sub_json
  sub_json=$(aws_q "$region" ec2 describe-subnets --query 'Subnets')

  if [[ -z "$sub_json" ]] || [[ "$sub_json" == "[]" ]] || [[ "$sub_json" == "null" ]]; then
    warn "  (none)"
  else
    rsub=$(echo "$sub_json" | jq 'length')
    printf "  ${DIM}%-26s %-20s %-16s %-30s${NC}\n" "Subnet ID" "CIDR" "AZ" "Name"
    printf "  ${DIM}%-26s %-20s %-16s %-30s${NC}\n" \
      "$(printf '%0.s─' {1..26})" "$(printf '%0.s─' {1..20})" \
      "$(printf '%0.s─' {1..16})" "$(printf '%0.s─' {1..30})"
    echo "$sub_json" | jq -r '
      .[] | [
        .SubnetId,
        .CidrBlock,
        .AvailabilityZone,
        ((.Tags // []) | map(select(.Key == "Name")) | .[0].Value // "-")
      ] | @tsv' | while IFS=$'\t' read -r sid cidr az name; do
        printf "  %-26s %-20s %-16s %-30s\n" "$sid" "$cidr" "$az" "$name"
      done
  fi

  # --- Internet Gateways --------------------------------------------------
  section "Internet Gateways"
  local igw_json
  igw_json=$(aws_q "$region" ec2 describe-internet-gateways \
    --query 'InternetGateways')

  if [[ -z "$igw_json" ]] || [[ "$igw_json" == "[]" ]] || [[ "$igw_json" == "null" ]]; then
    warn "  (none)"
  else
    rigw=$(echo "$igw_json" | jq 'length')
    printf "  ${DIM}%-24s %-24s %-30s${NC}\n" "IGW ID" "Attached VPC" "Name"
    printf "  ${DIM}%-24s %-24s %-30s${NC}\n" \
      "$(printf '%0.s─' {1..24})" "$(printf '%0.s─' {1..24})" "$(printf '%0.s─' {1..30})"
    echo "$igw_json" | jq -r '
      .[] | [
        .InternetGatewayId,
        ((.Attachments // []) | .[0].VpcId // "-"),
        ((.Tags // []) | map(select(.Key == "Name")) | .[0].Value // "-")
      ] | @tsv' | while IFS=$'\t' read -r gid vpc name; do
        printf "  %-24s %-24s %-30s\n" "$gid" "$vpc" "$name"
      done
  fi

  # --- Load Balancers (ALB/NLB) -------------------------------------------
  section "Load Balancers"
  local lb_json
  lb_json=$(aws_q "$region" elbv2 describe-load-balancers \
    --query 'LoadBalancers')

  if [[ -z "$lb_json" ]] || [[ "$lb_json" == "[]" ]] || [[ "$lb_json" == "null" ]]; then
    warn "  (none)"
  else
    rlb=$(echo "$lb_json" | jq 'length')
    printf "  ${DIM}%-36s %-14s %-50s${NC}\n" "Name" "Type" "DNS Name"
    printf "  ${DIM}%-36s %-14s %-50s${NC}\n" \
      "$(printf '%0.s─' {1..36})" "$(printf '%0.s─' {1..14})" "$(printf '%0.s─' {1..50})"
    echo "$lb_json" | jq -r '
      .[] | [
        .LoadBalancerName,
        .Type,
        .DNSName
      ] | @tsv' | while IFS=$'\t' read -r lname ltype dns; do
        printf "  %-36s %-14s ${YELLOW}%-50s${NC}\n" "$lname" "$ltype" "$dns"
      done
  fi

  # --- NAT Gateways -------------------------------------------------------
  section "NAT Gateways"
  local nat_json
  nat_json=$(aws_q "$region" ec2 describe-nat-gateways \
    --filter "Name=state,Values=pending,available" \
    --query 'NatGateways')

  if [[ -z "$nat_json" ]] || [[ "$nat_json" == "[]" ]] || [[ "$nat_json" == "null" ]]; then
    warn "  (none)"
  else
    rnat=$(echo "$nat_json" | jq 'length')
    printf "  ${DIM}%-24s %-16s %-12s %-30s${NC}\n" "NAT GW ID" "Public IP" "State" "Name"
    printf "  ${DIM}%-24s %-16s %-12s %-30s${NC}\n" \
      "$(printf '%0.s─' {1..24})" "$(printf '%0.s─' {1..16})" \
      "$(printf '%0.s─' {1..12})" "$(printf '%0.s─' {1..30})"
    echo "$nat_json" | jq -r '
      .[] | [
        .NatGatewayId,
        ((.NatGatewayAddresses // []) | .[0].PublicIp // "-"),
        .State,
        ((.Tags // []) | map(select(.Key == "Name")) | .[0].Value // "-")
      ] | @tsv' | while IFS=$'\t' read -r nid pip state name; do
        printf "  %-24s ${YELLOW}%-16s${NC} %-12s %-30s\n" "$nid" "$pip" "$state" "$name"
      done
  fi

  # --- VPN Gateways -------------------------------------------------------
  section "VPN Gateways"
  local vgw_json
  vgw_json=$(aws_q "$region" ec2 describe-vpn-gateways \
    --filters "Name=state,Values=pending,available" \
    --query 'VpnGateways')

  if [[ -z "$vgw_json" ]] || [[ "$vgw_json" == "[]" ]] || [[ "$vgw_json" == "null" ]]; then
    warn "  (none)"
  else
    rvgw=$(echo "$vgw_json" | jq 'length')
    printf "  ${DIM}%-24s %-24s %-30s${NC}\n" "VGW ID" "Attached VPC" "Name"
    printf "  ${DIM}%-24s %-24s %-30s${NC}\n" \
      "$(printf '%0.s─' {1..24})" "$(printf '%0.s─' {1..24})" "$(printf '%0.s─' {1..30})"
    echo "$vgw_json" | jq -r '
      .[] | [
        .VpnGatewayId,
        ((.VpcAttachments // []) | map(select(.State == "attached")) | .[0].VpcId // "-"),
        ((.Tags // []) | map(select(.Key == "Name")) | .[0].Value // "-")
      ] | @tsv' | while IFS=$'\t' read -r vid vpc name; do
        printf "  %-24s %-24s %-30s\n" "$vid" "$vpc" "$name"
      done
  fi

  # --- Security Groups (count only) ---------------------------------------
  section "Security Groups"
  local sg_json
  sg_json=$(aws_q "$region" ec2 describe-security-groups --query 'SecurityGroups')

  if [[ -z "$sg_json" ]] || [[ "$sg_json" == "[]" ]] || [[ "$sg_json" == "null" ]]; then
    rsg=0
  else
    rsg=$(echo "$sg_json" | jq 'length')
  fi
  printf "  Total: ${WHITE}%d${NC} security groups\n" "$rsg"

  # --- Route Tables (count only) ------------------------------------------
  section "Route Tables"
  local rt_json
  rt_json=$(aws_q "$region" ec2 describe-route-tables --query 'RouteTables')

  if [[ -z "$rt_json" ]] || [[ "$rt_json" == "[]" ]] || [[ "$rt_json" == "null" ]]; then
    rrt=0
  else
    rrt=$(echo "$rt_json" | jq 'length')
  fi
  printf "  Total: ${WHITE}%d${NC} route tables\n" "$rrt"

  # --- Region subtotal ----------------------------------------------------
  printf "\n  ${BOLD}Region subtotal: ${NC}"
  printf "EC2=%d  EIP=%d  ENI=%d  VPC=%d  Subnet=%d  IGW=%d  LB=%d  NAT=%d  VGW=%d  SG=%d  RT=%d\n" \
    "$rc2" "$reip" "$reni" "$rvpc" "$rsub" "$rigw" "$rlb" "$rnat" "$rvgw" "$rsg" "$rrt"

  # --- Store in grand totals ----------------------------------------------
  TOTAL_EC2[$region]=$rc2;   TOTAL_EIP[$region]=$reip;   TOTAL_ENI[$region]=$reni
  TOTAL_VPC[$region]=$rvpc;  TOTAL_SUBNET[$region]=$rsub; TOTAL_IGW[$region]=$rigw
  TOTAL_LB[$region]=$rlb;    TOTAL_NAT[$region]=$rnat;    TOTAL_VGW[$region]=$rvgw
  TOTAL_SG[$region]=$rsg;    TOTAL_RT[$region]=$rrt

  (( GRAND_EC2 += rc2 ))   || true
  (( GRAND_EIP += reip ))  || true
  (( GRAND_ENI += reni ))  || true
  (( GRAND_VPC += rvpc ))  || true
  (( GRAND_SUBNET += rsub )) || true
  (( GRAND_IGW += rigw ))  || true
  (( GRAND_LB  += rlb ))   || true
  (( GRAND_NAT += rnat ))  || true
  (( GRAND_VGW += rvgw ))  || true
  (( GRAND_SG  += rsg ))   || true
  (( GRAND_RT  += rrt ))   || true
}

# ============================================================
# Global resources (not region-scoped)
# ============================================================

scan_global() {
  header "Global Resources"

  # --- Route53 Hosted Zones -----------------------------------------------
  section "Route53 Hosted Zones"
  local r53_json
  r53_json=$(aws --output json route53 list-hosted-zones 2>/dev/null)

  local zones
  zones=$(echo "$r53_json" | safe_jq '.HostedZones')

  if [[ -z "$zones" ]] || [[ "$zones" == "[]" ]] || [[ "$zones" == "null" ]]; then
    warn "  (none)"
  else
    local zone_count
    zone_count=$(echo "$zones" | jq 'length')
    printf "  ${DIM}%-40s %-28s %-8s${NC}\n" "Zone Name" "Zone ID" "Records"
    printf "  ${DIM}%-40s %-28s %-8s${NC}\n" \
      "$(printf '%0.s─' {1..40})" "$(printf '%0.s─' {1..28})" "$(printf '%0.s─' {1..8})"
    echo "$zones" | jq -r '
      .[] | [
        .Name,
        (.Id | split("/") | last),
        (.ResourceRecordSetCount | tostring)
      ] | @tsv' | while IFS=$'\t' read -r zname zid rcount; do
        printf "  %-40s %-28s %-8s\n" "$zname" "$zid" "$rcount"
      done
    printf "  Total: ${WHITE}%d${NC} hosted zones\n" "$zone_count"
  fi

  # --- S3 Buckets ---------------------------------------------------------
  section "S3 Buckets"
  local s3_json
  s3_json=$(aws --output json s3api list-buckets 2>/dev/null)

  local buckets
  buckets=$(echo "$s3_json" | safe_jq '.Buckets')

  if [[ -z "$buckets" ]] || [[ "$buckets" == "[]" ]] || [[ "$buckets" == "null" ]]; then
    warn "  (none)"
  else
    local bucket_count
    bucket_count=$(echo "$buckets" | jq 'length')
    echo "$buckets" | jq -r '.[].Name' | while read -r bname; do
      printf "  - %s\n" "$bname"
    done
    printf "  Total: ${WHITE}%d${NC} buckets\n" "$bucket_count"
  fi
}

# ============================================================
# Grand summary
# ============================================================

print_summary() {
  header "Grand Summary"

  # Column header
  printf "\n  ${BOLD}%-18s %5s %5s %5s %5s %5s %5s %5s %5s %5s %5s %5s${NC}\n" \
    "Region" "EC2" "EIP" "ENI" "VPC" "Sub" "IGW" "LB" "NAT" "VGW" "SG" "RT"
  printf "  %-18s %5s %5s %5s %5s %5s %5s %5s %5s %5s %5s %5s\n" \
    "$(printf '%0.s─' {1..18})" "$(printf '%0.s─' {1..5})" "$(printf '%0.s─' {1..5})" \
    "$(printf '%0.s─' {1..5})" "$(printf '%0.s─' {1..5})" "$(printf '%0.s─' {1..5})" \
    "$(printf '%0.s─' {1..5})" "$(printf '%0.s─' {1..5})" "$(printf '%0.s─' {1..5})" \
    "$(printf '%0.s─' {1..5})" "$(printf '%0.s─' {1..5})" "$(printf '%0.s─' {1..5})"

  for region in "${SCAN_REGIONS[@]}"; do
    printf "  %-18s %5d %5d %5d %5d %5d %5d %5d %5d %5d %5d %5d\n" \
      "$region" \
      "${TOTAL_EC2[$region]:-0}" "${TOTAL_EIP[$region]:-0}" "${TOTAL_ENI[$region]:-0}" \
      "${TOTAL_VPC[$region]:-0}" "${TOTAL_SUBNET[$region]:-0}" "${TOTAL_IGW[$region]:-0}" \
      "${TOTAL_LB[$region]:-0}" "${TOTAL_NAT[$region]:-0}" "${TOTAL_VGW[$region]:-0}" \
      "${TOTAL_SG[$region]:-0}" "${TOTAL_RT[$region]:-0}"
  done

  # Totals row
  printf "  %-18s %5s %5s %5s %5s %5s %5s %5s %5s %5s %5s %5s\n" \
    "$(printf '%0.s─' {1..18})" "$(printf '%0.s─' {1..5})" "$(printf '%0.s─' {1..5})" \
    "$(printf '%0.s─' {1..5})" "$(printf '%0.s─' {1..5})" "$(printf '%0.s─' {1..5})" \
    "$(printf '%0.s─' {1..5})" "$(printf '%0.s─' {1..5})" "$(printf '%0.s─' {1..5})" \
    "$(printf '%0.s─' {1..5})" "$(printf '%0.s─' {1..5})" "$(printf '%0.s─' {1..5})"
  printf "  ${BOLD}%-18s %5d %5d %5d %5d %5d %5d %5d %5d %5d %5d %5d${NC}\n" \
    "TOTAL" \
    "$GRAND_EC2" "$GRAND_EIP" "$GRAND_ENI" "$GRAND_VPC" "$GRAND_SUBNET" \
    "$GRAND_IGW" "$GRAND_LB" "$GRAND_NAT" "$GRAND_VGW" "$GRAND_SG" "$GRAND_RT"

  # Grand resource count
  local grand_total=$(( GRAND_EC2 + GRAND_EIP + GRAND_ENI + GRAND_VPC + GRAND_SUBNET \
    + GRAND_IGW + GRAND_LB + GRAND_NAT + GRAND_VGW + GRAND_SG + GRAND_RT ))

  printf "\n  ${BOLD}Total AWS resources discovered: ${WHITE}%d${NC}\n" "$grand_total"

  # Token estimate: each IP-bearing resource ~= 1 management token
  local token_est=$(( GRAND_EC2 + GRAND_EIP + GRAND_ENI + GRAND_NAT + GRAND_LB ))
  printf "  ${DIM}Estimated managed IP tokens (EC2+EIP+ENI+NAT+LB): ${WHITE}%d${NC}\n" "$token_est"
}

# ============================================================
# Main
# ============================================================

printf "${BOLD}AWS Resource Inventory — UAI3 Tech Summit${NC}\n"
printf "${DIM}Scanning %d region(s)...${NC}\n" "${#SCAN_REGIONS[@]}"
printf "${DIM}Started: $(date '+%Y-%m-%d %H:%M:%S %Z')${NC}\n"

for region in "${SCAN_REGIONS[@]}"; do
  scan_region "$region"
done

scan_global
print_summary

printf "\n${DIM}Completed: $(date '+%Y-%m-%d %H:%M:%S %Z')${NC}\n"
