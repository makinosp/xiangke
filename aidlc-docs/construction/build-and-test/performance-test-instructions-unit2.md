# Performance Test Instructions — Unit 2: Game Foundation

## Overview

Performance tests for the game foundation layer. These tests verify that the
game meets the non-functional requirements for Web deployment.

---

## Performance Requirements (from NFR Requirements)

| Requirement           | Target  | Source  |
| --------------------- | ------- | ------- |
| Scene transition time | <500ms  | PF-1.1  |
| Audio latency         | <50ms   | PF-2.1  |
| Load time             | <10s    | NFR-1.2 |
| Frame rate            | ≥30 FPS | NFR-1.1 |

---

## Test Scenarios

### PT-1: Scene Transition Performance

**Purpose**: Verify scene transitions complete within 500ms.

**Test Steps**:

1. Run the project in Godot editor
2. Open the debugger's Monitors tab
3. Click "Start" → measure time to character select
4. Navigate through all scenes
5. Record transition times

**Expected**: All transitions complete within 500ms.

**Measurement**: Use Godot's debugger or browser dev tools.

---

### PT-2: Audio Latency

**Purpose**: Verify SFX playback latency is <50ms.

**Test Steps**:

1. Run the project
2. Click "Start" to initialize audio
3. Press UI buttons that trigger SFX
4. Measure time from button press to audible sound

**Expected**: Latency <50ms for responsive feedback.

**Note**: This is difficult to measure precisely without instrumentation. Rely
on Godot's built-in audio system for low latency.

---

### PT-3: Load Time

**Purpose**: Verify initial load completes within 10 seconds.

**Test Steps**:

1. Export HTML5 build
2. Open in browser
3. Open browser dev tools Network tab
4. Record time from page load to title screen visible

**Expected**: Load time <10 seconds.

**Measurement**: Browser dev tools or stopwatch.

---

### PT-4: Frame Rate

**Purpose**: Verify game maintains ≥30 FPS in Web export.

**Test Steps**:

1. Export HTML5 build
2. Open in browser
3. Open browser dev tools Performance tab
4. Run through all scenes
5. Record average FPS

**Expected**: Average FPS ≥30.

**Measurement**: Browser dev tools or Godot's debugger.

---

### PT-5: Memory Usage

**Purpose**: Verify memory usage is reasonable for Web.

**Test Steps**:

1. Run the project in browser
2. Open browser dev tools Memory tab
3. Navigate through all scenes
4. Record peak memory usage

**Expected**: Memory usage <100MB (typical for Godot HTML5).

---

## Running Tests

### Browser Testing

```bash
# Export HTML5 build
godot --headless --export-release "HTML5" build/web/index.html

# Serve locally (requires Python or similar)
cd build/web && python -m http.server 8000

# Open in browser
open http://localhost:8000
```

### Desktop Testing

Run in Godot editor with debugger enabled to monitor:

- FPS (Debugger → Monitors → FPS)
- Memory (Debugger → Monitors → Memory)
- Object count (Debugger → Monitors → Objects)

---

## Performance Optimization Tips

If tests fail:

1. **Scene transitions slow**: Reduce transition duration in `TransitionConfig`
2. **Audio latency high**: Preload audio streams, use `AudioStreamOGGVorbis`
3. **Load time high**: Minimize resource file sizes, use compressed textures
4. **FPS low**: Reduce draw calls, use simpler shaders, optimize UI layout

---

## Test Results

| Test ID | Description           | Target  | Status | Notes                    |
| ------- | --------------------- | ------- | ------ | ------------------------ |
| PT-1    | Scene transition time | <500ms  | Manual | Requires timing          |
| PT-2    | Audio latency         | <50ms   | Manual | Requires instrumentation |
| PT-3    | Load time             | <10s    | Manual | Browser testing          |
| PT-4    | Frame rate            | ≥30 FPS | Manual | Browser testing          |
| PT-5    | Memory usage          | <100MB  | Manual | Browser testing          |
