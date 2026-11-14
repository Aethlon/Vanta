# VANTA

Native Rust codebase intelligence: fast repository search, code graphs,
dependency paths, and blast-radius analysis. No model calls, no API key, and no
source code leaves the machine.

**Source is private.** This repository is the public distribution channel for
release binaries and installers.

## Install

macOS / Linux:

```bash
curl -fsSL https://vanta.aethlon.xyz/install.sh | bash
```

Windows PowerShell:

```powershell
irm https://vanta.aethlon.xyz/install.ps1 | iex
```

Or download the archive for your platform from
[Releases](https://github.com/Aethlon/Vanta/releases). Every release includes a
SHA-256 checksum.

## Update

```bash
vanta update --check
vanta update
```

## Documentation

https://vanta.aethlon.xyz/docs

## License

VANTA is proprietary software. Use is governed by the license shipped with the
binary and installer. Redistribution, modification, and hosted-service resale
are not granted.
