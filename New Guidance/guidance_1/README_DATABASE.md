# PostgreSQL Database Connection Setup

This Flutter app uses an HTTP-based approach to connect to a PostgreSQL database through a backend API.

## Backend Setup

To set up the backend API, you can use any backend framework like Node.js with Express, Python with Flask, or any other backend technology. Below is an example using Node.js with Express:

### 1. Create a Node.js Backend

1. Create a new directory for your backend:
```bash
mkdir guidance-backend
cd guidance-backend
```

2. Initialize a new Node.js project:
```bash
npm init -y
```

3. Install required dependencies:
```bash
npm install express pg cors
```

4. Create a `server.js` file:
```javascript
const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');

const app = express();
const port = 3000;

// Enable CORS
app.use(cors());
app.use(express.json());

// PostgreSQL connection pool
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'guidance_db',
  password: 'your_password',
  port: 5432,
});

// Test database connection
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('Database connection error:', err.stack);
  } else {
    console.log('Database connected successfully');
  }
});

// API endpoints
// Get all students
app.get('/api/students', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM students');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Add a new student
app.post('/api/students', async (req, res) => {
  try {
    const { name, email } = req.body;
    const result = await pool.query(
      'INSERT INTO students (name, email) VALUES ($1, $2) RETURNING *',
      [name, email]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Start the server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
```

5. Run the backend server:
```bash
node server.js
```

### 2. Database Setup

Create a PostgreSQL database and table:

```sql
CREATE DATABASE guidance_db;

CREATE TABLE students (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 3. Flutter App Integration

The Flutter app uses the `ApiService` class to communicate with the backend API:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  
  final http.Client _client = http.Client();
  
  // Get all students
  Future<List<dynamic>> getAllStudents() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/students'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load students: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching students: $e');
    }
  }
  
  // Add a new student
  Future<bool> addStudent(String name, String email) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/students'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
        }),
      );
      
      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Error adding student: $e');
    }
  }
  
  // Close the HTTP client
  void dispose() {
    _client.close();
  }
}
```

### 4. Usage in Flutter Widgets

The `AnswerableForms` widget demonstrates how to use the API service:

```dart
class _AnswerableFormsState extends State<AnswerableForms> {
  final ApiService _apiService = ApiService();
  List<dynamic> _students = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load students from the API
      final students = await _apiService.getAllStudents();
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading students: $e')),
      );
    }
  }
  
  // ... rest of the widget code
}
```

## Security Considerations

For production use, consider implementing:

1. Authentication and authorization
2. HTTPS for secure communication
3. Input validation and sanitization
4. Rate limiting
5. Proper error handling
6. Environment variables for sensitive data
