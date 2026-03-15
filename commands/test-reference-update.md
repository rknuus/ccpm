---
allowed-tools: Bash, Read, Write
---

# Test Reference Update

Test the task reference update logic used in epic-decompose.

## Usage
```
/ccpm:test-reference-update
```

## Instructions

### 1. Create Test Files

Create test task files with references:
```bash
mkdir -p /tmp/test-refs

# Create task 001
cat > /tmp/test-refs/001.md << 'EOF'
---
name: Task One
status: open
depends_on: []
parallel: true
conflicts_with: [002, 003]
---
# Task One
This is task 001.
EOF

# Create task 002
cat > /tmp/test-refs/002.md << 'EOF'
---
name: Task Two
status: open
depends_on: [001]
parallel: false
conflicts_with: [003]
---
# Task Two
This is task 002, depends on 001.
EOF

# Create task 003
cat > /tmp/test-refs/003.md << 'EOF'
---
name: Task Three
status: open
depends_on: [001, 002]
parallel: false
conflicts_with: []
---
# Task Three
This is task 003, depends on 001 and 002.
EOF
```

### 2. Create Mappings

Create the mapping file:
```bash
cat > /tmp/task-mapping.txt << 'EOF'
001.md:42
002.md:43
003.md:44
EOF
```

Then build the ID mapping: for each line in `/tmp/task-mapping.txt`, extract the number before `.md` as the old ID and the number after `:` as the new ID. Write these mappings to `/tmp/id-mapping.txt` in `old:new` format (e.g., `001:42`).

### 3. Update References

For each entry in `/tmp/task-mapping.txt`:
1. Use the Read tool to read the task file from `/tmp/test-refs/{task_file}`
2. In the content, replace all references to old IDs with new IDs using the mapping from `/tmp/id-mapping.txt`
3. Use the Write tool to write the updated content to `/tmp/test-refs/{new_number}.md`

### 4. Verify Results

Check that references were updated correctly:
```bash
echo "=== Final Results ==="
for file in 42.md 43.md 44.md; do
  echo "File: /tmp/test-refs/$file"
  grep -E "name:|depends_on:|conflicts_with:" "/tmp/test-refs/$file"
  echo ""
done
```

Expected output:
- 42.md should have conflicts_with: [43, 44]
- 43.md should have depends_on: [42] and conflicts_with: [44]
- 44.md should have depends_on: [42, 43]

### 5. Cleanup Padded Test

```bash
rm -rf /tmp/test-refs
rm -f /tmp/task-mapping.txt /tmp/id-mapping.txt
echo "✅ Padded ID test complete and cleaned up"
```

### 6. Test Non-Padded IDs

Create test files with non-padded IDs (as used by the global counter):
```bash
mkdir -p /tmp/test-refs-v2

# Create task 1
cat > /tmp/test-refs-v2/1.md << 'EOF'
---
name: Task One
status: open
depends_on: []
parallel: true
conflicts_with: [2, 3]
---
# Task One
This is task 1.
EOF

# Create task 2
cat > /tmp/test-refs-v2/2.md << 'EOF'
---
name: Task Two
status: open
depends_on: [1]
parallel: false
conflicts_with: [3]
---
# Task Two
This is task 2, depends on 1.
EOF

# Create task 3
cat > /tmp/test-refs-v2/3.md << 'EOF'
---
name: Task Three
status: open
depends_on: [1, 2]
parallel: false
conflicts_with: []
---
# Task Three
This is task 3, depends on 1 and 2.
EOF
```

### 7. Create Non-Padded Mappings

Create the mapping file:
```bash
cat > /tmp/task-mapping.txt << 'EOF'
1.md:101
2.md:102
3.md:103
EOF
```

Then build the ID mapping: for each line in `/tmp/task-mapping.txt`, extract the number before `.md` as the old ID and the number after `:` as the new ID. Write these mappings to `/tmp/id-mapping.txt` in `old:new` format (e.g., `1:101`).

### 8. Update Non-Padded References

For each entry in `/tmp/task-mapping.txt`:
1. Use the Read tool to read the task file from `/tmp/test-refs-v2/{task_file}`
2. In the content, replace all references to old IDs with new IDs using the mapping from `/tmp/id-mapping.txt`
3. Use the Write tool to write the updated content to `/tmp/test-refs-v2/{new_number}.md`

### 9. Verify Non-Padded Results

```bash
echo "=== Non-Padded ID Results ==="
for file in 101.md 102.md 103.md; do
  echo "File: /tmp/test-refs-v2/$file"
  grep -E "name:|depends_on:|conflicts_with:" "/tmp/test-refs-v2/$file"
  echo ""
done
```

Expected output:
- 101.md should have conflicts_with: [102, 103]
- 102.md should have depends_on: [101] and conflicts_with: [103]
- 103.md should have depends_on: [101, 102]

### 10. Final Cleanup

```bash
rm -rf /tmp/test-refs-v2
rm -f /tmp/task-mapping.txt /tmp/id-mapping.txt
echo "✅ All tests complete and cleaned up"
```
