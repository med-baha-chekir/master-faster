const axios = require('axios');
const fs = require('fs');

async function run() {
  try {
    const response = await axios.post('http://localhost:3000/speak', {
      text: 'Bonjour, je suis Sarra votre assistante.',
      language: 'fr'
    }, { responseType: 'stream' });

    response.data.pipe(fs.createWriteStream('test_audio.mp3'))
      .on('finish', () => {
        const stats = fs.statSync('test_audio.mp3');
        console.log('Saved to test_audio.mp3, size:', stats.size, 'bytes');
      });
  } catch (err) {
    console.error('Failed to get TTS:', err.message);
  }
}
run();
