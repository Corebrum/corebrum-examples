# Copyright (c) 2024 Corebrum Team. All Rights Reserved.
# Licensed under All Rights Reserved License.
# See LICENSE file for details.

import time
import json

def fibonacci_recursive(n):
    """Generate Fibonacci sequence using recursion (inefficient for large n)."""
    if n <= 0:
        return []
    elif n == 1:
        return [0]
    elif n == 2:
        return [0, 1]
    else:
        sequence = fibonacci_recursive(n - 1)
        sequence.append(sequence[-1] + sequence[-2])
        return sequence

def fibonacci_iterative(n):
    """Generate Fibonacci sequence using iteration (efficient for large n)."""
    if n <= 0:
        return []
    elif n == 1:
        return [0]
    elif n == 2:
        return [0, 1]
    
    sequence = [0, 1]
    for i in range(2, n):
        sequence.append(sequence[i - 1] + sequence[i - 2])
    return sequence

def fibonacci_generator(n):
    """Generate Fibonacci sequence using a generator (memory efficient)."""
    if n <= 0:
        return []
    
    a, b = 0, 1
    sequence = []
    for _ in range(n):
        sequence.append(a)
        a, b = b, a + b
    return sequence

# Get input terms from the inputs dictionary
terms = inputs.get("terms", 10)

# Validate input
if not isinstance(terms, (int, float)) or terms < 0:
    raise ValueError(f"Invalid input: {terms}. Must be a non-negative number.")

# Convert to integer if it's a float
terms = int(terms)

# Start timing
start_time = time.time()

# Generate Fibonacci sequence (using iterative method for best performance)
sequence = fibonacci_iterative(terms)

# Calculate computation time
computation_time_ms = int((time.time() - start_time) * 1000)

# Create result dictionary
result = {
    "sequence": sequence,
    "terms": len(sequence),
    "last_term": sequence[-1] if sequence else None,
    "computation_time_ms": computation_time_ms,
    "worker_id": worker_id,
    "method": "iterative",
    "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
    "sequence_sum": sum(sequence) if sequence else 0
}

# The result variable will be automatically printed as JSON by the Corebrum wrapper
