require("dotenv").config();
const express = require("express");
const db = require("./app/config/database");

const app = express();
app.use(express.json());

// Sync database (creates tables if they don't exist)
db.sequelize.sync({ alter: true });

// Your routes here
app.listen(8080, () => {
  console.log("Inventory API running on port 8080");
});
