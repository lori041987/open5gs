# Open5GS Unified Logging Improvements

**Date:** September 4, 2025  
**Version:** Open5GS 2.7.6  
**Contributors:** Claude Code Assistant

## Overview

This document describes the implementation of network function prefixes in Open5GS unified logging and methods for colored log viewing during runtime.

## Problem Statement

### Original Issue
When using unified logging mode in Open5GS, all network functions write to a single log file, but logs only showed the category (e.g., `[sbi]`) without indicating which network function generated the log entry.

**Before:**
```
09/04 09:31:09.752: [sbi] DEBUG: [204:POST] http://127.0.0.4:7777/nsmf-pdusession/v1/sm-contexts/25/modify
```

**Expected:**
```
09/04 09:31:09.752: [amf][sbi] DEBUG: [204:POST] http://127.0.0.4:7777/nsmf-pdusession/v1/sm-contexts/25/modify
```

## Solution Implementation

### Code Changes

#### 1. Network Function Name Storage (lib/core/ogs-log.h)
Added function declaration:
```c
void ogs_log_set_network_function(const char *name);
```

#### 2. Global Storage and Function Implementation (lib/core/ogs-log.c)
Added global variable:
```c
static const char *network_function_name = NULL;
```

Added function:
```c
void ogs_log_set_network_function(const char *name)
{
    network_function_name = name;
}
```

#### 3. Network Function Name Extraction (lib/app/ogs-init.c)
Added logic to extract network function name from program name during initialization:
```c
/* Extract network function name from argv[0] for unified logging */
if (argv && argv[0]) {
    const char *prog_name = strrchr(argv[0], '/');
    if (prog_name) {
        prog_name++; /* Skip the '/' */
    } else {
        prog_name = argv[0]; /* No path, use whole string */
    }
    
    /* Extract network function from names like "open5gs-amfd" -> "amf" */
    if (strncmp(prog_name, "open5gs-", 8) == 0) {
        const char *nf_name = prog_name + 8;
        /* Remove trailing 'd' if present (amfd -> amf) */
        static char nf_name_buf[32];
        strncpy(nf_name_buf, nf_name, sizeof(nf_name_buf) - 1);
        nf_name_buf[sizeof(nf_name_buf) - 1] = '\0';
        size_t len = strlen(nf_name_buf);
        if (len > 0 && nf_name_buf[len - 1] == 'd') {
            nf_name_buf[len - 1] = '\0';
        }
        ogs_log_set_network_function(nf_name_buf);
    }
}
```

#### 4. Log Domain Format Update (lib/core/ogs-log.c)
Modified `log_domain` function to include network function prefix:
```c
static char *log_domain(char *buf, char *last,
        const char *name, int use_color)
{
    if (network_function_name) {
        buf = ogs_slprintf(buf, last, "[%s%s%s][%s%s%s] ",
                use_color ? TA_FGC_YELLOW : "",
                network_function_name,
                use_color ? TA_NOR : "",
                use_color ? TA_FGC_YELLOW : "",
                name,
                use_color ? TA_NOR : "");
    } else {
        buf = ogs_slprintf(buf, last, "[%s%s%s] ",
                use_color ? TA_FGC_YELLOW : "",
                name,
                use_color ? TA_NOR : "");
    }

    return buf;
}
```

### Build Process

```bash
# Setup build
meson build --prefix=`pwd`/install

# Build project
ninja -C build

# Install binaries
ninja -C build install
```

### Results

**After Implementation:**
```
09/04 19:00:28.393: [nrf][sbi] INFO: NF Service [nnrf-nfm]
09/04 19:00:28.393: [nrf][sbi] INFO: NF Service [nnrf-disc]
09/04 19:01:32.172: [amf][sbi] DEBUG: ogs_sbi_client_add [http]
09/04 19:01:32.172: [amf][sbi] INFO: Setup NF EndPoint(addr) [127.0.0.200:7777]
```

## Colored Log Viewing

Since the implementation doesn't save ANSI color codes to log files, external tools are needed for colored real-time log viewing.

### Recommended Solutions

#### Option 1: Simple sed-based coloring (RECOMMENDED)
```bash
# Add to ~/.bashrc
colorlog() {
    local logfile="${1:-var/log/open5gs/open5gs-unified.log}"
    tail -f "$logfile" | sed \
        -e "s/.*FATAL.*/\x1b[1;31m&\x1b[0m/"   \
        -e "s/.*ERROR.*/\x1b[1;31m&\x1b[0m/"   \
        -e "s/.*WARNING.*/\x1b[1;33m&\x1b[0m/" \
        -e "s/.*INFO.*/\x1b[1;32m&\x1b[0m/"    \
        -e "s/.*DEBUG.*/\x1b[36m&\x1b[0m/"     \
        -e "s/.*TRACE.*/\x1b[35m&\x1b[0m/"
}
```

**Color Scheme:**
- **FATAL/ERROR**: Bright Red
- **WARNING**: Bright Yellow
- **INFO**: Bright Green  
- **DEBUG**: Cyan
- **TRACE**: Magenta

**Usage:**
```bash
source ~/.bashrc
colorlog                                    # Default log file
colorlog /path/to/specific/logfile.log     # Custom log file
```

#### Option 2: High-speed logging (minimal overhead)

If you don’t set GREP_COLOR explicitly:
grep --color defaults to 01;31 = bright red.

```bash
  # Minimal overhead version
  colorlog() {
      tail -f "${1:-var/log/open5gs/open5gs-unified.log}" | \
      GREP_COLOR='1;31' grep --color=always -E "(FATAL|ERROR)|$" | \
      GREP_COLOR='1;33' grep --color=always -E "WARNING|$" | \
      GREP_COLOR='1;32' grep --color=always -E "INFO|$"
  }

  # Or even simpler for speed:
  # Only highlight errors/warnings (fastest)
  colorlog() {
      tail -f "${1:-var/log/open5gs/open5gs-unified.log}" | \
      grep --color=always -E "(FATAL|ERROR|WARNING)|$"
  }


```

#### Option 3: Advanced with lnav
Create `~/.lnav/formats/open5gs.json`:
```json
{
    "open5gs_log": {
        "title": "Open5GS Log Format",
        "regex": {
            "basic": {
                "pattern": "^(?P<timestamp>\\d{2}/\\d{2} \\d{2}:\\d{2}:\\d{2}\\.\\d{3}): \\[(?P<nf>\\w+)\\]\\[(?P<category>\\w+)\\] (?P<level>\\w+): (?P<body>.*?)(?P<location> \\(.*\\))$"
            }
        },
        "level-field": "level",
        "level": {
            "fatal": "FATAL",
            "error": "ERROR", 
            "warning": "WARNING",
            "info": "INFO",
            "debug": "DEBUG",
            "trace": "TRACE"
        },
        "value": {
            "nf": {
                "kind": "string",
                "identifier": true
            },
            "category": {
                "kind": "string", 
                "identifier": true
            }
        }
    }
}
```

Usage: `lnav /path/to/log/file`

## Performance Impact

### On Open5GS
- **Impact**: Zero
- **Reason**: Changes only affect log formatting, not core functionality
- **Network Function Detection**: Happens once during initialization
- **Log Output**: Same performance as before

### On Log Viewing
- **sed-based coloring**: Minimal CPU overhead
- **grep-based coloring**: Slightly less overhead, highlights critical messages only
- **lnav**: Higher features but more resource usage
- **All external tools**: Zero impact on Open5GS processes

## Configuration

### Enable Unified Logging
In network function YAML configs (e.g., `amf.yaml`, `nrf.yaml`):
```yaml
logger:
  file:
    path: /path/to/separate/log  # Will be ignored when unified is enabled
  level: trace
  unified_logging: true
  unified_file: /path/to/open5gs-unified.log
```

### Environment Variable Override
```bash
export OPEN5GS_UNIFIED_LOGGING=1
export OPEN5GS_UNIFIED_FILE=/path/to/unified.log
```

## Testing

### Test Commands
```bash
# Test NRF
timeout 5 ./install/bin/open5gs-nrfd -c install/etc/open5gs/nrf.yaml

# Test AMF  
timeout 3 ./install/bin/open5gs-amfd -c install/etc/open5gs/amf.yaml

# View logs with colors
colorlog install/var/log/open5gs/open5gs-unified.log
```

### Expected Output Format
```
[timestamp]: [network_function][category] LEVEL: message (location)
```

Examples:
```
09/04 19:00:28.393: [nrf][app] INFO: Configuration: 'etc/open5gs/nrf.yaml'
09/04 19:01:32.172: [amf][sbi] DEBUG: ogs_sbi_client_add [http]
```

## Benefits

1. **Clear Network Function Identification**: Easy to distinguish logs from different network functions in unified mode
2. **No Performance Impact**: Changes don't affect Open5GS runtime performance
3. **Clean Log Files**: No ANSI color codes saved to disk
4. **Backward Compatibility**: Separate logging mode continues to work as before
5. **Automatic Detection**: No configuration required - works based on binary name
6. **Real-time Colored Viewing**: Multiple options for colored log viewing

## Files Modified

- `lib/core/ogs-log.h`: Added function declaration
- `lib/core/ogs-log.c`: Added global storage, function implementation, and format modification
- `lib/app/ogs-init.c`: Added network function name extraction logic

## Future Enhancements

1. **Network Function Color Coding**: Add different colors for different network functions
2. **Log Level Filtering**: Add options to filter by log levels in real-time
3. **Custom Format Options**: Allow customizable log format templates
4. **Performance Monitoring**: Add metrics for log output rates
5. **Log Rotation Integration**: Better integration with log rotation tools

## Troubleshooting

### Issue: Network function name not detected
**Cause**: Binary name doesn't follow `open5gs-*` pattern  
**Solution**: Ensure binary is named correctly (e.g., `open5gs-amfd`, `open5gs-nrfd`)

### Issue: Colors not appearing
**Cause**: Terminal doesn't support ANSI colors or `tail`/`sed` pipeline issue  
**Solution**: Check terminal capabilities, use `colorlog` function instead of raw commands

### Issue: Log file permissions
**Cause**: Log directory not writable  
**Solution**: Ensure proper permissions on log directory: `chmod 755 /var/log/open5gs/`

## References

- [Open5GS Documentation](https://open5gs.org/open5gs/docs/)
- [Meson Build System](https://mesonbuild.com/)
- [ANSI Color Codes](https://en.wikipedia.org/wiki/ANSI_escape_code)