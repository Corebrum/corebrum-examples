/**
 * Factorial Demo - Demonstrates using Corebrum JavaScript library to compute factorials.
 *
 * This demo shows the difference between corebrum.run() and corebrum.execute():
 *
 * - corebrum.run(): Best for existing functions. Wraps a function so it executes on Corebrum.
 *   Use when you have a function defined and want to execute it remotely.
 *
 * - corebrum.execute(): Best for raw code strings. Executes arbitrary JavaScript code.
 *   Use when you have code as a string or want to execute code dynamically.
 */

const corebrum = require('../index');

/**
 * Method 1: Using corebrum.run() decorator
 * 
 * This is the recommended approach when you have a function already defined.
 * The decorator wraps your function so it executes on Corebrum instead of locally.
 */
async function factorialRun() {
  console.log('Method 1: Using corebrum.run() decorator');
  
  // Define the factorial function
  const factorial = corebrum.run((n) => {
    if (n <= 1) return 1;
    let result = 1;
    for (let i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  });
  
  // Call it normally - it executes on Corebrum
  const numbers = [0, 1, 5, 8, 10];
  for (const num of numbers) {
    try {
      const result = await factorial(num);
      console.log(`Factorial(${num.toString().padStart(2)}) = ${result}`);
    } catch (error) {
      console.error(`Factorial(${num.toString().padStart(2)}) = Error: ${error.message}`);
    }
  }
  console.log();
}

/**
 * Method 2: Using corebrum.execute() method
 * 
 * This approach is useful when you have code as a string or want to execute
 * code dynamically. You must assign the result to a variable (e.g., 'result')
 * for the wrapper to capture it.
 */
async function factorialExecute() {
  console.log('Method 2: Using corebrum.execute() method');
  
  const numbers = [0, 1, 5, 8, 10];
  for (const num of numbers) {
    try {
      const result = await corebrum.execute(
        `
        function factorial(n) {
          if (n <= 1) return 1;
          let result = 1;
          for (let i = 2; i <= n; i++) {
            result *= i;
          }
          return result;
        }
        const result = factorial(number); // Assign to result variable
        `,
        { number: num },
        { name: 'factorial_task' }
      );
      console.log(`Factorial(${num.toString().padStart(2)}) = ${result}`);
    } catch (error) {
      console.error(`Factorial(${num.toString().padStart(2)}) = Error: ${error.message}`);
    }
  }
  console.log();
}

/**
 * Method 3: Recursive factorial implementation
 * 
 * Demonstrates a more complex recursive implementation.
 */
async function factorialRecursive() {
  console.log('Method 3: Recursive factorial implementation');
  
  const factorial = corebrum.run((n) => {
    function fact(n) {
      if (n <= 1) return 1;
      return n * fact(n - 1);
    }
    return fact(n);
  });
  
  const numbers = [0, 1, 5, 8, 10];
  for (const num of numbers) {
    try {
      const result = await factorial(num);
      console.log(`Factorial(${num.toString().padStart(2)}) = ${result}`);
    } catch (error) {
      console.error(`Factorial(${num.toString().padStart(2)}) = Error: ${error.message}`);
    }
  }
  console.log();
}

/**
 * Method 4: Parallel execution of multiple factorials
 * 
 * Demonstrates executing multiple tasks in parallel.
 */
async function factorialParallel() {
  console.log('Method 4: Parallel execution of multiple factorials');
  
  const factorial = corebrum.run((n) => {
    if (n <= 1) return 1;
    let result = 1;
    for (let i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  });
  
  const numbers = [5, 8, 10, 12, 15];
  console.log('Submitting multiple factorial calculations in parallel...');
  
  try {
    // Execute all factorials in parallel
    const promises = numbers.map(num => factorial(num));
    const results = await Promise.all(promises);
    
    for (let i = 0; i < numbers.length; i++) {
      console.log(`Factorial(${numbers[i].toString().padStart(2)}) = ${results[i]}`);
    }
  } catch (error) {
    console.error(`Error: ${error.message}`);
  }
  console.log();
}

// Main function
async function main() {
  console.log('='.repeat(60));
  console.log('Corebrum Factorial Demo');
  console.log('='.repeat(60));
  console.log();
  
  try {
    await factorialRun();
    await factorialExecute();
    await factorialRecursive();
    await factorialParallel();
    
    console.log('='.repeat(60));
    console.log('All methods completed successfully!');
    console.log('='.repeat(60));
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
  factorialRun,
  factorialExecute,
  factorialRecursive,
  factorialParallel,
};

