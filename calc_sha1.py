#!/usr/bin/env python3
import hashlib

# Calcular SHA-1 para diferentes strings
test_strings = ['a', 'b', 'c', '0', '1']

for s in test_strings:
    sha1_hash = hashlib.sha1(s.encode()).hexdigest()
    print(f"SHA-1('{s}') = {sha1_hash}")
