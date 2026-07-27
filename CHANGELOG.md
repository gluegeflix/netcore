# NetCore Changelog

All notable changes to this project will be documented in this file.

The format follows a simplified version of Keep a Changelog.

---

## [Unreleased]

### Added

- Initial NetCore installer framework structure
- Modular installer architecture
- Centralized common helper library
- YAML-based configuration system
- Logging framework with fallback support
- Directory creation helper
- File backup helper
- Backup restore helper
- Confirmation prompt helper
- Service helper functions
- System preparation module
- Network preparation module
- Security preparation module
- Services preparation module

### Changed

- Standardized module loading pattern
- Moved execution control into the main launcher
- Converted modules to reusable function-based architecture
- Standardized module entry points:
  - `install_system()`
  - `install_network()`
  - `install_security()`
  - `install_services()`
- Improved installer output formatting
- Improved error handling and failure reporting
- Added support for non-root logging fallback
- Improved timezone configuration handling
- Improved package installation workflow

### Fixed

- Fixed missing command handling for:
  - `yq`
  - `date`
  - required system utilities
- Fixed log permission failures
- Fixed Fail2Ban directory creation handling
- Fixed module execution conflicts
- Fixed launcher/module separation issues
- Fixed configuration parsing issues

### In Progress

- Module naming standardization:
  - `install_system_packages()`
  - `install_network_packages()`
  - `install_security_packages()`
  - `install_service_packages()`

---

## [0.1.0] - Development Release

### Added

- Initial NetCore project foundation
- Ubuntu system preparation workflow
- Network validation workflow
- Security hardening workflow
- Service preparation workflow

---

## Future Roadmap

### Planned

- Command dependency validation helpers
  - `require_command()`
  - `require_package()`
  - `require_service()`

- Reliability improvements
  - `retry_command()`
  - improved rollback support

- Additional modules:
  - Docker
  - Tailscale
  - AdGuard Home
  - DNS services
  - Monitoring stack
  - Backup services

- Improved automation modes:
  - Interactive mode
  - Auto-confirm mode
  - Fully unattended mode

- Better reporting:
  - Module summaries
  - Pass/fail counters
  - Installation reports
