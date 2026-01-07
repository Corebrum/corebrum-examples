/**
 * Advanced usage examples for Corebrum JavaScript library.
 */

const corebrum = require('../index');

// Example 1: Functions with default arguments
async function example1() {
  console.log('Example 1: Functions with default arguments');
  
  const processWithDefaults = corebrum.run((data, multiplier = 2, offset = 0) => {
    return data.map(x => x * multiplier + offset);
  });
  
  const result1 = await processWithDefaults([1, 2, 3]);
  const result2 = await processWithDefaults([1, 2, 3], 3, 10);
  console.log('Result 1:', result1);
  console.log('Result 2:', result2);
  console.log();
}

// Example 2: Error handling
async function example2() {
  console.log('Example 2: Error handling');
  
  const divide = corebrum.run((a, b) => {
    if (b === 0) {
      throw new Error('Division by zero');
    }
    return a / b;
  });
  
  try {
    const result = await divide(10, 2);
    console.log(`Result: ${result}`);
  } catch (error) {
    console.error('Error caught:', error.message);
  }
  
  try {
    await divide(10, 0);
  } catch (error) {
    console.log('Expected error caught:', error.message);
  }
  console.log();
}

// Example 3: Custom timeout
async function example3() {
  console.log('Example 3: Custom timeout');
  
  const longRunning = corebrum.run(() => {
    // Simulate some work
    let sum = 0;
    for (let i = 0; i < 1000000; i++) {
      sum += i;
    }
    return sum;
  }, { timeout: 60 }); // 60 second timeout
  
  const result = await longRunning();
  console.log(`Result: ${result}`);
  console.log();
}

// Example 4: Using identity context
async function example4() {
  console.log('Example 4: Using identity context');
  
  const processWithIdentity = corebrum.run((data) => {
    return {
      data: data,
      processed: true,
      timestamp: Date.now()
    };
  }, { identityId: 'test-identity-123' });
  
  const result = await processWithIdentity({ key: 'value' });
  console.log('Result:', JSON.stringify(result, null, 2));
  console.log();
}

// Example 5: Execute with inputs
async function example5() {
  console.log('Example 5: Execute with inputs');
  
  const result = await corebrum.execute(
    `
    const process = (x, y) => {
      return x * y + 10;
    };
    const result = process(x, y); // Assign to result variable
    `,
    { x: 5, y: 3 }
  );
  console.log(`Result: ${result}`);
  console.log();
}

// Run all examples
async function main() {
  try {
    await example1();
    await example2();
    await example3();
    await example4();
    await example5();
  } catch (error) {
    console.error('Error:', error.message);
    if (error.stack) {
      console.error('Stack:', error.stack);
    }
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = {
  example1,
  example2,
  example3,
  example4,
  example5,
};

