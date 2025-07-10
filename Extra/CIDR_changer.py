#!/usr/bin/env python3
import ipaddress
import subprocess
import re

def range_to_cidrs(start_ip, end_ip):
    """IP 범위를 정확한 CIDR 리스트로 변환"""
    start = int(ipaddress.IPv4Address(start_ip))
    end = int(ipaddress.IPv4Address(end_ip))
    
    cidrs = []
    while start <= end:
        # 현재 시작 IP에서 가능한 최대 블록 크기 계산
        max_block = 1
        while (start & (max_block - 1)) == 0 and start + max_block - 1 <= end:
            max_block <<= 1
        max_block >>= 1
        
        # CIDR 표기법으로 변환
        prefix_len = 32 - (max_block - 1).bit_length()
        cidrs.append(f"{ipaddress.IPv4Address(start)}/{prefix_len}")
        start += max_block
    
    return cidrs

# 파일 읽기
filename = input("IP 범위 파일명을 입력하세요: ").strip()

try:
    with open(filename, 'r') as f:
        lines = f.readlines()
except FileNotFoundError:
    print(f"파일 '{filename}'을 찾을 수 없습니다.")
    exit(1)

all_cidrs = set()

for line in lines:
    line = line.strip()
    if not line or line.startswith('#'):
        continue
    
    # CIDR 형태
    if '/' in line:
        all_cidrs.add(line)
    # 범위 형태 (예: 114.96.0.0 - 114.103.255.255)
    elif ' - ' in line:
        parts = line.split(' - ')
        if len(parts) == 2:
            start_ip = parts[0].strip()
            end_ip = parts[1].strip()
            cidrs = range_to_cidrs(start_ip, end_ip)
            all_cidrs.update(cidrs)

print(f"총 {len(all_cidrs)}개 CIDR 블록을 차단합니다.")

# UFW로 차단
for cidr in sorted(all_cidrs):
    cmd = ['sudo', 'ufw', 'deny', 'from', cidr]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        print(f"차단됨: {cidr}")
    else:
        print(f"실패: {cidr}")

print("완료.")