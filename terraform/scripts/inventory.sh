#!/usr/bin/env bash
# ============================================================
# AWS Resource Inventory — UAI3 Tech Summit Lab
# Scans deployment regions and produces asset counts with
# IP association breakdown per region and a grand summary.
#
# Usage:
#   ./inventory.sh                          # full 8-region scan
#   ./inventory.sh --region eu-central-1    # single-region scan
#   ./inventory.sh --no-color               # disable ANSI colors
#   ./inventory.sh --no-color > report.txt  # pipe to file
# ============================================================
set -uo pipefail

# --- Deployment regions (matches Terraform providers) ---------------------

ALL_REGIONS=(
  us-east-1
  us-west-2
  eu-central-1
  eu-west-1
  ap-northeast-1
  sa-east-1
  ca-central-1
  ap-south-1
)

# --- Color helpers --------------------------------------------------------

USE_COLOR=true

setup_colors() {
  if [[ "$USE_COLOR" == true ]] && [[ -t 1 ]]; then
    CYAN='\033[0;36m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    WHITE='\033[1;37m'
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
      echo "Default: scans all 8 deployment regions."
      exit 0
      ;;
    *)
      echo "Unknown option: $1"; exit 1
      ;;
  esac
done

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

# Helper: run AWS CLI with region — returns empty string on error (SCP deny etc)
aws_q() {
  local region="$1"; shift
  aws --region "$region" --output json "$@" 2>/dev/null || true
}

# --- Grand-total accumulators ---------------------------------------------

declare -A T_EC2 T_EC2_PUB T_EIP T_EIP_ASSOC T_ENI T_ENI_PUB
declare -A T_VPC T_SUBNET T_IGW T_NAT T_NAT_PUB T_VGW T_SG T_RT

G_EC2=0 G_EC2_PUB=0 G_EIP=0 G_EIP_ASSOC=0 G_ENI=0 G_ENI_PUB=0
G_VPC=0 G_SUBNET=0 G_IGW=0 G_NAT=0 G_NAT_PUB=0 G_VGW=0 G_SG=0 G_RT=0

# ============================================================
# Per-region scan
# ============================================================

scan_region() {
  local r="$1"
  local ec2=0 ec2_pub=0 eip=0 eip_assoc=0 eni=0 eni_pub=0
  local vpc=0 subnet=0 igw=0 nat=0 nat_pub=0 vgw=0 sg=0 rt=0

  header "Region: ${r}"

  # --- EC2 Instances ---
  local json
  json=$(aws_q "$r" ec2 describe-instances \
    --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query 'Reservations[].Instances[]')
  if [[ -n "$json" ]] && [[ "$json" != "[]" ]] && [[ "$json" != "null" ]]; then
    ec2=$(echo "$json" | jq 'length')
    ec2_pub=$(echo "$json" | jq '[.[] | select(.PublicIpAddress != null)] | length')
  fi

  # --- Elastic IPs ---
  json=$(aws_q "$r" ec2 describe-addresses --query 'Addresses')
  if [[ -n "$json" ]] && [[ "$json" != "[]" ]] && [[ "$json" != "null" ]]; then
    eip=$(echo "$json" | jq 'length')
    eip_assoc=$(echo "$json" | jq '[.[] | select(.InstanceId != null or .NetworkInterfaceId != null)] | length')
  fi

  # --- ENIs ---
  json=$(aws_q "$r" ec2 describe-network-interfaces --query 'NetworkInterfaces')
  if [[ -n "$json" ]] && [[ "$json" != "[]" ]] && [[ "$json" != "null" ]]; then
    eni=$(echo "$json" | jq 'length')
    eni_pub=$(echo "$json" | jq '[.[] | select(.Association.PublicIp != null)] | length')
  fi

  # --- VPCs ---
  json=$(aws_q "$r" ec2 describe-vpcs --query 'Vpcs')
  if [[ -n "$json" ]] && [[ "$json" != "[]" ]] && [[ "$json" != "null" ]]; then
    vpc=$(echo "$json" | jq 'length')
  fi

  # --- Subnets ---
  json=$(aws_q "$r" ec2 describe-subnets --query 'Subnets')
  if [[ -n "$json" ]] && [[ "$json" != "[]" ]] && [[ "$json" != "null" ]]; then
    subnet=$(echo "$json" | jq 'length')
  fi

  # --- IGWs ---
  json=$(aws_q "$r" ec2 describe-internet-gateways --query 'InternetGateways')
  if [[ -n "$json" ]] && [[ "$json" != "[]" ]] && [[ "$json" != "null" ]]; then
    igw=$(echo "$json" | jq 'length')
  fi

  # --- NAT Gateways ---
  json=$(aws_q "$r" ec2 describe-nat-gateways \
    --filter "Name=state,Values=pending,available" --query 'NatGateways')
  if [[ -n "$json" ]] && [[ "$json" != "[]" ]] && [[ "$json" != "null" ]]; then
    nat=$(echo "$json" | jq 'length')
    nat_pub=$(echo "$json" | jq '[.[] | select(.NatGatewayAddresses[0].PublicIp != null)] | length')
  fi

  # --- VPN Gateways ---
  json=$(aws_q "$r" ec2 describe-vpn-gateways \
    --filters "Name=state,Values=pending,available" --query 'VpnGateways')
  if [[ -n "$json" ]] && [[ "$json" != "[]" ]] && [[ "$json" != "null" ]]; then
    vgw=$(echo "$json" | jq 'length')
  fi

  # --- Security Groups ---
  json=$(aws_q "$r" ec2 describe-security-groups --query 'SecurityGroups')
  if [[ -n "$json" ]] && [[ "$json" != "[]" ]] && [[ "$json" != "null" ]]; then
    sg=$(echo "$json" | jq 'length')
  fi

  # --- Route Tables ---
  json=$(aws_q "$r" ec2 describe-route-tables --query 'RouteTables')
  if [[ -n "$json" ]] && [[ "$json" != "[]" ]] && [[ "$json" != "null" ]]; then
    rt=$(echo "$json" | jq 'length')
  fi

  # --- Print region asset table ---
  printf "\n  ${BOLD}%-28s %7s %14s${NC}\n" "Resource" "Count" "With Public IP"
  printf "  %-28s %7s %14s\n" \
    "$(printf '%0.s─' {1..28})" "$(printf '%0.s─' {1..7})" "$(printf '%0.s─' {1..14})"
  printf "  %-28s ${WHITE}%7d${NC} ${YELLOW}%14d${NC}\n" "EC2 Instances"       "$ec2"    "$ec2_pub"
  printf "  %-28s ${WHITE}%7d${NC} ${YELLOW}%14d${NC}  (associated)\n" "Elastic IPs"  "$eip"    "$eip_assoc"
  printf "  %-28s ${WHITE}%7d${NC} ${YELLOW}%14d${NC}\n" "Network Interfaces"  "$eni"    "$eni_pub"
  printf "  %-28s ${WHITE}%7d${NC}\n"                    "VPCs"                "$vpc"
  printf "  %-28s ${WHITE}%7d${NC}\n"                    "Subnets"             "$subnet"
  printf "  %-28s ${WHITE}%7d${NC}\n"                    "Internet Gateways"   "$igw"
  printf "  %-28s ${WHITE}%7d${NC} ${YELLOW}%14d${NC}\n" "NAT Gateways"        "$nat"    "$nat_pub"
  printf "  %-28s ${WHITE}%7d${NC}\n"                    "VPN Gateways"        "$vgw"
  printf "  %-28s ${WHITE}%7d${NC}\n"                    "Security Groups"     "$sg"
  printf "  %-28s ${WHITE}%7d${NC}\n"                    "Route Tables"        "$rt"
  printf "  %-28s %7s %14s\n" \
    "$(printf '%0.s─' {1..28})" "$(printf '%0.s─' {1..7})" "$(printf '%0.s─' {1..14})"

  local region_total=$(( ec2 + eip + eni + vpc + subnet + igw + nat + vgw + sg + rt ))
  local region_ips=$(( ec2_pub + eip_assoc + eni_pub + nat_pub ))
  printf "  ${BOLD}%-28s %7d %14d${NC}\n" "REGION TOTAL" "$region_total" "$region_ips"

  # --- Accumulate ---
  T_EC2[$r]=$ec2;       T_EC2_PUB[$r]=$ec2_pub
  T_EIP[$r]=$eip;       T_EIP_ASSOC[$r]=$eip_assoc
  T_ENI[$r]=$eni;       T_ENI_PUB[$r]=$eni_pub
  T_VPC[$r]=$vpc;       T_SUBNET[$r]=$subnet;   T_IGW[$r]=$igw
  T_NAT[$r]=$nat;       T_NAT_PUB[$r]=$nat_pub; T_VGW[$r]=$vgw
  T_SG[$r]=$sg;         T_RT[$r]=$rt

  (( G_EC2 += ec2 ))           || true;  (( G_EC2_PUB += ec2_pub ))     || true
  (( G_EIP += eip ))           || true;  (( G_EIP_ASSOC += eip_assoc )) || true
  (( G_ENI += eni ))           || true;  (( G_ENI_PUB += eni_pub ))     || true
  (( G_VPC += vpc ))           || true;  (( G_SUBNET += subnet ))       || true
  (( G_IGW += igw ))           || true;  (( G_NAT += nat ))             || true
  (( G_NAT_PUB += nat_pub ))   || true;  (( G_VGW += vgw ))            || true
  (( G_SG += sg ))             || true;  (( G_RT += rt ))               || true
}

# ============================================================
# Global resources
# ============================================================

scan_global() {
  header "Global Resources"

  # --- Route53 ---
  local r53_json zones zone_count=0
  r53_json=$(aws --output json route53 list-hosted-zones 2>/dev/null || true)
  zones=$(echo "$r53_json" | jq -r '.HostedZones // []' 2>/dev/null || echo "[]")
  if [[ "$zones" != "[]" ]] && [[ "$zones" != "null" ]] && [[ -n "$zones" ]]; then
    zone_count=$(echo "$zones" | jq 'length')
  fi
  printf "  Route53 Hosted Zones:  ${WHITE}%d${NC}\n" "$zone_count"

  # --- S3 ---
  local s3_json buckets bucket_count=0
  s3_json=$(aws --output json s3api list-buckets 2>/dev/null || true)
  buckets=$(echo "$s3_json" | jq -r '.Buckets // []' 2>/dev/null || echo "[]")
  if [[ "$buckets" != "[]" ]] && [[ "$buckets" != "null" ]] && [[ -n "$buckets" ]]; then
    bucket_count=$(echo "$buckets" | jq 'length')
  fi
  printf "  S3 Buckets:            ${WHITE}%d${NC}\n" "$bucket_count"
}

# ============================================================
# Grand summary
# ============================================================

print_summary() {
  header "Grand Summary — All Regions"

  # Per-region row: region | total assets | assets with IP
  printf "\n  ${BOLD}%-18s %8s %14s${NC}\n" "Region" "Assets" "With Public IP"
  printf "  %-18s %8s %14s\n" \
    "$(printf '%0.s─' {1..18})" "$(printf '%0.s─' {1..8})" "$(printf '%0.s─' {1..14})"

  for r in "${SCAN_REGIONS[@]}"; do
    local ra=$(( ${T_EC2[$r]:-0} + ${T_EIP[$r]:-0} + ${T_ENI[$r]:-0} + ${T_VPC[$r]:-0} \
      + ${T_SUBNET[$r]:-0} + ${T_IGW[$r]:-0} + ${T_NAT[$r]:-0} + ${T_VGW[$r]:-0} \
      + ${T_SG[$r]:-0} + ${T_RT[$r]:-0} ))
    local ri=$(( ${T_EC2_PUB[$r]:-0} + ${T_EIP_ASSOC[$r]:-0} + ${T_ENI_PUB[$r]:-0} + ${T_NAT_PUB[$r]:-0} ))
    printf "  %-18s ${WHITE}%8d${NC} ${YELLOW}%14d${NC}\n" "$r" "$ra" "$ri"
  done

  printf "  %-18s %8s %14s\n" \
    "$(printf '%0.s─' {1..18})" "$(printf '%0.s─' {1..8})" "$(printf '%0.s─' {1..14})"

  local grand_total=$(( G_EC2 + G_EIP + G_ENI + G_VPC + G_SUBNET + G_IGW + G_NAT + G_VGW + G_SG + G_RT ))
  local grand_ips=$(( G_EC2_PUB + G_EIP_ASSOC + G_ENI_PUB + G_NAT_PUB ))

  printf "  ${BOLD}%-18s %8d %14d${NC}\n\n" "TOTAL" "$grand_total" "$grand_ips"

  # Breakdown by resource type
  printf "  ${BOLD}%-28s %7s %14s${NC}\n" "Resource Type" "Count" "With Public IP"
  printf "  %-28s %7s %14s\n" \
    "$(printf '%0.s─' {1..28})" "$(printf '%0.s─' {1..7})" "$(printf '%0.s─' {1..14})"
  printf "  %-28s ${WHITE}%7d${NC} ${YELLOW}%14d${NC}\n" "EC2 Instances"       "$G_EC2"    "$G_EC2_PUB"
  printf "  %-28s ${WHITE}%7d${NC} ${YELLOW}%14d${NC}  (associated)\n" "Elastic IPs"  "$G_EIP"    "$G_EIP_ASSOC"
  printf "  %-28s ${WHITE}%7d${NC} ${YELLOW}%14d${NC}\n" "Network Interfaces"  "$G_ENI"    "$G_ENI_PUB"
  printf "  %-28s ${WHITE}%7d${NC}\n"                    "VPCs"                "$G_VPC"
  printf "  %-28s ${WHITE}%7d${NC}\n"                    "Subnets"             "$G_SUBNET"
  printf "  %-28s ${WHITE}%7d${NC}\n"                    "Internet Gateways"   "$G_IGW"
  printf "  %-28s ${WHITE}%7d${NC} ${YELLOW}%14d${NC}\n" "NAT Gateways"        "$G_NAT"    "$G_NAT_PUB"
  printf "  %-28s ${WHITE}%7d${NC}\n"                    "VPN Gateways"        "$G_VGW"
  printf "  %-28s ${WHITE}%7d${NC}\n"                    "Security Groups"     "$G_SG"
  printf "  %-28s ${WHITE}%7d${NC}\n"                    "Route Tables"        "$G_RT"
  printf "  %-28s %7s %14s\n" \
    "$(printf '%0.s─' {1..28})" "$(printf '%0.s─' {1..7})" "$(printf '%0.s─' {1..14})"
  printf "  ${BOLD}%-28s %7d %14d${NC}\n" "GRAND TOTAL" "$grand_total" "$grand_ips"

  printf "\n  ${DIM}Estimated management tokens (IP-bearing assets): ${WHITE}%d${NC}\n" "$grand_ips"
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
