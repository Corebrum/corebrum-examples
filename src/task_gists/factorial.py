# Copyright (c) 2024 Corebrum Team. All Rights Reserved.
# Licensed under All Rights Reserved License.
# See LICENSE file for details.

import time
import json

def factorial(n):
    """Compute factorial of n recursively."""
    if n < 0:
        raise ValueError("Factorial is not defined for negative numbers")
    if n == 0 or n == 1:
        return 1
    return n * factorial(n - 1)

def factorial_iterative(n):
    """Compute factorial of n iteratively (more efficient for large numbers)."""
    if n < 0:
        raise ValueError("Factorial is not defined for negative numbers")
    result = 1
    for i in range(1, n + 1):
        result *= i
    return result

# Get input number from the inputs dictionary
number = inputs.get("number", 10)

# Validate input
if not isinstance(number, (int, float)) or number < 0:
    raise ValueError(f"Invalid input: {number}. Must be a non-negative number.")

# Convert to integer if it's a float
number = int(number)

# Start timing
start_time = time.time()

# Compute factorial (using iterative method for better performance)
factorial_result = factorial_iterative(number)

# Calculate computation time
computation_time_ms = int((time.time() - start_time) * 1000)

# Create result dictionary
result = {
    "factorial": factorial_result,
    "input_number": number,
    "computation_time_ms": computation_time_ms,
    "worker_id": worker_id,
    "method": "iterative",
    "timestamp": time.strftime("%Y-%m-%d %H:%M:%S")
}

# The result variable will be automatically printed as JSON by the Corebrum wrapper
