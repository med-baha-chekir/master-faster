// Quick smoke test for both backend endpoints
const http = require('http');

function post(path, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const options = {
      hostname: 'localhost',
      port: 3000,
      path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data),
      },
    };
    const req = http.request(options, (res) => {
      let buf = '';
      res.on('data', (chunk) => (buf += chunk));
      res.on('end', () => resolve({ status: res.statusCode, body: buf }));
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

(async () => {
  // Replace this placeholder with your actual phone number to test
  // Must include area code, e.g., '+216XXXXXXXX'
  const testPhoneNumber = 'YOUR_TEST_NUMBER_HERE'; 

  console.log('Testing /start-call ...');
  if (testPhoneNumber === 'YOUR_TEST_NUMBER_HERE') {
      console.log('⚠️ Please update testPhoneNumber in test.js with a valid number to test Vapi calling.');
      return;
  }

  const r1 = await post('/start-call', {
    phoneNumber: testPhoneNumber,
    scenario: 'taking a doctor appointment',
    userName: 'Alex',
    userAddress: '123 Main St, Tunis',
    isEmergency: false
  });
  
  console.log('Status:', r1.status);
  console.log('Response:', r1.body);

  if (r1.status === 200) {
      const responseBody = JSON.parse(r1.body);
      const callId = responseBody.callId;
      console.log(`\nCall successfully initiated! Call ID: ${callId}`);
      console.log('Run the following to check its status:');
      console.log(`curl http://localhost:3000/call-status/${callId}`);
  }
})();
