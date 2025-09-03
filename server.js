// Load environment variables from .env file
require('dotenv').config();

const express = require('express');
const { Pool } = require('pg'); // PostgreSQL client
const cors = require('cors'); // For Cross-Origin Resource Sharing

const app = express();
const port = process.env.PORT || 3000; // Server will run on port 3000 by default, or from .env

// Configure PostgreSQL connection pool
const pool = new Pool({
  user: process.env.DB_USER || 'myfin_user', // Your PostgreSQL username
  host: process.env.DB_HOST || 'localhost', // Your PostgreSQL host
  database: process.env.DB_NAME || 'myfin_db', // Your PostgreSQL database name
  password: process.env.DB_PASSWORD || 'myfin_password', // Your PostgreSQL password
  port: process.env.DB_PORT || 5432, // Default PostgreSQL port
});

// NEW: Add a custom parser for PostgreSQL numeric types to ensure they are parsed as floats
const types = require('pg').types;
types.setTypeParser(types.builtins.NUMERIC, parseFloat);
types.setTypeParser(types.builtins.INT2, parseInt);
types.setTypeParser(types.builtins.INT4, parseInt);
types.setTypeParser(types.builtins.INT8, parseInt);
types.setTypeParser(types.builtins.FLOAT4, parseFloat);
types.setTypeParser(types.builtins.FLOAT8, parseFloat);

// Middleware
app.use(cors()); // Enable CORS for all routes
app.use(express.json({ limit: '10mb' }));

// Test database connection
pool.connect((err, client, release) => {
  if (err) {
    return console.error('Error acquiring client', err.stack);
  }
  client.query('SELECT NOW()', (err, result) => {
    release();
    if (err) {
      return console.error('Error executing query', err.stack);
    }
    console.log('Successfully connected to PostgreSQL database:', result.rows[0].now);
  });
});

// API endpoint to save or update user profile data
app.post('/api/profile', async (req, res) => {
  const {
    firebase_uid,
    first_name,
    middle_name,
    last_name,
    date_of_birth,
    gender,
    pan_card,
    aadhaar_card,
    address_proof_type,
    address_proof_details,
    photograph_ipv,
    bank_account_number,
    ifsc_code,
    annual_salary_range,
    income_proof,
    credit_score,
    mobile_number,
    email_id,
    occupation,
    other_occupation,
    educational_qualification,
    add_nominee,
    nominee_name,
    nominee_mobile,
    nominee_email,
    agreed_to_terms,
    setupComplete
  } = req.body;

  // Basic validation
  if (!email_id || !first_name || !last_name || !pan_card || !aadhaar_card || !bank_account_number || !ifsc_code || !annual_salary_range || !credit_score || !mobile_number || !occupation || !educational_qualification) {
    return res.status(400).json({ error: 'Missing mandatory profile fields.' });
  }

  try {
    const result = await pool.query(
      `INSERT INTO user_profiles (
        firebase_uid, first_name, middle_name, last_name, date_of_birth, gender,
        pan_card, aadhaar_card, address_proof_type, address_proof_details, photograph_ipv,
        bank_account_number, ifsc_code, annual_salary_range, income_proof, credit_score,
        mobile_number, email_id, occupation, other_occupation, educational_qualification,
        add_nominee, nominee_name, nominee_mobile, nominee_email,
        agreed_to_terms, setup_complete
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27
      ) ON CONFLICT (email_id) DO UPDATE SET
        first_name = EXCLUDED.first_name,
        middle_name = EXCLUDED.middle_name,
        last_name = EXCLUDED.last_name,
        date_of_birth = EXCLUDED.date_of_birth,
        gender = EXCLUDED.gender,
        pan_card = EXCLUDED.pan_card,
        aadhaar_card = EXCLUDED.aadhaar_card,
        address_proof_type = EXCLUDED.address_proof_type,
        address_proof_details = EXCLUDED.address_proof_details,
        photograph_ipv = EXCLUDED.photograph_ipv,
        bank_account_number = EXCLUDED.bank_account_number,
        ifsc_code = EXCLUDED.ifsc_code,
        annual_salary_range = EXCLUDED.annual_salary_range,
        income_proof = EXCLUDED.income_proof,
        credit_score = EXCLUDED.credit_score,
        mobile_number = EXCLUDED.mobile_number,
        occupation = EXCLUDED.occupation,
        other_occupation = EXCLUDED.other_occupation,
        educational_qualification = EXCLUDED.educational_qualification,
        add_nominee = EXCLUDED.add_nominee,
        nominee_name = EXCLUDED.nominee_name,
        nominee_mobile = EXCLUDED.nominee_mobile,
        nominee_email = EXCLUDED.nominee_email,
        agreed_to_terms = EXCLUDED.agreed_to_terms,
        setup_complete = EXCLUDED.setup_complete,
        firebase_uid = EXCLUDED.firebase_uid,
        last_updated = CURRENT_TIMESTAMP
      RETURNING *;`,
      [
        firebase_uid, first_name, middle_name, last_name, date_of_birth, gender,
        pan_card, aadhaar_card, address_proof_type, address_proof_details, photograph_ipv,
        bank_account_number, ifsc_code, annual_salary_range, income_proof, credit_score,
        mobile_number, email_id, occupation, other_occupation, educational_qualification,
        add_nominee, nominee_name, nominee_mobile, nominee_email,
        agreed_to_terms, setupComplete
      ]
    );
    res.status(200).json({ message: 'Profile saved successfully!', profile: result.rows[0] });
  } catch (err) {
    console.error('Error saving profile:', err.message);
    res.status(500).json({ error: 'Failed to save profile.', details: err.message });
  }
});

// API endpoint to get user profile data
app.get('/api/profile/:email_id', async (req, res) => {
  const { email_id } = req.params;

  try {
    const result = await pool.query(
      'SELECT * FROM user_profiles WHERE email_id = $1;',
      [email_id]
    );

    if (result.rows.length > 0) {
      const profile = result.rows[0];
      const cleanedProfile = { ...profile };

      if (typeof cleanedProfile.monthly_income === 'string') cleanedProfile.monthly_income = parseFloat(cleanedProfile.monthly_income);
      if (typeof cleanedProfile.monthly_savings === 'string') cleanedProfile.monthly_savings = parseFloat(cleanedProfile.monthly_savings);
      if (typeof cleanedProfile.existing_savings_investments === 'string') cleanedProfile.existing_savings_investments = parseFloat(cleanedProfile.existing_savings_investments);
      if (typeof cleanedProfile.monthly_emis === 'string') cleanedProfile.monthly_emis = parseFloat(cleanedProfile.monthly_emis);
      if (typeof cleanedProfile.monthly_rent_mortgage === 'string') cleanedProfile.monthly_rent_mortgage = parseFloat(cleanedProfile.monthly_rent_mortgage);
      if (typeof cleanedProfile.age === 'string') cleanedProfile.age = parseInt(cleanedProfile.age);
      if (typeof cleanedProfile.dependents === 'string') cleanedProfile.dependents = parseInt(cleanedProfile.dependents);
      if (typeof cleanedProfile.credit_score === 'string') cleanedProfile.credit_score = parseInt(cleanedProfile.credit_score);

      res.status(200).json(cleanedProfile);
    } else {
      res.status(404).json({ error: 'Profile not found.' });
    }
  } catch (err) {
    console.error('Error fetching profile:', err.message);
    res.status(500).json({ error: 'Failed to fetch profile.', details: err.message });
  }
});

// API endpoint to save insurance calculation data
app.post('/api/insurance-calculation', async (req, res) => {
  const {
    firebase_uid,
    age,
    gender,
    annual_income,
    marital_status,
    num_children,
    spouse_annual_income,
    smoking_habit,
    health_conditions,
    exercise_frequency,
    existing_life_insurance,
    total_debts,
    total_savings_investments,
    calculated_insurance_amount,
    email_id // Added email_id here
  } = req.body;

  // Basic validation
  if (!email_id || !calculated_insurance_amount) { // Changed validation
    return res.status(400).json({ error: 'Email ID and calculated amount are required.' });
  }

  try {
    const result = await pool.query(
      `INSERT INTO insurance_calculations (
        firebase_uid, age, gender, annual_income, marital_status, num_children,
        spouse_annual_income, smoking_habit, health_conditions, exercise_frequency,
        existing_life_insurance, total_debts, total_savings_investments, calculated_insurance_amount, email_id
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15
      ) RETURNING *;`,
      [
        firebase_uid, age, gender, annual_income, marital_status, num_children,
        spouse_annual_income, smoking_habit, health_conditions, exercise_frequency,
        existing_life_insurance, total_debts, total_savings_investments, calculated_insurance_amount, email_id
      ]
    );
    res.status(201).json({ message: 'Insurance calculation saved successfully!', calculation: result.rows[0] });
  } catch (err) {
    console.error('Error saving insurance calculation:', err.message);
    res.status(500).json({ error: 'Failed to save insurance calculation.', details: err.message });
  }
});

// NEW API endpoint to get a user's insurance calculations
app.get('/api/insurance-calculations/:email_id', async (req, res) => {
  const { email_id } = req.params;

  try {
    const result = await pool.query(
      'SELECT * FROM insurance_calculations WHERE email_id = $1 ORDER BY calculated_at DESC;',
      [email_id]
    );

    const calculations = result.rows.map(row => {
      const cleanedRow = { ...row };
      if (typeof cleanedRow.annual_income === 'string') cleanedRow.annual_income = parseFloat(cleanedRow.annual_income);
      if (typeof cleanedRow.spouse_annual_income === 'string') cleanedRow.spouse_annual_income = parseFloat(cleanedRow.spouse_annual_income);
      if (typeof cleanedRow.existing_life_insurance === 'string') cleanedRow.existing_life_insurance = parseFloat(cleanedRow.existing_life_insurance);
      if (typeof cleanedRow.total_debts === 'string') cleanedRow.total_debts = parseFloat(cleanedRow.total_debts);
      if (typeof cleanedRow.total_savings_investments === 'string') cleanedRow.total_savings_investments = parseFloat(cleanedRow.total_savings_investments);
      if (typeof cleanedRow.calculated_insurance_amount === 'string') cleanedRow.calculated_insurance_amount = parseFloat(cleanedRow.calculated_insurance_amount);
      if (typeof cleanedRow.age === 'string') cleanedRow.age = parseInt(cleanedRow.age);
      if (typeof cleanedRow.num_children === 'string') cleanedRow.num_children = parseInt(cleanedRow.num_children);
      return cleanedRow;
    });

    res.status(200).json(calculations);
  } catch (err) {
    console.error('Error fetching insurance calculations:', err.message);
    res.status(500).json({ error: 'Failed to fetch insurance calculations.', details: err.message });
  }
});

// Start the server
app.listen(port, () => {
  console.log(`Backend server running on http://localhost:${port}`);
});