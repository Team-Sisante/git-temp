# Cross-Platform Compatibility Patterns

This document summarizes the established patterns for ensuring `Scripts/menu.js` and other automation scripts run correctly on Windows, Linux, and macOS.

## 1. Path Handling
- **Always use `path.resolve()` or `path.join()`**: Never concatenate paths manually (e.g., `'/' + dir + '/' + file`).
- **Use `path.delimiter`**: When constructing environment variables like `PATH` that are platform-dependent (colon on Unix, semicolon on Windows).

## 2. Platform Detection
- Use `os.platform() === 'win32'` to differentiate between Windows and Unix-like (Linux/macOS) systems.
```javascript
const isWindows = os.platform() === 'win32';
```

## 3. Command Execution
- **`execSync`**: Use for simple, blocking commands where output handling is straightforward. 
- **`spawn`**: Preferred for long-running or interactive processes, or when you need better control over `stdout`/`stderr` streams.
- **Shell Wrapper**: When running shell-specific commands (like `source activate`), explicitly use the correct shell:
```javascript
const isGitBash = process.env.MSYSTEM === 'MINGW64' || process.env.MSYSTEM === 'MINGW32';
const options = { shell: isGitBash ? 'bash' : true };
```

## 4. Virtual Environment Activation
- **Windows**: `call "path/to/venv/Scripts/activate.bat"`
- **Unix**: `source "path/to/venv/bin/activate"`
- **Pattern**:
```javascript
if (isWindows) {
  finalCommand = `"${path.join(venvPath, 'Scripts', 'activate.bat')}" && ${command}`;
} else {
  finalCommand = `source "${path.join(venvPath, 'bin', 'activate')}" && ${command}`;
}
```

## 5. Docker Compose
- **Compatibility**: Prefer `docker compose` (Docker v2) but fallback to `docker-compose` if necessary.
```javascript
function getDockerCompose() {
    try {
        execSync('docker compose version', { stdio: 'ignore' });
        return 'docker compose';
    } catch (e) {
        return 'docker-compose';
    }
}
```
