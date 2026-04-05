-- Clear existing tables for a clean re-import
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS users;
SET FOREIGN_KEY_CHECKS = 1;

-- Users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL, -- Hashed password using bcrypt
    role ENUM('admin', 'staff') DEFAULT 'staff',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Products table
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    sku VARCHAR(50) NOT NULL UNIQUE,
    barcode VARCHAR(100) UNIQUE, -- New field
    quantity INT DEFAULT 0,
    price DECIMAL(10, 2) NOT NULL,
    low_stock_threshold INT DEFAULT 5, -- New field
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (quantity >= 0)
) ENGINE=InnoDB;

-- Transactions table
CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    user_id INT NOT NULL,
    type ENUM('IN', 'OUT') NOT NULL,
    quantity INT NOT NULL,
    reason VARCHAR(255), -- New field for stock adjustment
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- Sample users (Passwords are 'admin123' and 'staff123' respectively)
-- Using plain text passwords for easier testing
INSERT INTO users (username, email, password, role) VALUES 
('admin', 'admin@example.com', 'admin123', 'admin'),
('staff', 'staff@example.com', 'staff123', 'staff')
ON DUPLICATE KEY UPDATE username=VALUES(username);

-- Sample products
INSERT INTO products (name, description, sku, barcode, quantity, price, low_stock_threshold) VALUES 
('Office Chair', 'Ergonomic office chair with lumbar support', 'CHR-001', '1234567890', 15, 149.99, 5),
('Mechanical Keyboard', 'RGB backlight mechanical keyboard', 'KBD-001', '0987654321', 4, 89.50, 5), -- Low stock
('Monitor Mount', 'Dual monitor arm mount', 'MNT-001', '1122334455', 10, 55.00, 3)
ON DUPLICATE KEY UPDATE name=VALUES(name);
