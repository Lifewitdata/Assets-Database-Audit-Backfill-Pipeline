PRAGMA foreign_keys=ON;
CREATE TABLE IF NOT EXISTS sources (
 source_id TEXT PRIMARY KEY, url TEXT NOT NULL, sha256 TEXT NOT NULL, publisher_notes TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS records (
 record_id TEXT PRIMARY KEY, source_id TEXT NOT NULL REFERENCES sources(source_id),
 source_row INTEGER NOT NULL, bbl TEXT NOT NULL, neighborhood TEXT NOT NULL,
 address TEXT, building_class TEXT NOT NULL, sale_date TEXT NOT NULL,
 sale_price REAL, gross_square_feet REAL, residential_units INTEGER,
 UNIQUE(source_id,source_row)
);
CREATE TABLE IF NOT EXISTS evidence (
 record_id TEXT NOT NULL REFERENCES records(record_id), field TEXT NOT NULL,
 source_value TEXT, source_id TEXT NOT NULL REFERENCES sources(source_id), source_row INTEGER NOT NULL,
 PRIMARY KEY(record_id,field)
);
CREATE TABLE IF NOT EXISTS proposals (
 proposal_id TEXT PRIMARY KEY, record_id TEXT NOT NULL REFERENCES records(record_id),
 field TEXT NOT NULL CHECK(field IN ('address','sale_price','gross_square_feet','residential_units')),
 proposed_value TEXT, evidence_source TEXT, evidence_row INTEGER,
 status TEXT NOT NULL DEFAULT 'PENDING' CHECK(status IN ('PENDING','APPLIED','REJECTED')),
 reason TEXT, created_by TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS audit_log (
 audit_id INTEGER PRIMARY KEY, proposal_id TEXT NOT NULL UNIQUE REFERENCES proposals(proposal_id),
 record_id TEXT NOT NULL, field TEXT NOT NULL, old_value TEXT, new_value TEXT NOT NULL,
 evidence_source TEXT NOT NULL, evidence_row INTEGER NOT NULL,
 reviewer TEXT NOT NULL, applied_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_records_neighborhood ON records(neighborhood,building_class);
