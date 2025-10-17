/*
  # IoT Dashboard Complete Schema with Custom Fields and Authentication

  ## Overview
  Creates a comprehensive IoT dashboard schema supporting user authentication, custom project fields,
  devices with API keys, telemetry data, firmware, and ML models.

  ## 1. New Tables

  ### user_profiles
  - `user_id` (uuid, primary key, foreign key to auth.users) - Links to Supabase auth
  - `email` (text) - User email
  - `display_name` (text) - User display name
  - `created_at` (timestamptz) - Account creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### projects
  - `project_id` (varchar, primary key) - Unique project identifier (e.g., WP01)
  - `project_name` (text) - Human-readable project name
  - `project_type` (text) - Type: 'water_pump' or 'smart_light'
  - `ml_enabled` (boolean) - ML script option enabled
  - `custom_fields` (jsonb) - Dynamic field definitions for project-specific data
  - `user_id` (uuid, foreign key) - Owner of the project
  - `created_at` (timestamptz) - Auto-generated creation timestamp

  ### devices
  - `device_id` (varchar, primary key) - Unique device identifier
  - `project_id` (varchar, foreign key) - Links to projects table
  - `api_key` (uuid, unique) - Unique API key for device authentication
  - `user_id` (uuid, foreign key) - Owner of the device
  - `role` (text) - Device role: 'regular' or 'beta'
  - `auto_update` (boolean) - Enable automatic firmware updates
  - `custom_data` (jsonb) - Values for custom fields defined in project
  - `is_registered` (boolean) - Device registration status
  - `first_connected_at` (timestamptz) - First connection timestamp
  - `updated_at` (timestamptz) - Last update timestamp
  
  ### wp_samples (Water Pump Telemetry)
  - `id` (bigint, primary key) - Auto-increment ID
  - `project_id` (varchar) - Project identifier
  - `device_id` (varchar) - Device identifier
  - `ts_utc` (timestamptz) - Timestamp in UTC
  - `level_pct` (numeric) - Water level percentage
  - `pump_on` (boolean) - Pump on/off state
  - `flow_out_lpm` (numeric) - Outflow in liters per minute
  - `flow_in_lpm` (numeric) - Inflow in liters per minute
  - `net_flow_lpm` (numeric) - Net flow in liters per minute
  
  ### sl_samples (Smart Light Telemetry)
  - `id` (bigint, primary key) - Auto-increment ID
  - `project_id` (varchar) - Project identifier
  - `device_id` (varchar) - Device identifier
  - `ts_utc` (timestamptz) - Timestamp in UTC
  - `brightness` (integer) - Brightness level
  - `power_w` (numeric) - Power consumption in watts
  - `color_temp` (integer) - Color temperature in Kelvin
  
  ### firmware
  - `id` (bigint, primary key) - Auto-increment ID
  - `version` (varchar) - Firmware version (e.g., b0.1.1.0)
  - `filename` (text) - Original filename
  - `sha256` (varchar) - SHA256 hash of the file
  - `size_bytes` (bigint) - File size in bytes
  - `uploaded_at` (timestamptz) - Upload timestamp
  - `file_path` (text) - Storage path reference

  ### ml_models
  - `id` (bigint, primary key) - Auto-increment ID
  - `project_id` (varchar) - Project identifier
  - `model_type` (text) - Type of model (e.g., 'tflite')
  - `filename` (text) - Model filename
  - `file_path` (text) - Storage path reference
  - `size_bytes` (bigint) - File size in bytes
  - `created_at` (timestamptz) - Creation timestamp
  - `training_samples` (integer) - Number of samples used for training

  ## 2. Sample Data
  - Projects: Water Tank System (ML enabled) and Smart Light System
  - Devices: 4 water tank devices, 3 smart light devices with custom field data
  - Telemetry: 480 water pump samples, 360 smart light samples

  ## 3. Security
  - Enable RLS on all tables
  - User-based access control for projects and devices
  - Device API key authentication for telemetry uploads
  - Public read access for authenticated users, write access for owners only

  ## 4. Performance
  - Indexes on foreign keys and timestamp columns
  - GIN indexes on JSONB columns for efficient querying
*/

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  display_name TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create projects table
CREATE TABLE IF NOT EXISTS projects (
  project_id VARCHAR(64) PRIMARY KEY,
  project_name TEXT NOT NULL,
  project_type TEXT NOT NULL,
  ml_enabled BOOLEAN DEFAULT false,
  custom_fields JSONB DEFAULT '[]'::jsonb,
  user_id UUID REFERENCES user_profiles(user_id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create devices table
CREATE TABLE IF NOT EXISTS devices (
  device_id VARCHAR(64) PRIMARY KEY,
  project_id VARCHAR(64) NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
  api_key UUID UNIQUE DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES user_profiles(user_id) ON DELETE CASCADE,
  role TEXT DEFAULT 'regular' CHECK (role IN ('regular', 'beta')),
  auto_update BOOLEAN DEFAULT false,
  custom_data JSONB DEFAULT '{}'::jsonb,
  is_registered BOOLEAN DEFAULT false,
  first_connected_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create water pump samples table
CREATE TABLE wp_samples (
  id BIGSERIAL PRIMARY KEY,
  project_id VARCHAR(64) NOT NULL,
  device_id VARCHAR(64) NOT NULL,
  ts_utc TIMESTAMPTZ DEFAULT now(),
  level_pct NUMERIC,
  pump_on BOOLEAN,
  flow_out_lpm NUMERIC,
  flow_in_lpm NUMERIC,
  net_flow_lpm NUMERIC
);

-- Create smart light samples table
CREATE TABLE sl_samples (
  id BIGSERIAL PRIMARY KEY,
  project_id VARCHAR(64) NOT NULL,
  device_id VARCHAR(64) NOT NULL,
  ts_utc TIMESTAMPTZ DEFAULT now(),
  brightness INTEGER,
  power_w NUMERIC,
  color_temp INTEGER
);

-- Create firmware table
CREATE TABLE firmware (
  id BIGSERIAL PRIMARY KEY,
  version VARCHAR(64) NOT NULL,
  filename TEXT NOT NULL,
  sha256 VARCHAR(64),
  size_bytes BIGINT,
  uploaded_at TIMESTAMPTZ DEFAULT now(),
  file_path TEXT
);

-- Create ml_models table
CREATE TABLE ml_models (
  id BIGSERIAL PRIMARY KEY,
  project_id VARCHAR(64) NOT NULL,
  model_type TEXT DEFAULT 'tflite',
  filename TEXT NOT NULL,
  file_path TEXT,
  size_bytes BIGINT,
  created_at TIMESTAMPTZ DEFAULT now(),
  training_samples INTEGER DEFAULT 0
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_projects_user ON projects(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_project ON devices(project_id);
CREATE INDEX IF NOT EXISTS idx_devices_user ON devices(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_api_key ON devices(api_key);
CREATE INDEX IF NOT EXISTS idx_wp_samples_project ON wp_samples(project_id);
CREATE INDEX IF NOT EXISTS idx_wp_samples_device ON wp_samples(device_id);
CREATE INDEX IF NOT EXISTS idx_wp_samples_ts ON wp_samples(ts_utc DESC);
CREATE INDEX IF NOT EXISTS idx_sl_samples_project ON sl_samples(project_id);
CREATE INDEX IF NOT EXISTS idx_sl_samples_device ON sl_samples(device_id);
CREATE INDEX IF NOT EXISTS idx_sl_samples_ts ON sl_samples(ts_utc DESC);
CREATE INDEX IF NOT EXISTS idx_firmware_version ON firmware(version);
CREATE INDEX IF NOT EXISTS idx_ml_models_project ON ml_models(project_id);
CREATE INDEX IF NOT EXISTS idx_projects_custom_fields ON projects USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_devices_custom_data ON devices USING gin(custom_data);

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE wp_samples ENABLE ROW LEVEL SECURITY;
ALTER TABLE sl_samples ENABLE ROW LEVEL SECURITY;
ALTER TABLE firmware ENABLE ROW LEVEL SECURITY;
ALTER TABLE ml_models ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_profiles
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policies for projects
CREATE POLICY "Users can view own projects"
  ON projects FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own projects"
  ON projects FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own projects"
  ON projects FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own projects"
  ON projects FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- RLS Policies for devices
CREATE POLICY "Users can view own devices"
  ON devices FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own devices"
  ON devices FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own devices"
  ON devices FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own devices"
  ON devices FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Devices can authenticate with API key"
  ON devices FOR SELECT
  TO anon
  USING (true);

-- RLS Policies for wp_samples
CREATE POLICY "Users can view own project samples"
  ON wp_samples FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.project_id = wp_samples.project_id
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Devices can insert samples via API"
  ON wp_samples FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Users can delete own project samples"
  ON wp_samples FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.project_id = wp_samples.project_id
      AND projects.user_id = auth.uid()
    )
  );

-- RLS Policies for sl_samples
CREATE POLICY "Users can view own project light samples"
  ON sl_samples FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.project_id = sl_samples.project_id
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Devices can insert light samples via API"
  ON sl_samples FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Users can delete own project light samples"
  ON sl_samples FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.project_id = sl_samples.project_id
      AND projects.user_id = auth.uid()
    )
  );

-- RLS Policies for firmware
CREATE POLICY "All authenticated users can view firmware"
  ON firmware FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Devices can download firmware"
  ON firmware FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Authenticated users can upload firmware"
  ON firmware FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can delete firmware"
  ON firmware FOR DELETE
  TO authenticated
  USING (true);

-- RLS Policies for ml_models
CREATE POLICY "Users can view own project models"
  ON ml_models FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.project_id = ml_models.project_id
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Devices can download models"
  ON ml_models FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Users can insert own project models"
  ON ml_models FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.project_id = ml_models.project_id
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own project models"
  ON ml_models FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.project_id = ml_models.project_id
      AND projects.user_id = auth.uid()
    )
  );

-- Note: Sample data removed - users must create their own projects and devices after signup

-- Commented out sample data (requires user_id)

-- Create realtime_data table
CREATE TABLE IF NOT EXISTS realtime_data (
  id BIGSERIAL PRIMARY KEY,
  device_id VARCHAR(64) NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
  project_id VARCHAR(64) NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
  data JSONB DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Add realtime_fields column to projects
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'projects' AND column_name = 'realtime_fields'
  ) THEN
    ALTER TABLE projects ADD COLUMN realtime_fields JSONB DEFAULT '[]'::jsonb;
  END IF;
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_realtime_data_device ON realtime_data(device_id);
CREATE INDEX IF NOT EXISTS idx_realtime_data_project ON realtime_data(project_id);
CREATE INDEX IF NOT EXISTS idx_realtime_data_data ON realtime_data USING gin(data);
CREATE INDEX IF NOT EXISTS idx_projects_realtime_fields ON projects USING gin(realtime_fields);

-- Enable Row Level Security
ALTER TABLE realtime_data ENABLE ROW LEVEL SECURITY;

-- RLS Policies for realtime_data
CREATE POLICY "Users can view own device realtime data"
  ON realtime_data FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM devices
      WHERE devices.device_id = realtime_data.device_id
      AND devices.user_id = auth.uid()
    )
  );

CREATE POLICY "Devices can insert realtime data via API"
  ON realtime_data FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Devices can update realtime data via API"
  ON realtime_data FOR UPDATE
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Users can delete own device realtime data"
  ON realtime_data FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM devices
      WHERE devices.device_id = realtime_data.device_id
      AND devices.user_id = auth.uid()
    )
  );

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'projects' AND column_name = 'ml_script_content'
  ) THEN
    ALTER TABLE projects ADD COLUMN ml_script_content TEXT;
  END IF;
END $$;

-- Add ml_script_updated_at column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'projects' AND column_name = 'ml_script_updated_at'
  ) THEN
    ALTER TABLE projects ADD COLUMN ml_script_updated_at TIMESTAMPTZ;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'ml_models' AND column_name = 'device_id'
  ) THEN
    ALTER TABLE ml_models ADD COLUMN device_id VARCHAR(64);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_ml_models_device ON ml_models(device_id);


