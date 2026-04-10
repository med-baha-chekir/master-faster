const axios = require('axios');

async function test() {
  console.log("=== Testing simulate-call-start ===");
  const startRes = await axios.post("http://localhost:3000/simulate-call-start", {
    scenario: "commander une pizza",
    userName: "Yassine",
    userAddress: "Rue de la Paix, Sousse",
    language: "fr"
  });
  console.log("Start Response:", startRes.data);

  const sessionId = startRes.data.sessionId;

  console.log("\n=== Testing simulate-caller-response ===");
  const respRes = await axios.post("http://localhost:3000/simulate-caller-response", {
    sessionId: sessionId,
    userChoice: "Livraison"
  });
  console.log("Response Cards / Reply:", respRes.data);
}

test().catch(console.error);
