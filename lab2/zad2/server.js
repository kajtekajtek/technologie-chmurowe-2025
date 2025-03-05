const express = require('express');
const app = express();
const port = 8080;

app.get('/', (req, res) => {
  const currentDate = new Date();
  res.status(200).send(`${currentDate}`);
});

app.listen(port, () => {
  console.log(`Server running at: ${port}/`);
});
