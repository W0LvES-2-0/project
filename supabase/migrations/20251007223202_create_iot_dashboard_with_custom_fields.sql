/*
  # IoT Dashboard Complete Schema (Clean Version)

  Supports user authentication, project/device management, telemetry data, firmware, and ML models.
  Includes RLS policies and optimized indexes for performance.

  --- COMPATIBLE WITH SUPABASE 2025 ---
*/

-- ===========================
-- 1. USER PROFILES
-- ===========================
CREATE TABLE IF NOT EXISTS user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  display_name TEXT,
  role TEXT DEFAULT 'regular' CHECK (role IN ('admin', 'regular', 'beta')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ===========================
-- 2. PROJECTS
-- ===========================
CREATE TABLE IF NOT EXISTS projects (
  project_id VARCHAR(64) PRIMARY KEY,
  project_name TEXT NOT NULL,
  project_type TEXT NOT NULL,
  ml_enabled BOOLEAN DEFAULT false,
  custom_fields JSONB DEFAULT '[]'::jsonb,
  realtime_fields JSONB DEFAULT '{}'::jsonb, -- added safely for GIN index
  user_id UUID REFERENCES user_profiles(user_id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ===========================
-- 3. DEVICES
-- ===========================
CREATE TABLE IF NOT EXISTS devices (
  device_id VARCHAR(64) PRIMARY KEY,
  project_id VARCHAR(64) NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
  api_key UUID UNIQUE DEFAULT gen_random_uuid(),
  role TEXT DEFAULT 'regular' CHECK (role IN ('regular', 'beta')),
  auto_update BOOLEAN DEFAULT false,
  custom_data JSONB DEFAULT '{}'::jsonb,
  is_registered BOOLEAN DEFAULT false,
  first_connected_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ===========================
-- 4. DEVICE-USER RELATION
-- ===========================
CREATE TABLE IF NOT EXISTS device_users (
  device_id VARCHAR(64) NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
  assigned_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (device_id, user_id)
);

-- ===========================
-- 5. TELEMETRY: WATER PUMP
-- ===========================
CREATE TABLE IF NOT EXISTS wp_samples (
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

-- ===========================
-- 6. TELEMETRY: SMART LIGHT
-- ===========================
CREATE TABLE IF NOT EXISTS sl_samples (
  id BIGSERIAL PRIMARY KEY,
  project_id VARCHAR(64) NOT NULL,
  device_id VARCHAR(64) NOT NULL,
  ts_utc TIMESTAMPTZ DEFAULT now(),
  brightness INTEGER,
  power_w NUMERIC,
  color_temp INTEGER
);

-- ===========================
-- 7. FIRMWARE
-- ===========================
CREATE TABLE IF NOT EXISTS firmware (
  id BIGSERIAL PRIMARY KEY,
  version VARCHAR(64) NOT NULL,
  filename TEXT NOT NULL,
  sha256 VARCHAR(64),
  size_bytes BIGINT,
  uploaded_at TIMESTAMPTZ DEFAULT now(),
  file_path TEXT
);

-- ===========================
-- 8. ML MODELS
-- ===========================
CREATE TABLE IF NOT EXISTS ml_models (
  id BIGSERIAL PRIMARY KEY,
  project_id VARCHAR(64) NOT NULL,
  device_id VARCHAR(64),
  model_type TEXT DEFAULT 'tflite',
  filename TEXT NOT NULL,
  file_path TEXT,
  size_bytes BIGINT,
  created_at TIMESTAMPTZ DEFAULT now(),
  training_samples INTEGER DEFAULT 0
);

-- ===========================
-- 9. REALTIME DATA
-- ===========================
CREATE TABLE IF NOT EXISTS realtime_data (
  id BIGSERIAL PRIMARY KEY,
  device_id VARCHAR(64) NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
  project_id VARCHAR(64) NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
  data JSONB DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ===========================
-- 10. INDEXES
-- ===========================
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_projects_user ON projects(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_project ON devices(project_id);
CREATE INDEX IF NOT EXISTS idx_devices_api_key ON devices(api_key);
CREATE INDEX IF NOT EXISTS idx_device_users_device ON device_users(device_id);
CREATE INDEX IF NOT EXISTS idx_device_users_user ON device_users(user_id);
CREATE INDEX IF NOT EXISTS idx_wp_samples_project ON wp_samples(project_id);
CREATE INDEX IF NOT EXISTS idx_wp_samples_device ON wp_samples(device_id);
CREATE INDEX IF NOT EXISTS idx_wp_samples_ts ON wp_samples(ts_utc DESC);
CREATE INDEX IF NOT EXISTS idx_sl_samples_project ON sl_samples(project_id);
CREATE INDEX IF NOT EXISTS idx_sl_samples_device ON sl_samples(device_id);
CREATE INDEX IF NOT EXISTS idx_sl_samples_ts ON sl_samples(ts_utc DESC);
CREATE INDEX IF NOT EXISTS idx_firmware_version ON firmware(version);
CREATE INDEX IF NOT EXISTS idx_ml_models_project ON ml_models(project_id);
CREATE INDEX IF NOT EXISTS idx_ml_models_device ON ml_models(device_id);
CREATE INDEX IF NOT EXISTS idx_projects_custom_fields ON projects USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_projects_realtime_fields ON projects USING gin(realtime_fields);
CREATE INDEX IF NOT EXISTS idx_devices_custom_data ON devices USING gin(custom_data);
CREATE INDEX IF NOT EXISTS idx_realtime_data_device ON realtime_data(device_id);
CREATE INDEX IF NOT EXISTS idx_realtime_data_project ON realtime_data(project_id);
CREATE INDEX IF NOT EXISTS idx_realtime_data_data ON realtime_data USING gin(data);

-- ===========================
-- 11. ENABLE RLS
-- ===========================
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE wp_samples ENABLE ROW LEVEL SECURITY;
ALTER TABLE sl_samples ENABLE ROW LEVEL SECURITY;
ALTER TABLE firmware ENABLE ROW LEVEL SECURITY;
ALTER TABLE ml_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE realtime_data ENABLE ROW LEVEL SECURITY;

-- ===========================
-- 12. RLS POLICIES (CLEAN)
-- ===========================

-- USER PROFILES
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- PROJECTS
CREATE POLICY "Users can view projects"
  ON projects FOR SELECT TO authenticated
  USING (
    user_id = auth.uid() OR EXISTS (
      SELECT 1 FROM device_users du
      JOIN devices d ON du.device_id = d.device_id
      WHERE d.project_id = projects.project_id AND du.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert projects"
  ON projects FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own projects"
  ON projects FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own projects"
  ON projects FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- DEVICES
CREATE POLICY "Users can view assigned devices"
  ON devices FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM device_users WHERE device_users.device_id = devices.device_id AND device_users.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert devices"
  ON devices FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM projects WHERE projects.project_id = devices.project_id AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update devices"
  ON devices FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM projects WHERE projects.project_id = devices.project_id AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete devices"
  ON devices FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM projects WHERE projects.project_id = devices.project_id AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Devices can authenticate with API key"
  ON devices FOR SELECT TO anon USING (true);

-- DEVICE USERS
CREATE POLICY "Users can view device assignments"
  ON device_users FOR SELECT TO authenticated
  USING (
    user_id = auth.uid() OR EXISTS (
      SELECT 1 FROM devices d
      JOIN projects p ON d.project_id = p.project_id
      WHERE d.device_id = device_users.device_id AND p.user_id = auth.uid()
    )
  );

CREATE POLICY "Project owners can assign devices"
  ON device_users FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM devices d
      JOIN projects p ON d.project_id = p.project_id
      WHERE d.device_id = device_users.device_id AND p.user_id = auth.uid()
    )
  );

CREATE POLICY "Project owners can remove device assignments"
  ON device_users FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM devices d
      JOIN projects p ON d.project_id = p.project_id
      WHERE d.device_id = device_users.device_id AND p.user_id = auth.uid()
    )
  );

-- WP SAMPLES
CREATE POLICY "Users can view assigned device samples"
  ON wp_samples FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM device_users WHERE device_users.device_id = wp_samples.device_id AND device_users.user_id = auth.uid()
    )
  );

CREATE POLICY "Devices can insert samples via API"
  ON wp_samples FOR INSERT TO anon, authenticated WITH CHECK (true);

-- SL SAMPLES
CREATE POLICY "Users can view assigned light samples"
  ON sl_samples FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM device_users WHERE device_users.device_id = sl_samples.device_id AND device_users.user_id = auth.uid()
    )
  );

CREATE POLICY "Devices can insert light samples via API"
  ON sl_samples FOR INSERT TO anon, authenticated WITH CHECK (true);

-- FIRMWARE
CREATE POLICY "Anyone can view firmware"
  ON firmware FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Authenticated can upload firmware"
  ON firmware FOR INSERT TO authenticated WITH CHECK (true);

-- ML MODELS
CREATE POLICY "Users can view models for assigned devices"
  ON ml_models FOR SELECT TO authenticated
  USING (
    device_id IS NULL OR
    EXISTS (
      SELECT 1 FROM device_users WHERE device_users.device_id = ml_models.device_id AND device_users.user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM projects WHERE projects.project_id = ml_models.project_id AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Devices can fetch ML models"
  ON ml_models FOR SELECT TO anon USING (true);

-- REALTIME DATA
CREATE POLICY "Users can view assigned device realtime data"
  ON realtime_data FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM device_users WHERE device_users.device_id = realtime_data.device_id AND device_users.user_id = auth.uid()
    )
  );

CREATE POLICY "Devices can insert realtime data"
  ON realtime_data FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY "Devices can update realtime data"
  ON realtime_data FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
