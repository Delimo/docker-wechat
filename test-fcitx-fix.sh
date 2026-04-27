#!/bin/bash
echo "Testing script syntax..."
bash -n startapp-enhanced.sh && echo "✓ startapp-enhanced.sh syntax OK"
if grep -q "luna_pinyin_simp" Dockerfile; then
    echo "✓ Rime simplified Chinese config found in Dockerfile"
fi
