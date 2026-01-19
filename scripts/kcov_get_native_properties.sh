#!/bin/sh

# Coverage harness for scripts/get_native_properties.sh
#
# Runs a curated set of cases under kcov to exercise branches.
# Intended for Linux CI where kcov is available.

set -eu

KCOV_BIN=${KCOV_BIN:-kcov}
OUT_DIR=${OUT_DIR:-coverage/kcov}
RAW_DIR=${RAW_DIR:-coverage/raw}

REPO_ROOT=${REPO_ROOT:-$(pwd)}

SCRIPT='scripts/get_native_properties.sh'
FIX='tests/fixtures/get_native_properties'

# kcov tends to count here-doc content as instrumented lines even though it's
# just data fed into the selector tables (not executable shell statements).
# Exclude all <<'EOF' ... EOF blocks so coverage reflects executable logic.
# Note: in this script the terminating EOF markers are indented.
KCOV_EXCLUDE_REGION_TABLES="<<'EOF':^[[:space:]]*EOF$"

# kcov counts the *contents* of multi-line awk programs (inside single quotes)
# as if they were executable shell statements. Exclude these regions so the
# report reflects what the shell actually executes.
# NOTE: The end-regex matches the literal "$cpuinfo_path" in the script under
# test (so we must not expand $cpuinfo_path here).
KCOV_EXCLUDE_REGION_AWK="^[[:space:]]*awk[[:space:]]*':^[[:space:]]*'[[:space:]]*\"\\\$cpuinfo_path\""

rm -rf "$OUT_DIR" "$RAW_DIR"
mkdir -p "$OUT_DIR" "$RAW_DIR"

run_case() {
	name=$1
	expect_fail=${EXPECT_FAIL:-0}
	# IMPORTANT: run kcov in "bash script" mode by passing the script as the in-file.
	# Environment variables are provided by prefixing the function call:
	#   GP_UNAME_S=... GP_UNAME_M=... run_case name
	#
	# We force bash as the parser so we can collect coverage even though the script
	# is POSIX sh (shebang is /bin/sh).
	rc=0
	"$KCOV_BIN" \
		--bash-parser=/bin/bash \
		--bash-method=DEBUG \
		--include-path="$REPO_ROOT/scripts" \
		--exclude-region="$KCOV_EXCLUDE_REGION_TABLES" \
		--exclude-region="$KCOV_EXCLUDE_REGION_AWK" \
		"$RAW_DIR/$name" \
		"$SCRIPT" >/dev/null || rc=$?
	if [ "$rc" -ne 0 ] && [ "$expect_fail" -eq 0 ]; then
		return "$rc"
	fi
	return 0
}

# ---- Linux: x86 tiers (table-driven)
GP_UNAME_S=Linux GP_UNAME_M=x86_64 GP_CPUINFO="$FIX/x86_64_base.cpuinfo" run_case linux_x86_64_base
GP_UNAME_S=Linux GP_UNAME_M=x86_64 GP_CPUINFO="$FIX/x86_64_popcnt_only.cpuinfo" run_case linux_x86_64_popcnt_only
GP_UNAME_S=Linux GP_UNAME_M=x86_64 GP_CPUINFO="$FIX/x86_64_sse3_popcnt_pni.cpuinfo" run_case linux_x86_64_sse3_popcnt_pni
GP_UNAME_S=Linux GP_UNAME_M=x86_64 GP_CPUINFO="$FIX/x86_64_sse3_popcnt_sse3.cpuinfo" run_case linux_x86_64_sse3_popcnt_sse3
GP_UNAME_S=Linux GP_UNAME_M=x86_64 GP_CPUINFO="$FIX/x86_64_ssse3.cpuinfo" run_case linux_x86_64_ssse3
GP_UNAME_S=Linux GP_UNAME_M=x86_64 GP_CPUINFO="$FIX/x86_64_sse41_popcnt.cpuinfo" run_case linux_x86_64_sse41_popcnt
GP_UNAME_S=Linux GP_UNAME_M=x86_64 GP_CPUINFO="$FIX/x86_64_avx2.cpuinfo" run_case linux_x86_64_avx2
GP_UNAME_S=Linux GP_UNAME_M=x86_64 GP_CPUINFO="$FIX/x86_64_bmi2_only.cpuinfo" run_case linux_x86_64_bmi2_only
GP_UNAME_S=Linux GP_UNAME_M=x86_64 GP_CPUINFO="$FIX/x86_64_amd_zen12_exclude_bmi2.cpuinfo" run_case linux_x86_64_zen12_exclude_bmi2
GP_UNAME_S=Linux GP_UNAME_M=x86_64 GP_CPUINFO="$FIX/x86_64_avxvnni.cpuinfo" run_case linux_x86_64_avxvnni
GP_UNAME_S=Linux GP_UNAME_M=x86_64 GP_CPUINFO="$FIX/x86_64_avx512.cpuinfo" run_case linux_x86_64_avx512
GP_UNAME_S=Linux GP_UNAME_M=x86_64 GP_CPUINFO="$FIX/x86_64_vnni512.cpuinfo" run_case linux_x86_64_vnni512
GP_UNAME_S=Linux GP_UNAME_M=x86_64 GP_CPUINFO="$FIX/x86_64_avx512icl.cpuinfo" run_case linux_x86_64_avx512icl

# ---- Linux: x86 32 tiers
GP_UNAME_S=Linux GP_UNAME_M=i686 GP_CPUINFO="$FIX/x86_32_base.cpuinfo" run_case linux_x86_32_base
GP_UNAME_S=Linux GP_UNAME_M=i686 GP_CPUINFO="$FIX/x86_32_sse2.cpuinfo" run_case linux_x86_32_sse2
GP_UNAME_S=Linux GP_UNAME_M=i686 GP_CPUINFO="$FIX/x86_32_sse41_popcnt.cpuinfo" run_case linux_x86_32_sse41_popcnt

# ---- Linux: ARM paths
GP_UNAME_S=Linux GP_UNAME_M=armv7l GP_CPUINFO="$FIX/armv7_neon.cpuinfo" run_case linux_armv7_neon
GP_UNAME_S=Linux GP_UNAME_M=armv7l GP_CPUINFO="$FIX/armv7.cpuinfo" run_case linux_armv7_no_neon
GP_UNAME_S=Linux GP_UNAME_M=armv7l GP_CPUINFO="$FIX/does_not_exist.cpuinfo" run_case linux_armv7_cpuinfo_missing_fallback_uname
GP_UNAME_S=Linux GP_UNAME_M=armv8l GP_CPUINFO="$FIX/does_not_exist.cpuinfo" run_case linux_armv8l_cpuinfo_missing_fallback_uname
GP_UNAME_S=Linux GP_UNAME_M=armv5tel GP_CPUINFO="$FIX/does_not_exist.cpuinfo" run_case linux_armv5_cpuinfo_missing_fallback_uname
GP_UNAME_S=Linux GP_UNAME_M=armv6l GP_CPUINFO="$FIX/does_not_exist.cpuinfo" run_case linux_armv6_cpuinfo_missing_fallback_uname
GP_UNAME_S=Linux GP_UNAME_M=armv5tel GP_CPUINFO="$FIX/armv5.cpuinfo" run_case linux_armv5
GP_UNAME_S=Linux GP_UNAME_M=armv6l GP_CPUINFO="$FIX/armv6.cpuinfo" run_case linux_armv6
GP_UNAME_S=Linux GP_UNAME_M=arm GP_CPUINFO="$FIX/arm_processor_only_v7.cpuinfo" run_case linux_arm_processor_only_v7
GP_UNAME_S=Linux GP_UNAME_M=arm GP_CPUINFO="$FIX/arm_unknown_neon_only.cpuinfo" run_case linux_arm_unknown_neon_only
GP_UNAME_S=Linux GP_UNAME_M=arm GP_CPUINFO="$FIX/arm_unknown_no_neon.cpuinfo" run_case linux_arm_unknown_no_neon
GP_UNAME_S=Linux GP_UNAME_M=arm GP_CPUINFO="$FIX/does_not_exist.cpuinfo" run_case linux_arm_cpuinfo_missing_unknown

# ---- Linux: AArch64 paths
GP_UNAME_S=Linux GP_UNAME_M=aarch64 GP_CPUINFO="$FIX/armv8.cpuinfo" run_case linux_aarch64_armv8
GP_UNAME_S=Linux GP_UNAME_M=aarch64 GP_CPUINFO="$FIX/armv8_dotprod.cpuinfo" run_case linux_aarch64_armv8_dotprod

# ---- Linux: PPC64 parse branches
GP_UNAME_S=Linux GP_UNAME_M=ppc64le GP_CPUINFO="$FIX/ppc64_power9_altivec.cpuinfo" run_case linux_ppc64_power9_altivec
GP_UNAME_S=Linux GP_UNAME_M=ppc64 GP_CPUINFO="$FIX/ppc64_power6_altivec.cpuinfo" run_case linux_ppc64_power6_altivec
GP_UNAME_S=Linux GP_UNAME_M=ppc64 GP_CPUINFO="$FIX/ppc64_altivec_cpu_unparseable.cpuinfo" run_case linux_ppc64_altivec_cpu_unparseable
GP_UNAME_S=Linux GP_UNAME_M=ppc64le GP_CPUINFO="$FIX/ppc64_altivec_cpu_numeric_only.cpuinfo" run_case linux_ppc64_altivec_cpu_numeric_only
GP_UNAME_S=Linux GP_UNAME_M=ppc64le GP_CPUINFO="$FIX/ppc64_no_altivec.cpuinfo" run_case linux_ppc64_no_altivec

# ---- Linux: PPC32
GP_UNAME_S=Linux GP_UNAME_M=ppc GP_CPUINFO="$FIX/ppc32.cpuinfo" run_case linux_ppc32

# ---- Linux: other arch families
GP_UNAME_S=Linux GP_UNAME_M=loongarch64 GP_CPUINFO="$FIX/loongarch64_lasx.cpuinfo" run_case linux_loongarch64_lasx
GP_UNAME_S=Linux GP_UNAME_M=loongarch64 GP_CPUINFO="$FIX/loongarch64_lsx.cpuinfo" run_case linux_loongarch64_lsx
GP_UNAME_S=Linux GP_UNAME_M=loongarch64 GP_CPUINFO="$FIX/loongarch64.cpuinfo" run_case linux_loongarch64_base
GP_UNAME_S=Linux GP_UNAME_M=riscv64 GP_CPUINFO="$FIX/riscv64.cpuinfo" run_case linux_riscv64
GP_UNAME_S=Linux GP_UNAME_M=e2k GP_CPUINFO="$FIX/e2k.cpuinfo" run_case linux_e2k

# ---- Linux: get_bits invalid fallback
GP_UNAME_S=Linux GP_UNAME_M=mysterycpu GP_BITS=wat run_case linux_unknown_machine_bits_invalid
GP_UNAME_S=Linux GP_UNAME_M=mysterycpu GP_BITS=32 run_case linux_unknown_machine_bits_32
GP_UNAME_S=Linux GP_UNAME_M=mysterycpu GP_BITS=64 run_case linux_unknown_machine_bits_64
GP_UNAME_S=Linux GP_UNAME_M=mysterycpu run_case linux_unknown_machine_bits_getconf

# ---- Linux: x86 unreadable/missing cpuinfo (exercises get_flags else + is_znver_1_2 unreadable)
GP_UNAME_S=Linux GP_UNAME_M=x86_64 GP_CPUINFO="$FIX/does_not_exist.cpuinfo" run_case linux_x86_64_cpuinfo_missing
GP_UNAME_S=Linux GP_UNAME_M=x86_64 GP_CPUINFO="$FIX/x86_64_empty_vendor_only.cpuinfo" run_case linux_x86_64_vendor_only

# ---- Darwin: sysctl call path (no override), plus apple-silicon
GP_UNAME_S=Darwin GP_UNAME_M=arm64 run_case darwin_arm64

# Darwin x86_64 with explicit sysctl feature overrides
GP_UNAME_S=Darwin GP_UNAME_M=x86_64 GP_SYSCTL_FEATURES='AVX2 SSE3' run_case darwin_x86_64_override_avx2
GP_UNAME_S=Darwin GP_UNAME_M=x86_64 GP_SYSCTL_FEATURES=' ' run_case darwin_x86_64_override_empty

# Ensure GP_SYSCTL_FEATURES is truly absent/empty to exercise the sysctl-call branch.
(
	unset GP_SYSCTL_FEATURES
	GP_UNAME_S=Darwin GP_UNAME_M=x86_64 run_case darwin_x86_64_sysctl_real
)

# Darwin unknown machine: general-32/general-64 fallback
GP_UNAME_S=Darwin GP_UNAME_M=mips64 GP_BITS=32 run_case darwin_unknown_bits_32
GP_UNAME_S=Darwin GP_UNAME_M=mips64 GP_BITS=64 run_case darwin_unknown_bits_64

# ---- Windows patterns
GP_UNAME_S=MINGW64_ARM64_NT-10.0 GP_UNAME_M=aarch64 run_case mingw_arm64_pattern
GP_UNAME_S=MSYS_NT-10.0 GP_UNAME_M=x86_64 GP_CPUINFO="$FIX/x86_64_avx2.cpuinfo" run_case msys_x86_pattern
GP_UNAME_S=CYGWIN_NT-10.0 GP_UNAME_M=x86_64 GP_CPUINFO="$FIX/x86_64_sse41_popcnt.cpuinfo" run_case cygwin_x86_pattern

# ---- Unsupported OS
GP_UNAME_S=Plan9 GP_UNAME_M=x86_64 EXPECT_FAIL=1 run_case unsupported_os

# Merge into a single report
"$KCOV_BIN" --merge "$OUT_DIR" "$RAW_DIR"/*

# Basic sanity: ensure the merged report exists and contains HTML
[ -d "$OUT_DIR" ]
if ! find "$OUT_DIR" -type f -name 'index.html' -print -quit | grep -q .; then
	printf '%s\n' "kcov report looks empty (missing index.html)" >&2
	printf '%s\n' "kcov: $KCOV_BIN, include-path: $REPO_ROOT/scripts" >&2
	exit 1
fi

# Additional sanity: fail if kcov produced a merged coverage.json with 0 instrumented lines.
cov_json=$(find "$OUT_DIR" -type f -name 'coverage.json' -print -quit 2>/dev/null || true)
if [ -n "${cov_json:-}" ]; then
	if grep -Eq '"instrumented"[[:space:]]*:[[:space:]]*0|"instrumentedLines"[[:space:]]*:[[:space:]]*0' "$cov_json"; then
		printf '%s\n' "kcov merged coverage.json reports 0 instrumented lines" >&2
		printf '%s\n' "coverage.json: $cov_json" >&2
		exit 1
	fi
fi
