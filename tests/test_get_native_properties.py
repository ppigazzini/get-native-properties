"""Tests for get_native_properties script."""

import os
import shutil
import subprocess
import unittest
from pathlib import Path
from typing import TypedDict

REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = REPO_ROOT / "scripts" / "get_native_properties.sh"
FIXTURES = REPO_ROOT / "tests" / "fixtures" / "get_native_properties"
SH = Path(shutil.which("sh") or "/bin/sh")


def read_fixture(path: Path) -> str:
    """Read a fixture file as text."""
    return path.read_text(encoding="utf-8")


def build_env(
    *,
    uname_s: str,
    uname_m: str,
    cpuinfo: Path | None = None,
    bits: str | None = None,
    sysctl_features: str | None = None,
) -> dict[str, str]:
    """Build an environment for invoking the script under test."""
    env = os.environ.copy()
    env["GP_UNAME_S"] = uname_s
    env["GP_UNAME_M"] = uname_m
    if cpuinfo is not None:
        env["GP_CPUINFO"] = str(cpuinfo)
    else:
        env.pop("GP_CPUINFO", None)
    if bits is not None:
        env["GP_BITS"] = bits
    else:
        env.pop("GP_BITS", None)
    if sysctl_features is not None:
        env["GP_SYSCTL_FEATURES"] = sysctl_features
    else:
        env.pop("GP_SYSCTL_FEATURES", None)
    return env


def run_script(
    *,
    uname_s: str,
    uname_m: str,
    cpuinfo: Path | None = None,
    bits: str | None = None,
    sysctl_features: str | None = None,
) -> str:
    """Run the script and return stdout, raising on non-zero exit."""
    env = build_env(
        uname_s=uname_s,
        uname_m=uname_m,
        cpuinfo=cpuinfo,
        bits=bits,
        sysctl_features=sysctl_features,
    )
    try:
        proc = subprocess.run(  # noqa: S603
            [str(SH), str(SCRIPT)],
            env=env,
            cwd=str(REPO_ROOT),
            text=True,
            capture_output=True,
            check=True,
        )
    except subprocess.CalledProcessError as exc:
        msg = (
            f"script failed: rc={exc.returncode}\n"
            f"stdout={exc.stdout}\n"
            f"stderr={exc.stderr}"
        )
        raise RuntimeError(msg) from exc
    return proc.stdout


def run_script_expect_fail(
    *,
    uname_s: str,
    uname_m: str,
    cpuinfo: Path | None = None,
    bits: str | None = None,
) -> tuple[int, str, str]:
    """Run the script and return (rc, stdout, stderr) for failures."""
    env = build_env(
        uname_s=uname_s,
        uname_m=uname_m,
        cpuinfo=cpuinfo,
        bits=bits,
        sysctl_features=None,
    )
    proc = subprocess.run(  # noqa: S603
        [str(SH), str(SCRIPT)],
        env=env,
        cwd=str(REPO_ROOT),
        text=True,
        capture_output=True,
        check=False,
    )
    return proc.returncode, proc.stdout, proc.stderr


class TestGetNativeProperties(unittest.TestCase):
    """Coverage for supported OS/arch combinations."""

    def test_linux_fixtures(self) -> None:
        """Validate Linux fixture mappings."""
        cases = [
            ("x86_64", "x86_64_base.cpuinfo", "x86-64\n"),
            ("i686", "x86_32_base.cpuinfo", "x86-32\n"),
            ("x86_64", "x86_64_avx512icl.cpuinfo", "x86-64-avx512icl\n"),
            ("x86_64", "x86_64_vnni512.cpuinfo", "x86-64-vnni512\n"),
            ("x86_64", "x86_64_avx512.cpuinfo", "x86-64-avx512\n"),
            ("x86_64", "x86_64_avxvnni.cpuinfo", "x86-64-avxvnni\n"),
            ("x86_64", "x86_64_bmi2_only.cpuinfo", "x86-64-bmi2\n"),
            ("x86_64", "x86_64_amd_zen12_exclude_bmi2.cpuinfo", "x86-64-avx2\n"),
            ("x86_64", "x86_64_avx2.cpuinfo", "x86-64-avx2\n"),
            ("x86_64", "x86_64_sse41_popcnt.cpuinfo", "x86-64-sse41-popcnt\n"),
            ("x86_64", "x86_64_ssse3.cpuinfo", "x86-64-ssse3\n"),
            ("x86_64", "x86_64_sse3_popcnt_pni.cpuinfo", "x86-64-sse3-popcnt\n"),
            ("i686", "x86_32_sse41_popcnt.cpuinfo", "x86-32-sse41-popcnt\n"),
            ("i686", "x86_32_sse2.cpuinfo", "x86-32-sse2\n"),
            ("x86_64", "empty.cpuinfo", "x86-64\n"),
            ("i686", "empty.cpuinfo", "x86-32\n"),
            ("aarch64", "armv8_dotprod.cpuinfo", "armv8-dotprod\n"),
            ("aarch64", "armv8.cpuinfo", "armv8\n"),
            ("arm64", "armv8.cpuinfo", "armv8\n"),
            ("armv7l", "armv7_neon.cpuinfo", "armv7-neon\n"),
            ("armv7l", "armv7.cpuinfo", "armv7\n"),
            ("armv7l", "armv6.cpuinfo", "general-32\n"),
            ("armv5tel", "armv5.cpuinfo", "general-32\n"),
            ("loongarch64", "loongarch64_lasx.cpuinfo", "loongarch64-lasx\n"),
            ("loongarch64", "loongarch64_lsx.cpuinfo", "loongarch64-lsx\n"),
            ("loongarch64", "loongarch64.cpuinfo", "loongarch64\n"),
            ("ppc64le", "ppc64_power9_altivec.cpuinfo", "ppc-64-vsx\n"),
            ("ppc64", "ppc64_power6_altivec.cpuinfo", "ppc-64-altivec\n"),
            ("ppc64le", "ppc64_no_altivec.cpuinfo", "ppc-64\n"),
            ("ppc", "ppc32.cpuinfo", "ppc-32\n"),
            ("ppc32", "ppc32.cpuinfo", "ppc-32\n"),
            ("powerpc", "ppc32.cpuinfo", "ppc-32\n"),
            ("riscv64", "riscv64.cpuinfo", "riscv64\n"),
            ("e2k", "e2k.cpuinfo", "e2k\n"),
        ]
        for uname_m, fixture, expected in cases:
            with self.subTest(uname_m=uname_m, fixture=fixture, expected=expected):
                out = run_script(
                    uname_s="Linux",
                    uname_m=uname_m,
                    cpuinfo=FIXTURES / fixture,
                )
                assert out == expected  # noqa: S101

    def test_linux_unknown_machine_falls_back_general_32(self) -> None:
        """Unknown Linux machine falls back to 32-bit generic."""
        out = run_script(uname_s="Linux", uname_m="mysterycpu", bits="32")
        assert out == "general-32\n"  # noqa: S101

    def test_linux_unknown_machine_falls_back_general_64(self) -> None:
        """Unknown Linux machine falls back to 64-bit generic."""
        out = run_script(uname_s="Linux", uname_m="mysterycpu", bits="64")
        assert out == "general-64\n"  # noqa: S101

    def test_windows_variants(self) -> None:
        """Validate Windows variants using Linux-style fixtures."""
        cases = [
            ("MSYS_NT-10.0", "x86_64", "x86_64_avx2.cpuinfo", "x86-64-avx2\n"),
            (
                "CYGWIN_NT-10.0",
                "x86_64",
                "x86_64_sse41_popcnt.cpuinfo",
                "x86-64-sse41-popcnt\n",
            ),
            ("MINGW64_ARM64_NT-10.0", "aarch64", "empty.cpuinfo", "armv8-dotprod\n"),
        ]
        for uname_s, uname_m, fixture, expected in cases:
            with self.subTest(uname_s=uname_s, uname_m=uname_m, fixture=fixture):
                out = run_script(
                    uname_s=uname_s,
                    uname_m=uname_m,
                    cpuinfo=FIXTURES / fixture,
                )
                assert out == expected  # noqa: S101

    def test_darwin_variants(self) -> None:
        """Validate Darwin variants using sysctl fixtures."""

        class DarwinCase(TypedDict):
            uname_m: str
            bits: str | None
            sysctl_fixture: str | None
            sysctl_features: str | None
            expected: str

        cases: list[DarwinCase] = [
            {
                "uname_m": "arm64",
                "bits": None,
                "sysctl_fixture": None,
                "sysctl_features": None,
                "expected": "apple-silicon\n",
            },
            {
                "uname_m": "mips64",
                "bits": "64",
                "sysctl_fixture": None,
                "sysctl_features": None,
                "expected": "general-64\n",
            },
            {
                "uname_m": "x86_64",
                "bits": None,
                "sysctl_fixture": "darwin_x86_64_avx2.sysctl",
                "sysctl_features": None,
                "expected": "x86-64-avx2\n",
            },
            {
                "uname_m": "x86_64",
                "bits": None,
                "sysctl_fixture": "darwin_x86_64_avx512icl.sysctl",
                "sysctl_features": None,
                "expected": "x86-64-avx512icl\n",
            },
            {
                "uname_m": "x86_64",
                "bits": None,
                "sysctl_fixture": None,
                "sysctl_features": "sse3 ssse3 sse4.1 popcnt",
                "expected": "x86-64-sse41-popcnt\n",
            },
            {
                "uname_m": "x86_64",
                "bits": None,
                "sysctl_fixture": None,
                "sysctl_features": " ",
                "expected": "x86-64\n",
            },
        ]
        for case in cases:
            with self.subTest(
                uname_m=case["uname_m"],
                sysctl_fixture=case["sysctl_fixture"],
                bits=case["bits"],
            ):
                sysctl_features = case["sysctl_features"]
                if case["sysctl_fixture"]:
                    sysctl_features = read_fixture(FIXTURES / case["sysctl_fixture"])
                out = run_script(
                    uname_s="Darwin",
                    uname_m=case["uname_m"],
                    bits=case["bits"],
                    sysctl_features=sysctl_features,
                )
                assert out == case["expected"]  # noqa: S101

    def test_unknown_os_exits_nonzero(self) -> None:
        """Unsupported OS should exit non-zero with a clear error."""
        rc, _stdout, stderr = run_script_expect_fail(uname_s="Plan9", uname_m="x86_64")
        assert rc != 0  # noqa: S101
        assert "Unsupported system type" in stderr  # noqa: S101


if __name__ == "__main__":
    unittest.main()
