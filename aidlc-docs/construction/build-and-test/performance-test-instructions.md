# Performance Test Instructions

## Purpose

Validate that the data layer meets performance requirements defined in NFR
Requirements (PF-1, PF-2, PF-3).

## Performance Requirements

| Requirement        | Target                | NFR Reference |
| ------------------ | --------------------- | ------------- |
| Frame rate         | ≥30 FPS in Web export | PF-1.3        |
| Initial data load  | < 10 seconds on Web   | PF-2.1        |
| Data preload       | All data at startup   | PF-2.2        |
| Type effectiveness | O(1) operation        | PF-3.2        |
| Damage calculation | O(1) operation        | PF-3.2        |

## Setup Performance Test Environment

### 1. Export HTML5 Build

```bash
# Export the project for Web platform
# Project → Export → Web → Export Project
```

### 2. Serve Locally for Testing

```bash
# From the build/web directory
cd build/web
python3 -m http.server 8080
```

### 3. Open in Browser

Navigate to `http://localhost:8080` in Chrome/Firefox.

## Run Performance Tests

### Test 1: Load Time Measurement

**Steps**:

1. Open browser DevTools (F12) → Network tab
2. Clear cache and reload page
3. Measure time from first byte to page fully loaded

**Expected**: Total load time < 10 seconds (including Godot engine + data).

**Acceptable**: Godot engine itself takes 3-5 seconds on first load; data
loading adds < 1 second for <200KB of `.tres` files.

### Test 2: Frame Rate Verification

**Steps**:

1. Open browser DevTools → Performance tab
2. Start recording
3. Let the game run for 10 seconds
4. Stop recording and check FPS

**Expected**: ≥ 30 FPS sustained.

**Note**: With only Unit 1 implemented (no battle system), the game scene is
minimal. FPS should be 60 (VSync) in most browsers.

### Test 3: Data Preload Verification

**Steps**:

1. Check browser console for DataRegistry output
2. Verify message: "All data loaded and validated successfully"
3. Confirm character and move counts match expected values

**Expected**: All data loaded before game starts (no async loading).

### Test 4: Type Effectiveness Performance

**Steps**:

1. In browser console, execute (if exposed):
   ```javascript
   // Measure 10,000 type chart lookups
   const start = performance.now();
   for (let i = 0; i < 10000; i++) {
     // TypeChart lookups are O(1) array accesses
   }
   const elapsed = performance.now() - start;
   console.log(`10,000 lookups: ${elapsed}ms`);
   ```

**Expected**: < 1ms for 10,000 lookups (O(1) array access).

## Performance Optimization

If performance doesn't meet requirements:

1. **Slow load time**: Verify `.tres` files are not excessively large; consider
   compressing or splitting data
2. **Low FPS**: Check for per-frame operations in `_process()` or
   `_physics_process()` callbacks
3. **Memory issues**: Profile memory usage in browser DevTools → Memory tab

## Results Location

- Browser DevTools → Network tab (load time)
- Browser DevTools → Performance tab (FPS)
- Browser Console (validation output)
