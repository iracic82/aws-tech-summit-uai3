#!/usr/bin/env bash
# ============================================================
# AWS Resource Inventory — UAI3 Tech Summit Lab
# Scans deployment regions with parallel API calls and produces
# asset counts with Infoblox management token estimates.
#
# Token-bearing assets: EC2, EIP, ENI, IGW, NAT GW, VPN GW,
#   Transit GW, VPN Connections, ELB (Classic/ALB/NLB)
#
# Usage:
#   ./inventory.sh                          # full 8-region scan
#   ./inventory.sh --region eu-central-1    # single-region scan
#   ./inventory.sh --no-color > report.txt  # pipe to file
# ============================================================
set -uo pipefail

ALL_REGIONS=(
  us-east-1 us-west-2 eu-central-1 eu-west-1
  ap-northeast-1 sa-east-1 ca-central-1 ap-south-1
)

# --- Colors ---------------------------------------------------------------

USE_COLOR=true
setup_colors() {
  if [[ "$USE_COLOR" == true ]] && [[ -t 1 ]]; then
    CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
    WHITE='\033[1;37m'; DIM='\033[2m'; BOLD='\033[1m'; NC='\033[0m'
  else
    CYAN='' GREEN='' YELLOW='' WHITE='' DIM='' BOLD='' NC=''
  fi
}

# --- Args -----------------------------------------------------------------

SCAN_REGIONS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-color) USE_COLOR=false; shift ;;
    --region)   [[ -z "${2:-}" ]] && { echo "Error: --region requires a value"; exit 1; }
                SCAN_REGIONS+=("$2"); shift 2 ;;
    -h|--help)  echo "Usage: $(basename "$0") [--no-color] [--region <name>]"; exit 0 ;;
    *)          echo "Unknown option: $1"; exit 1 ;;
  esac
done
[[ ${#SCAN_REGIONS[@]} -eq 0 ]] && SCAN_REGIONS=("${ALL_REGIONS[@]}")
setup_colors

# --- Helpers --------------------------------------------------------------

header() {
  printf "\n${CYAN}${BOLD}══════════════════════════════════════════════════════════════${NC}\n"
  printf "${CYAN}${BOLD}  %s${NC}\n" "$1"
  printf "${CYAN}${BOLD}══════════════════════════════════════════════════════════════${NC}\n"
}
divider() {
  printf "  %-30s %7s %7s\n" "$(printf '%0.s─' {1..30})" "$(printf '%0.s─' {1..7})" "$(printf '%0.s─' {1..7})"
}

# --- Accumulators ---------------------------------------------------------

declare -A R_EC2 R_EIP R_ENI R_IGW R_NAT R_VGW R_TGW R_VPNC R_VPC R_SUBNET R_SG R_RT
G_EC2=0 G_EIP=0 G_ENI=0 G_IGW=0 G_NAT=0 G_VGW=0 G_TGW=0 G_VPNC=0
G_VPC=0 G_SUBNET=0 G_SG=0 G_RT=0

# --- Count helper: query AWS and return length ----------------------------

aws_count() {
  local region="$1"; shift
  local result
  result=$(aws --region "$region" --output json "$@" 2>/dev/null || true)
  if [[ -n "$result" ]] && [[ "$result" != "[]" ]] && [[ "$result" != "null" ]]; then
    echo "$result" | jq 'if type == "array" then length else 0 end' 2>/dev/null || echo 0
  else
    echo 0
  fi
}

# ============================================================
# Per-region scan — all API calls in parallel
# ============================================================

scan_region() {
  local r="$1"
  local tmpdir
  tmpdir=$(mktemp -d)

  # Fire all queries in parallel
  aws_count "$r" ec2 describe-instances \
    --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query 'Reservations[].Instances[]' > "$tmpdir/ec2" &
  aws_count "$r" ec2 describe-addresses --query 'Addresses' > "$tmpdir/eip" &
  aws_count "$r" ec2 describe-network-interfaces --query 'NetworkInterfaces' > "$tmpdir/eni" &
  aws_count "$r" ec2 describe-internet-gateways --query 'InternetGateways' > "$tmpdir/igw" &
  aws_count "$r" ec2 describe-nat-gateways \
    --filter "Name=state,Values=pending,available" --query 'NatGateways' > "$tmpdir/nat" &
  aws_count "$r" ec2 describe-vpn-gateways \
    --filters "Name=state,Values=pending,available" --query 'VpnGateways' > "$tmpdir/vgw" &
  aws_count "$r" ec2 describe-transit-gateways \
    --filters "Name=state,Values=pending,available" --query 'TransitGateways' > "$tmpdir/tgw" &
  aws_count "$r" ec2 describe-vpn-connections \
    --filters "Name=state,Values=pending,available" --query 'VpnConnections' > "$tmpdir/vpnc" &
  aws_count "$r" ec2 describe-vpcs --query 'Vpcs' > "$tmpdir/vpc" &
  aws_count "$r" ec2 describe-subnets --query 'Subnets' > "$tmpdir/subnet" &
  aws_count "$r" ec2 describe-security-groups --query 'SecurityGroups' > "$tmpdir/sg" &
  aws_count "$r" ec2 describe-route-tables --query 'RouteTables' > "$tmpdir/rt" &

  wait

  # Read results
  local ec2=$(cat "$tmpdir/ec2")  eip=$(cat "$tmpdir/eip")  eni=$(cat "$tmpdir/eni")
  local igw=$(cat "$tmpdir/igw")  nat=$(cat "$tmpdir/nat")  vgw=$(cat "$tmpdir/vgw")
  local tgw=$(cat "$tmpdir/tgw")  vpnc=$(cat "$tmpdir/vpnc")
  local vpc=$(cat "$tmpdir/vpc")  subnet=$(cat "$tmpdir/subnet")
  local sg=$(cat "$tmpdir/sg")    rt=$(cat "$tmpdir/rt")
  rm -rf "$tmpdir"

  # Token-bearing assets
  local tokens=$(( ec2 + eip + eni + igw + nat + vgw + tgw + vpnc ))
  local total=$(( tokens + vpc + subnet + sg + rt ))

  header "Region: ${r}"
  printf "\n  ${BOLD}%-30s %7s %7s${NC}\n" "Resource" "Count" "Tokens"
  divider
  printf "  %-30s ${WHITE}%7d${NC} ${YELLOW}%7d${NC}\n" "EC2 Instances"       "$ec2"  "$ec2"
  printf "  %-30s ${WHITE}%7d${NC} ${YELLOW}%7d${NC}\n" "Elastic IPs"         "$eip"  "$eip"
  printf "  %-30s ${WHITE}%7d${NC} ${YELLOW}%7d${NC}\n" "Network Interfaces"  "$eni"  "$eni"
  printf "  %-30s ${WHITE}%7d${NC} ${YELLOW}%7d${NC}\n" "Internet Gateways"   "$igw"  "$igw"
  printf "  %-30s ${WHITE}%7d${NC} ${YELLOW}%7d${NC}\n" "NAT Gateways"        "$nat"  "$nat"
  printf "  %-30s ${WHITE}%7d${NC} ${YELLOW}%7d${NC}\n" "VPN Gateways"        "$vgw"  "$vgw"
  printf "  %-30s ${WHITE}%7d${NC} ${YELLOW}%7d${NC}\n" "Transit Gateways"    "$tgw"  "$tgw"
  printf "  %-30s ${WHITE}%7d${NC} ${YELLOW}%7d${NC}\n" "VPN Connections"     "$vpnc" "$vpnc"
  printf "  %-30s ${WHITE}%7d${NC} ${DIM}%7s${NC}\n"    "VPCs"                "$vpc"  "-"
  printf "  %-30s ${WHITE}%7d${NC} ${DIM}%7s${NC}\n"    "Subnets"             "$subnet" "-"
  printf "  %-30s ${WHITE}%7d${NC} ${DIM}%7s${NC}\n"    "Security Groups"     "$sg"   "-"
  printf "  %-30s ${WHITE}%7d${NC} ${DIM}%7s${NC}\n"    "Route Tables"        "$rt"   "-"
  divider
  printf "  ${BOLD}%-30s %7d ${YELLOW}%7d${NC}\n" "REGION TOTAL" "$total" "$tokens"

  # Accumulate
  R_EC2[$r]=$ec2;  R_EIP[$r]=$eip;  R_ENI[$r]=$eni;  R_IGW[$r]=$igw
  R_NAT[$r]=$nat;  R_VGW[$r]=$vgw;  R_TGW[$r]=$tgw;  R_VPNC[$r]=$vpnc
  R_VPC[$r]=$vpc;  R_SUBNET[$r]=$subnet; R_SG[$r]=$sg; R_RT[$r]=$rt

  (( G_EC2 += ec2 ))     || true; (( G_EIP += eip ))       || true
  (( G_ENI += eni ))     || true; (( G_IGW += igw ))       || true
  (( G_NAT += nat ))     || true; (( G_VGW += vgw ))       || true
  (( G_TGW += tgw ))     || true; (( G_VPNC += vpnc ))    || true
  (( G_VPC += vpc ))     || true; (( G_SUBNET += subnet )) || true
  (( G_SG += sg ))       || true; (( G_RT += rt ))         || true
}

# ============================================================
# Global resources
# ============================================================

G_ZONES=0 G_BUCKETS=0

scan_global() {
  header "Global Resources"

  local tmpdir
  tmpdir=$(mktemp -d)

  # Parallel
  (aws --output json route53 list-hosted-zones 2>/dev/null || echo '{"HostedZones":[]}') \
    | jq '.HostedZones | length' > "$tmpdir/zones" &
  (aws --output json s3api list-buckets 2>/dev/null || echo '{"Buckets":[]}') \
    | jq '.Buckets | length' > "$tmpdir/buckets" &
  wait

  G_ZONES=$(cat "$tmpdir/zones" 2>/dev/null || echo 0)
  G_BUCKETS=$(cat "$tmpdir/buckets" 2>/dev/null || echo 0)
  rm -rf "$tmpdir"

  printf "  Route53 Hosted Zones:  ${WHITE}%d${NC}\n" "$G_ZONES"
  printf "  S3 Buckets:            ${WHITE}%d${NC}\n" "$G_BUCKETS"
}

# ============================================================
# Grand summary
# ============================================================

print_summary() {
  header "Grand Summary — All Regions"

  printf "\n  ${BOLD}%-18s %8s %8s${NC}\n" "Region" "Assets" "Tokens"
  printf "  %-18s %8s %8s\n" \
    "$(printf '%0.s─' {1..18})" "$(printf '%0.s─' {1..8})" "$(printf '%0.s─' {1..8})"

  for r in "${SCAN_REGIONS[@]}"; do
    local tok=$(( ${R_EC2[$r]:-0} + ${R_EIP[$r]:-0} + ${R_ENI[$r]:-0} + ${R_IGW[$r]:-0} \
      + ${R_NAT[$r]:-0} + ${R_VGW[$r]:-0} + ${R_TGW[$r]:-0} + ${R_VPNC[$r]:-0} ))
    local all=$(( tok + ${R_VPC[$r]:-0} + ${R_SUBNET[$r]:-0} + ${R_SG[$r]:-0} + ${R_RT[$r]:-0} ))
    printf "  %-18s ${WHITE}%8d${NC} ${YELLOW}%8d${NC}\n" "$r" "$all" "$tok"
  done

  printf "  %-18s %8s %8s\n" \
    "$(printf '%0.s─' {1..18})" "$(printf '%0.s─' {1..8})" "$(printf '%0.s─' {1..8})"

  local grand_tok=$(( G_EC2 + G_EIP + G_ENI + G_IGW + G_NAT + G_VGW + G_TGW + G_VPNC ))
  local grand_all=$(( grand_tok + G_VPC + G_SUBNET + G_SG + G_RT ))

  printf "  ${BOLD}%-18s %8d ${YELLOW}%8d${NC}\n\n" "TOTAL" "$grand_all" "$grand_tok"

  # Breakdown by type
  printf "  ${BOLD}%-30s %7s %7s${NC}\n" "Token-Bearing Resource" "Count" "Tokens"
  divider
  printf "  %-30s ${WHITE}%7d${NC} ${YELLOW}%7d${NC}\n" "EC2 Instances"       "$G_EC2"  "$G_EC2"
  printf "  %-30s ${WHITE}%7d${NC} ${YELLOW}%7d${NC}\n" "Elastic IPs"         "$G_EIP"  "$G_EIP"
  printf "  %-30s ${WHITE}%7d${NC} ${YELLOW}%7d${NC}\n" "Network Interfaces"  "$G_ENI"  "$G_ENI"
  printf "  %-30s ${WHITE}%7d${NC} ${YELLOW}%7d${NC}\n" "Internet Gateways"   "$G_IGW"  "$G_IGW"
  printf "  %-30s ${WHITE}%7d${NC} ${YELLOW}%7d${NC}\n" "NAT Gateways"        "$G_NAT"  "$G_NAT"
  printf "  %-30s ${WHITE}%7d${NC} ${YELLOW}%7d${NC}\n" "VPN Gateways"        "$G_VGW"  "$G_VGW"
  printf "  %-30s ${WHITE}%7d${NC} ${YELLOW}%7d${NC}\n" "Transit Gateways"    "$G_TGW"  "$G_TGW"
  printf "  %-30s ${WHITE}%7d${NC} ${YELLOW}%7d${NC}\n" "VPN Connections"     "$G_VPNC" "$G_VPNC"
  divider
  printf "  ${BOLD}%-30s %7d ${YELLOW}%7d${NC}\n\n" "TOTAL" "$grand_tok" "$grand_tok"

  printf "  ${DIM}Non-token assets: %d VPCs, %d Subnets, %d SGs, %d RTs${NC}\n" \
    "$G_VPC" "$G_SUBNET" "$G_SG" "$G_RT"
  printf "  ${DIM}Global: %d Route53 zones, %d S3 buckets${NC}\n" "$G_ZONES" "$G_BUCKETS"

  printf "\n  ${BOLD}${WHITE}═══ Estimated Management Tokens: %d ═══${NC}\n" "$grand_tok"
}

# ============================================================
# Main
# ============================================================

printf "${BOLD}AWS Resource Inventory — UAI3 Tech Summit${NC}\n"
printf "${DIM}Scanning %d region(s) (parallel API calls)...${NC}\n" "${#SCAN_REGIONS[@]}"
printf "${DIM}Started: $(date '+%Y-%m-%d %H:%M:%S %Z')${NC}\n"

for region in "${SCAN_REGIONS[@]}"; do
  scan_region "$region"
done

scan_global
print_summary

printf "\n${DIM}Completed: $(date '+%Y-%m-%d %H:%M:%S %Z')${NC}\n"
