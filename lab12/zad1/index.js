const express = require('express')
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

app.get('/', (req, res) => {
    res.json({ message: 'Hello World!' });
});

app.get('/health', (req, res) => {
    res.json({ status: 'OK' });
});

app.get('/items', (req, res) => {
    res.json([
        { id: 1, name: 'Item A' },
        { id: 2, name: 'Item B' }
    ]);
});

app.post('/echo', (req, res) => {
    res.json({ you_sent: req.body });
});

app.listen(port, () => {
    console.log(`API running on http://0.0.0.0:${port}`)
});
