/**
 * Basic usage examples for Corebrum JavaScript library.
 */

const corebrum = require('../index');

// Example 1: Simple function execution
async function example1() {
  console.log('Example 1: Simple function execution');
  
  const addNumbers = corebrum.run((a, b) => {
    return a + b;
  });
  
  const result = await addNumbers(5, 3);
  console.log(`Result: ${result}`);
  console.log();
}

// Example 2: Data processing (simulating async operation)
async function example2() {
  console.log('Example 2: Data processing');
  
  const processData = corebrum.run((data) => {
    // Simulate data processing
    const result = data.map(item => ({
      ...item,
      processed: true,
      timestamp: Date.now()
    }));
    return result;
  });
  
  const result = await processData([
    { id: 1, name: 'Item 1' },
    { id: 2, name: 'Item 2' }
  ]);
  console.log('Result:', JSON.stringify(result, null, 2));
  console.log();
}

// Example 3: Mathematical computations
async function example3() {
  console.log('Example 3: Mathematical computations');
  
  const calculate = corebrum.run((numbers) => {
    const sum = numbers.reduce((a, b) => a + b, 0);
    const avg = sum / numbers.length;
    const max = Math.max(...numbers);
    const min = Math.min(...numbers);
    return { sum, avg, max, min };
  });
  
  const result = await calculate([10, 20, 30, 40, 50]);
  console.log('Result:', JSON.stringify(result, null, 2));
  console.log();
}

// Example 4: Using execute() method
async function example4() {
  console.log('Example 4: Using execute() method');
  
  const result = await corebrum.execute(`
    const calculate = () => {
      return Math.sqrt(144);
    };
    const result = calculate(); // Assign to result variable
  `);
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
  } catch (error) {
    console.error('Error:', error.message);
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
};

