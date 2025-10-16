use anyhow::{Context, Result};
use std::path::PathBuf;
use std::fs;

/// Get the runtime directory for daemon sockets and PID files
pub fn runtime_dir() -> Result<PathBuf> {
    let dir = if let Ok(runtime_dir) = std::env::var("XDG_RUNTIME_DIR") {
        PathBuf::from(runtime_dir)
    } else {
        let home = std::env::var("HOME").context("HOME environment variable not set")?;
        PathBuf::from(home).join(".local/run")
    };

    let agent_tools_dir = dir.join("agent-tools");
    fs::create_dir_all(&agent_tools_dir)
        .context("Failed to create runtime directory")?;

    Ok(agent_tools_dir)
}

/// Get the socket path for a daemon
pub fn socket_path(daemon_name: &str) -> Result<PathBuf> {
    Ok(runtime_dir()?.join(format!("{}.sock", daemon_name)))
}

/// Get the PID file path for a daemon
pub fn pid_file_path(daemon_name: &str) -> Result<PathBuf> {
    Ok(runtime_dir()?.join(format!("{}.pid", daemon_name)))
}

/// Check if a daemon is running
pub fn is_running(daemon_name: &str) -> Result<bool> {
    let pid_file = pid_file_path(daemon_name)?;

    if !pid_file.exists() {
        return Ok(false);
    }

    let pid_str = fs::read_to_string(&pid_file)
        .context("Failed to read PID file")?;
    let pid: i32 = pid_str.trim().parse()
        .context("Invalid PID in PID file")?;

    // Check if process exists
    unsafe {
        Ok(libc::kill(pid, 0) == 0)
    }
}

/// Write PID file for daemon
pub fn write_pid_file(daemon_name: &str) -> Result<()> {
    let pid_file = pid_file_path(daemon_name)?;
    let pid = std::process::id();
    fs::write(&pid_file, pid.to_string())
        .context("Failed to write PID file")?;
    Ok(())
}

/// Remove PID file for daemon
pub fn remove_pid_file(daemon_name: &str) -> Result<()> {
    let pid_file = pid_file_path(daemon_name)?;
    if pid_file.exists() {
        fs::remove_file(&pid_file)
            .context("Failed to remove PID file")?;
    }
    Ok(())
}
