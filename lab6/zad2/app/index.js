// app/index.js
const express = require('express');
const mysql = require('mysql2');

const app = express();

const DB_HOST = process.env.DB_HOST || 'db';
const DB_USER = process.env.DB_USER || 'root';
const DB_PASSWORD = process.env.DB_PASSWORD || 'secret';
const DB_NAME = process.env.DB_NAME || 'testdb';
const PORT = process.env.PORT || 3000;

const db = mysql.createConnection({
    host: DB_HOST,
    user: DB_USER,
    password: DB_PASSWORD,
    database: DB_NAME
});

db.connect((err) => {
    if (err) {
        console.error("Couldn't connect to the DB:", err);
        process.exit(1);
    } else {
        console.log('Connected to the MySQL DB');
    }
});

app.get('/', (req, res) => {
    db.query('SELECT "Hello from DB" as message', (err, results) => {
        if (err) {
            return res.send('Query error:', err.message);
        }
        res.json(results);
    });
});

app.listen(PORT, () => {
    console.log(`App running on port ${PORT}`)
});
