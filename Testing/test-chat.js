const admin = require('firebase-admin');
const fetch = require('node-fetch');

// Initialize admin SDK
const serviceAccount = require('./service-account-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'omni-ai-8d5d2'
});

async function testChat() {
  try {
    // Create a custom token for testing
    const uid = 'test-user-' + Date.now();
    const customToken = await admin.auth().createCustomToken(uid);
    
    console.log('Created custom token for user:', uid);
    console.log('Token:', customToken);
    
    // Now you would need to exchange this custom token for an ID token
    // This requires client-side Firebase Auth SDK
    console.log('\nTo test the chat function:');
    console.log('1. Use this custom token in your iOS app to sign in');
    console.log('2. Or use the Firebase Auth emulator for testing');
    
    // Test the function without auth (should fail with 401)
    console.log('\nTesting without auth token...');
    const response1 = await fetch('https://aichat-265kkl2lea-uc.a.run.app', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        message: 'Hello, how are you?',
        sessionId: 'test-session-123'
      })
    });
    
    const result1 = await response1.json();
    console.log('Response without auth:', result1);
    
  } catch (error) {
    console.error('Error:', error);
  }
}

testChat();