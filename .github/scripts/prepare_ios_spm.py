"""Resolve the native binary before Flutter starts background SwiftPM fetches.

SwiftPM versions affected by swiftlang/swift-package-manager#10138 can race
while populating a cold binary-artifact cache. Resolving the standalone native
package first gives subsequent Flutter/Xcode resolvers a complete cached archive.
The download still uses SwiftPM's checksum validation.
"""

import argparse
import os
from pathlib import Path
import re
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--cache-path", type=Path,
        help="Use an isolated SwiftPM cache for local cold-cache verification.",
    )
    args = parser.parse_args()
    repository = Path(__file__).resolve().parents[2]
    source = (repository / "ios/nb_maps_flutter/Package.swift").read_text()
    url = "https://github.com/nextbillion-ai/maps-native-distribution"
    pin = re.search(
        rf'url:\s*"{re.escape(url)}",\s*exact:\s*"([^"]+)"', source
    )
    if pin is None:
        parser.error("Cannot find the exact native Maps SDK pin in Package.swift")
    version = pin.group(1)
    print(f"Resolving native Maps SDK {version} before Flutter", flush=True)
    with tempfile.TemporaryDirectory(
        prefix="nbmaps-spm-", dir=os.environ.get("RUNNER_TEMP")
    ) as scratch:
        checkout = Path(scratch) / "distribution"
        subprocess.run(
            ["git", "-c", "advice.detachedHead=false", "clone", "--quiet",
             "--depth", "1", "--branch", version, url, str(checkout)],
            check=True,
        )
        command = ["swift", "package", "--package-path", str(checkout)]
        if args.cache_path is not None:
            command.extend(["--cache-path", str(args.cache_path.resolve())])
        # In CI, omit --cache-path so Flutter/Xcode reuse SwiftPM's default
        # org.swift.swiftpm/artifacts cache after this synchronous resolve ends.
        subprocess.run([*command, "resolve"], check=True)


if __name__ == "__main__":
    main()
