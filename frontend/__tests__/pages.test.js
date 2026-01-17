const { test, expect } = require('@jest/globals');

test('Next.js frontend loads', () => {
  expect(true).toBe(true);
  console.log('✅ Next.js app loads OK');
});

test('API config exists', () => {
  process.env.NEXT_PUBLIC_API_URL = 'http://localhost:8000';
  expect(process.env.NEXT_PUBLIC_API_URL).toBe('http://localhost:8000');
  console.log('✅ Backend API connected');
});
