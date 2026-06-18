# Development Environment Scripts Guide

This document explains the differences between the various setup and update scripts used in your development environment management.

## Overview of Script Categories

### 1. Update Scripts (Synchronization Tools)
These scripts work bidirectionally to keep your system and configuration files in sync.

#### Update-JsonFromSetup.ps1
- **Direction**: Current System → Configuration File
- **Purpose**: Scans your current system and updates `versions.json` to reflect what's actually installed
- **Use Case**: When you've manually installed some tools and want to update your configuration to match
- **Key Features**:
  - Detects installed versions of system tools and Python packages
  - Updates the JSON configuration file with current versions
  - Can remove missing packages from the configuration
  - Creates backups before making changes

#### Update-SetupFromJson.ps1
- **Direction**: Configuration File → Current System
- **Purpose**: Reads `versions.json` and installs/updates tools to match the specified versions
- **Use Case**: When you want to ensure your system matches your desired configuration
- **Key Features**:
  - Installs system tools using the `Install-Tool` function
  - Updates Python interpreter to specified version
  - Installs Python packages from `requirements.txt`
  - Supports force updates even if versions match

### 2. Setup Scripts (Initial Environment Creation)
These scripts form a comprehensive pipeline for setting up a new development environment from scratch.

#### setup_all.ps1
- **Purpose**: System-wide tool installation
- **Scope**: Core development tools (VS Build Tools, Docker, etc.)
- **Key Features**:
  - Handles administrator privileges and relaunches
  - Uses winget for installations with detailed logging
  - Manages system restarts
  - Includes progress tracking and error handling
  - Focuses on tools that require system-level installation

#### bootstrap.ps1
- **Purpose**: Python environment setup
- **Scope**: Python installation and virtual environment creation
- **Key Features**:
  - Installs Python if not present
  - Creates and activates virtual environment
  - Sets up the Python-side of the development environment
  - Runs `setup_install.py` inside the virtual environment

#### setup_install.py
- **Purpose**: Python package and project setup
- **Scope**: Python packages and Django project configuration
- **Key Features**:
  - Handles pip upgrades and package installation
  - Sets up Django project specifics (migrations, static files)
  - Configures Docker integration
  - Provides setup completion instructions

## Key Functional Differences

### 1. Scope
- **Update Scripts**: Focused on version synchronization only
- **Setup Scripts**: Comprehensive environment creation from scratch

### 2. Error Handling
- **Update Scripts**: Basic error handling with warnings
- **Setup Scripts**: Detailed logging, retry mechanisms, progress tracking

### 3. Dependencies
- **Update Scripts**: Self-contained, work independently
- **Setup Scripts**: Sequential dependency (setup_all → bootstrap → setup_install)

### 4. Installation Methods
- **Update Scripts**: Use `Install-Tool` function with flexible command execution
- **Setup Scripts**: Use winget, PowerShell, and Python-specific installation methods

### 5. State Management
- **Update Scripts**: Compare current state with desired state
- **Setup Scripts**: Assume clean state and build everything

## When to Use Each Script

### Use Update Scripts When:
- You want to document your current setup (`Update-JsonFromSetup.ps1`)
- You want to ensure your system matches your configuration (`Update-SetupFromJson.ps1`)
- You're making incremental updates to your development environment
- You want to maintain consistency across multiple machines
- You need to synchronize versions between different environments

### Use Setup Scripts When:
- Setting up a new development machine
- Completely rebuilding your development environment
- Onboarding new team members
- When you need the full environment creation pipeline
- Starting fresh with a clean system

## Complementary Relationship

These scripts can work together in a complete workflow:

### Initial Setup Workflow
```powershell
# 1. Install system-wide tools
.\setup_all.ps1

# 2. Set up Python environment
.\bootstrap.ps1

# 3. Install Python packages and configure project
.\venv\Scripts\python.exe setup_install.py

# 4. Document the final setup
.\Scripts\Update-JsonFromSetup.ps1
```

### Maintenance Workflow
```powershell
# 1. Ensure system matches configuration
.\Scripts\Update-SetupFromJson.ps1

# 2. Update configuration if you've made manual changes
.\Scripts\Update-JsonFromSetup.ps1
```

## Configuration Files

### versions.json
- Used by both update scripts
- Contains version information for system tools and Python interpreter
- Structure:
  ```json
  {
    "system_tools": [
      {
        "appName": "Tool Name",
        "installCommand": "Installation command",
        "checkCommand": "Verification command",
        "envPath": "Path to add to environment",
        "manualInstallUrl": "URL for manual install",
        "manualInstallPath": "Path for manual installer"
      }
    ],
    "python": {
      "version": "Python version",
      "installer_url": "Python installer URL"
    }
  }
  ```

### requirements.txt
- Used by `Update-SetupFromJson.ps1` and `setup_install.py`
- Contains Python package dependencies
- Standard Python requirements file format

## Best Practices

### For Update Scripts
- Run `Update-JsonFromSetup.ps1` after making any manual installations
- Run `Update-SetupFromJson.ps1` before starting development to ensure consistency
- Use the `-ForceUpdate` parameter when you want to reinstall everything

### For Setup Scripts
- Always run as Administrator (setup scripts handle elevation automatically)
- Review logs after installation to verify success
- Follow the sequential order: setup_all → bootstrap → setup_install.py
- Use the provided instructions for next steps after setup completion

## Troubleshooting

### Common Issues with Update Scripts
- **Permission errors**: Run as Administrator
- **Path resolution**: Ensure scripts are in the correct directory structure
- **Missing tools**: Check if tools are installed in non-standard locations

### Common Issues with Setup Scripts
- **Installation failures**: Check logs for specific error messages
- **Environment variables**: Restart terminal after installation
- **Docker issues**: Ensure Docker Desktop is running before setup
- **Python issues**: Verify Python installation and PATH configuration

## Summary

The update scripts are for **maintenance and synchronization**, while the setup scripts are for **initial environment creation**. They serve different but complementary roles in managing your development environment. Use them together to maintain a consistent, well-documented development setup across your team and environments.