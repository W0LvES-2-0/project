-- Sample Data SQL for IoT Dashboard
-- This creates sample users, projects, devices, and device assignments

-- STEP 1: Create auth users first (do this manually or via Supabase Dashboard)
-- After creating auth users, note their UUIDs and replace in the queries below

-- STEP 2: Create user profiles
-- Replace the UUIDs below with actual auth.users IDs from Step 1

-- Example structure (update with your actual user IDs):
-- Admin user
INSERT INTO user_profiles (user_id, email, display_name, role) VALUES
  ('00000000-0000-0000-0000-000000000001'::uuid, 'admin@iot.local', 'Admin User', 'admin');

-- Regular and Beta users
INSERT INTO user_profiles (user_id, email, display_name, role) VALUES
  ('00000000-0000-0000-0000-000000000002'::uuid, 'user1@iot.local', 'User One', 'regular'),
  ('00000000-0000-0000-0000-000000000003'::uuid, 'user2@iot.local', 'User Two', 'beta');

-- STEP 3: Create sample projects (admin-owned)
INSERT INTO projects (project_id, project_name, project_type, ml_enabled, custom_fields, user_id) VALUES
  ('WP01', 'Water Tank System', 'water_pump', true,
   '[
      {"name": "tank_shape", "type": "select", "label": "Tank Shape", "required": true, "options": ["rectangular", "cylindrical", "spherical"]},
      {"name": "height_cm", "type": "number", "label": "Height (cm)", "required": true},
      {"name": "width_cm", "type": "number", "label": "Width (cm)", "required": false},
      {"name": "length_cm", "type": "number", "label": "Length (cm)", "required": false},
      {"name": "radius_cm", "type": "number", "label": "Radius (cm)", "required": false},
      {"name": "material", "type": "text", "label": "Tank Material", "required": false},
      {"name": "capacity_liters", "type": "number", "label": "Capacity (L)", "required": false}
    ]'::jsonb,
   '00000000-0000-0000-0000-000000000001'::uuid),
  ('SL01', 'Smart Light System', 'smart_light', false,
   '[
      {"name": "max_brightness", "type": "number", "label": "Max Brightness (%)", "required": true},
      {"name": "color_support", "type": "checkbox", "label": "Color Support", "required": true},
      {"name": "location", "type": "text", "label": "Location", "required": false},
      {"name": "wattage", "type": "number", "label": "Wattage (W)", "required": false}
    ]'::jsonb,
   '00000000-0000-0000-0000-000000000001'::uuid);

-- STEP 4: Create 7 devices with unique API keys
INSERT INTO devices (device_id, project_id, role, custom_data, is_registered) VALUES
  ('DEV-001', 'WP01', 'regular', '{"tank_shape": "rectangular", "height_cm": 200, "width_cm": 150, "length_cm": 150, "material": "stainless steel", "capacity_liters": 4500}'::jsonb, true),
  ('DEV-002', 'WP01', 'beta', '{"tank_shape": "cylindrical", "height_cm": 250, "radius_cm": 80, "material": "plastic", "capacity_liters": 5000}'::jsonb, true),
  ('DEV-003', 'WP01', 'regular', '{"tank_shape": "rectangular", "height_cm": 180, "width_cm": 120, "length_cm": 120, "material": "concrete", "capacity_liters": 2600}'::jsonb, true),
  ('DEV-004', 'SL01', 'regular', '{"max_brightness": 100, "color_support": true, "location": "Living Room", "wattage": 12}'::jsonb, true),
  ('DEV-005', 'SL01', 'beta', '{"max_brightness": 80, "color_support": false, "location": "Kitchen", "wattage": 9}'::jsonb, true),
  ('DEV-006', 'SL01', 'regular', '{"max_brightness": 100, "color_support": true, "location": "Bedroom", "wattage": 15}'::jsonb, true),
  ('DEV-007', 'WP01', 'regular', '{"tank_shape": "cylindrical", "height_cm": 300, "radius_cm": 100, "material": "fiberglass", "capacity_liters": 9400}'::jsonb, true);

-- STEP 5: Assign devices to users (multiple users can share devices)
INSERT INTO device_users (device_id, user_id) VALUES
  -- User 1 has access to DEV-001, DEV-002, DEV-005, DEV-006
  ('DEV-001', '00000000-0000-0000-0000-000000000002'::uuid),
  ('DEV-002', '00000000-0000-0000-0000-000000000002'::uuid),
  ('DEV-005', '00000000-0000-0000-0000-000000000002'::uuid),
  ('DEV-006', '00000000-0000-0000-0000-000000000002'::uuid),

  -- User 2 has access to DEV-003, DEV-004, DEV-005 (shared), DEV-007
  ('DEV-003', '00000000-0000-0000-0000-000000000003'::uuid),
  ('DEV-004', '00000000-0000-0000-0000-000000000003'::uuid),
  ('DEV-005', '00000000-0000-0000-0000-000000000003'::uuid),
  ('DEV-007', '00000000-0000-0000-0000-000000000003'::uuid);

-- STEP 6: Query to get device API keys (admin use only)
-- SELECT device_id, api_key FROM devices ORDER BY device_id;

-- Notes:
-- 1. Device DEV-005 is shared between User 1 and User 2
-- 2. Each device has a unique auto-generated API key (UUID)
-- 3. API keys should be hardcoded in ESP32 firmware
-- 4. Users with 'regular' or 'beta' roles can only see their assigned devices
-- 5. Admin can see and manage everything
