-- SQLite schema for hostname aliases
-- This creates a table to store IP address to hostname mappings

CREATE TABLE IF NOT EXISTS aliases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ip TEXT NOT NULL UNIQUE,  -- IP address (e.g., 192.168.1.1)
    hostname TEXT NOT NULL,    -- Human-readable hostname (e.g., Gateway)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create an index on the IP address for faster lookups
CREATE INDEX IF NOT EXISTS idx_aliases_ip ON aliases(ip);

-- Insert some example data
INSERT OR IGNORE INTO aliases (ip, hostname) VALUES ('10.109.20.11', 'Gateway');
INSERT OR IGNORE INTO aliases (ip, hostname) VALUES ('10.109.20.12', 'WebServer');
INSERT OR IGNORE INTO aliases (ip, hostname) VALUES ('127.0.0.1', 'localhost');
INSERT OR IGNORE INTO aliases (ip, hostname) VALUES ('10.109.20.16', 'FileServer');
INSERT OR IGNORE INTO aliases (ip, hostname) VALUES ('10.109.21.11', 'DevWorkstation');
