const { Sequelize } = require("sequelize");
const fs = require("fs");
const path = require("path");

const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASSWORD,
  {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    dialect: "postgres",
  },
);

const db = {};

// Load all models
const modelsPath = path.join(__dirname, "../models");
fs.readdirSync(modelsPath).forEach((file) => {
  if (file.endsWith(".js")) {
    const model = require(path.join(modelsPath, file));
    const modelInstance = model(sequelize, Sequelize.DataTypes);
    db[modelInstance.name] = modelInstance;
  }
});

db.sequelize = sequelize;
db.Sequelize = Sequelize;

module.exports = db;
