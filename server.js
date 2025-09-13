// ---------------------------------------------
// 1. Load correct environment variables file
// ---------------------------------------------
const path = require('path');
const dotenv = require('dotenv');

// If NODE_ENV is not set, default to 'development'
process.env.NODE_ENV = process.env.NODE_ENV || 'development';

// Load the right env file based on environment
if (process.env.NODE_ENV === 'production') {
  dotenv.config({ path: path.resolve(__dirname, 'cloud.env') });
  console.log('✅ Loaded cloud.env for production');
} else {
  dotenv.config({ path: path.resolve(__dirname, 'local.env') });
  console.log('✅ Loaded local.env for development');
}

const express = require('express');
const { Pool, types } = require('pg');
const cors = require('cors');
const axios = require('axios'); // Add axios for making HTTP requests

const app = express();
const port = process.env.PORT || 3000;
const isProduction = process.env.NODE_ENV === 'production';

// ---------------------------------------------
// 2. Configure PostgreSQL connection
// ---------------------------------------------
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
  ssl: false,
});


// ---------------------------------------------
// 3. Custom PostgreSQL type parsers
// ---------------------------------------------
types.setTypeParser(types.builtins.NUMERIC, parseFloat);
types.setTypeParser(types.builtins.INT2, parseInt);
types.setTypeParser(types.builtins.INT4, parseInt);
types.setTypeParser(types.builtins.INT8, parseInt);
types.setTypeParser(types.builtins.FLOAT4, parseFloat);
types.setTypeParser(types.builtins.FLOAT8, parseFloat);

// ---------------------------------------------
// 4. Middleware
// ---------------------------------------------
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// ---------------------------------------------
// 5. Auto-create tables if they don't exist
// ---------------------------------------------
async function createTablesIfNotExist() {
  const createUserProfiles = `
    CREATE TABLE IF NOT EXISTS user_profiles (
      firebase_uid TEXT,
      first_name TEXT NOT NULL,
      middle_name TEXT,
      last_name TEXT NOT NULL,
      date_of_birth DATE,
      gender TEXT,
      pan_card TEXT UNIQUE NOT NULL,
      aadhaar_card TEXT UNIQUE NOT NULL,
      address_proof_type TEXT,
      address_proof_details TEXT,
      photograph_ipv TEXT,
      bank_account_number TEXT NOT NULL,
      ifsc_code TEXT NOT NULL,
      annual_salary_range TEXT NOT NULL,
      income_proof TEXT,
      credit_score INTEGER NOT NULL,
      mobile_number TEXT NOT NULL,
      email_id TEXT PRIMARY KEY,
      occupation TEXT NOT NULL,
      other_occupation TEXT,
      educational_qualification TEXT NOT NULL,
      add_nominee BOOLEAN,
      nominee_name TEXT,
      nominee_mobile TEXT,
      nominee_email TEXT,
      agreed_to_terms BOOLEAN,
      setup_complete BOOLEAN,
      last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `;

  const createInsuranceCalculations = `
    CREATE TABLE IF NOT EXISTS insurance_calculations (
      id SERIAL PRIMARY KEY,
      firebase_uid TEXT,
      age INTEGER,
      gender TEXT,
      annual_income NUMERIC,
      marital_status TEXT,
      num_children INTEGER,
      spouse_annual_income NUMERIC,
      smoking_habit TEXT,
      health_conditions TEXT,
      exercise_frequency TEXT,
      existing_life_insurance NUMERIC,
      total_debts NUMERIC,
      total_savings_investments NUMERIC,
      calculated_insurance_amount NUMERIC NOT NULL,
      email_id TEXT REFERENCES user_profiles(email_id),
      calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `;

  try {
    await pool.query(createUserProfiles);
    await pool.query(createInsuranceCalculations);
    console.log("✅ Tables verified/created successfully");
  } catch (err) {
    console.error("❌ Error creating tables:", err.message);
  }
}

// ---------------------------------------------
// 6. Test DB connection and init tables
// ---------------------------------------------
pool.connect((err, client, release) => {
  if (err) {
    return console.error('❌ Error acquiring client', err.stack);
  }
  client.query('SELECT NOW()', async (err, result) => {
    release();
    if (err) {
      return console.error('❌ Error executing query', err.stack);
    }
    console.log('✅ Connected to PostgreSQL at', result.rows[0].now);
    await createTablesIfNotExist(); // Ensure tables exist
  });
});

// ---------------------------------------------
// 7. API Endpoints
// ---------------------------------------------

// Save/Update user profile
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

  if (!email_id || !first_name || !last_name || !pan_card || !aadhaar_card ||
      !bank_account_number || !ifsc_code || !annual_salary_range ||
      !credit_score || !mobile_number || !occupation || !educational_qualification) {
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
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16,
        $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27
      )
      ON CONFLICT (email_id) DO UPDATE SET
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
    console.error('❌ Error saving profile:', err.message);
    res.status(500).json({ error: 'Failed to save profile.', details: err.message });
  }
});


// Get user profile by firebase_uid
app.get('/api/profile/:firebase_uid', async (req, res) => {
  const { firebase_uid } = req.params;
  try {
    const result = await pool.query(
      'SELECT first_name, last_name, date_of_birth, mobile_number, email_id,  setup_complete FROM user_profiles WHERE firebase_uid = $1;',
      [firebase_uid]
    );

    if (result.rows.length > 0) {
      res.status(200).json(result.rows[0]);
    } else {
      res.status(404).json({ error: 'Profile not found.' });
    }
  } catch (err) {
    console.error('❌ Error fetching profile:', err.message);
    res.status(500).json({ error: 'Failed to fetch profile.', details: err.message });
  }
});
//optional: Get user profile by email_id
app.get('/api/profile/email/:email_id', async (req, res) => {
  const { email_id } = req.params;
  try {
    const result = await pool.query(
      'SELECT * FROM user_profiles WHERE email_id = $1;',
      [email_id]
    );

    if (result.rows.length > 0) {
      res.status(200).json(result.rows[0]);
    } else {
      res.status(404).json({ error: 'Profile not found.' });
    }
  } catch (err) {
    console.error('❌ Error fetching profile by email:', err.message);
    res.status(500).json({ error: 'Failed to fetch profile by email.', details: err.message });
  }
});


// Save insurance calculation
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
    email_id
  } = req.body;

  if (!email_id || !calculated_insurance_amount) {
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
        existing_life_insurance, total_debts, total_savings_investments,
        calculated_insurance_amount, email_id
      ]
    );
    res.status(201).json({ message: 'Insurance calculation saved successfully!', calculation: result.rows[0] });
  } catch (err) {
    console.error('❌ Error saving insurance calculation:', err.message);
    res.status(500).json({ error: 'Failed to save insurance calculation.', details: err.message });
  }
});

// Get insurance calculations
app.get('/api/insurance-calculations/:email_id', async (req, res) => {
  const { email_id } = req.params;
  try {
    const result = await pool.query(
      'SELECT * FROM insurance_calculations WHERE email_id = $1 ORDER BY calculated_at DESC;',
      [email_id]
    );
    res.status(200).json(result.rows);
  } catch (err) {
    console.error('❌ Error fetching insurance calculations:', err.message);
    res.status(500).json({ error: 'Failed to fetch insurance calculations.', details: err.message });
  }
});

// Test DB connection endpoint
app.get('/test-db', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW() AS current_time');
    res.json({
      status: 'success',
      current_time: result.rows[0].current_time
    });
  } catch (err) {
    console.error('Database test failed:', err);
    res.status(500).json({
      status: 'error',
      message: 'Database connection failed',
      error: err.message
    });
  }
});

// ---------------------------------------------
// 9. Aadhaar KYC (OTP Generation + Verification)
// ---------------------------------------------
app.post("/api/kyc/generate-aadhaar-otp", async (req, res) => {
  const { aadhaar_number } = req.body;

  if (!aadhaar_number || aadhaar_number.length !== 12) {
    return res.status(400).json({ error: "Invalid Aadhaar number." });
  }

  try {
    const response = await axios.post(
      "https://api.sandbox.co.in/kyc/aadhaar/okyc/otp",
      {
        "@entity": "in.co.sandbox.kyc.aadhaar.okyc.otp.request",
        aadhaar_number,
        consent: "y",
        reason: "KYC Verification",
      },
      {
        headers: {
          authorization: process.env.SANDBOX_AUTH_TOKEN,
          "x-api-key": process.env.SANDBOX_API_KEY,
          "x-api-version": "2.0",
          "Content-Type": "application/json",
        },
      }
    );

    res.status(200).json(response.data);
  } catch (err) {
    console.error("❌ Error generating OTP:", err.response?.data || err.message);
    res.status(500).json({
      error: err.response?.data?.message || "Failed to send OTP",
      details: err.response?.data || err.message,
    });
  }
});

app.post("/api/kyc/verify-aadhaar-otp", async (req, res) => {
  const { reference_id, otp } = req.body;

  if (!reference_id || !otp) {
    return res.status(400).json({ error: "Missing reference_id or OTP." });
  }

  try {
    const response = await axios.post(
      "https://api.sandbox.co.in/kyc/aadhaar/okyc/otp/verify",
      {
        "@entity": "in.co.sandbox.kyc.aadhaar.okyc.request",
        reference_id,
        otp,
      },
      {
        headers: {
          authorization: process.env.SANDBOX_AUTH_TOKEN,
          "x-api-key": process.env.SANDBOX_API_KEY,
          "x-api-version": "2.0",
          "Content-Type": "application/json",
        },
      }
    );

    res.status(200).json({
      status: "Success",
      message: "OTP verified successfully",
    });
  } catch (err) {
    console.error("❌ Error verifying OTP:", err.response?.data || err.message);
    res.status(500).json({
      error: err.response?.data?.message || "Failed to verify OTP",
      details: err.response?.data || err.message,
    });
  }
});

// ---------------------------------------------
// 10. PAN KYC (Verification)
// ---------------------------------------------
app.post("/api/kyc/verify-pan", async (req, res) => {
  const { pan, name_as_per_pan, date_of_birth } = req.body;

  if (!pan || !name_as_per_pan || !date_of_birth) {
    return res.status(400).json({ error: "Missing mandatory fields for PAN verification." });
  }

  try {
    const response = await axios.post(
      "https://api.sandbox.co.in/kyc/pan/verify",
      {
        "@entity": "in.co.sandbox.kyc.pan_verification.request",
        pan: pan,
        name_as_per_pan: name_as_per_pan,
        date_of_birth: date_of_birth,
        consent: "y",
        reason: "d",
      },
      {
        headers: {
          authorization: process.env.SANDBOX_AUTH_TOKEN,
          "x-api-key": process.env.SANDBOX_API_KEY,
          "x-api-version": "2.0",
          "Content-Type": "application/json",
        },
      }
    );

    res.status(200).json(response.data);
  } catch (err) {
    console.error("❌ Error verifying PAN:", err.response?.data || err.message);
    res.status(500).json({
      error: err.response?.data?.message || "Failed to verify PAN",
      details: err.response?.data || err.message,
    });
  }
});

// ---------------------------------------------
// 11. Bank Account Verification
// ---------------------------------------------
app.get('/api/kyc/verify-bank-account/:ifsc_code/:account_number', async (req, res) => {
  const { ifsc_code, account_number } = req.params;

  if (!ifsc_code || !account_number) {
    return res.status(400).json({ error: 'Missing mandatory fields for bank account verification.' });
  }

  try {
    // The Sandbox API endpoint for penniless verification is a GET request
    const response = await axios.get(
      `https://api.sandbox.co.in/bank/${ifsc_code}/accounts/${account_number}/penniless-verify`,
      {
        headers: {
          authorization: process.env.SANDBOX_AUTH_TOKEN,
          'x-api-key': process.env.SANDBOX_API_KEY,
          'x-api-version': '1.0',
          'Content-Type': 'application/json',
        },
      }
    );

    // The API response indicates if the account exists
    const accountExists = response.data.data.account_exists;
    const nameAtBank = response.data.data.name_at_bank;

    if (accountExists) {
      res.status(200).json({ message: 'Bank account verified successfully.', name_at_bank: nameAtBank });
    } else {
      res.status(400).json({ error: 'Bank account verification failed. The account does not exist.' });
    }
  } catch (err) {
    console.error('❌ Error verifying bank account:', err.response?.data || err.message);
    res.status(500).json({
      error: err.response?.data?.message || 'Failed to verify bank account.',
      details: err.response?.data || err.message,
    });
  }
});

// ---------------------------------------------
// 8. Start server
// ---------------------------------------------
app.listen(port, () => {
  console.log(`🚀 Backend running in ${process.env.NODE_ENV} mode on port ${port}`);
});
