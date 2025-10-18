-- ===========================================
-- SAMPLE DATA FOR IOT DASHBOARD
-- ===========================================
-- Creates 3 users (1 admin, 2 regular), 2 projects, 7 devices with assignments

-- ===========================================
-- 1. CREATE SAMPLE USERS IN AUTH.USERS
-- ===========================================

DO $$
DECLARE
  admin_user_id UUID := '11111111-1111-1111-1111-111111111111';
  user1_id UUID := '22222222-2222-2222-2222-222222222222';
  user2_id UUID := '33333333-3333-3333-3333-333333333333';
BEGIN
  -- Insert admin user into auth.users
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    admin_user_id,
    'authenticated',
    'authenticated',
    'admin@iot.local',
    crypt('admin123', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"display_name":"Admin User"}',
    now(),
    now(),
    '',
    ''
  ) ON CONFLICT (id) DO NOTHING;

  -- Insert regular user 1 into auth.users
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    user1_id,
    'authenticated',
    'authenticated',
    'user1@iot.local',
    crypt('user123', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"display_name":"John Smith"}',
    now(),
    now(),
    '',
    ''
  ) ON CONFLICT (id) DO NOTHING;

  -- Insert regular user 2 into auth.users
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    user2_id,
    'authenticated',
    'authenticated',
    'user2@iot.local',
    crypt('user123', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"display_name":"Jane Doe"}',
    now(),
    now(),
    '',
    ''
  ) ON CONFLICT (id) DO NOTHING;

  -- ===========================================
  -- 2. CREATE USER PROFILES
  -- ===========================================

  INSERT INTO user_profiles (user_id, email, display_name, role, created_at, updated_at)
  VALUES 
    (
      admin_user_id,
      'admin@iot.local',
      'Admin User',
      'admin',
      now() - interval '60 days',
      now()
    ),
    (
      user1_id,
      'user1@iot.local',
      'John Smith',
      'regular',
      now() - interval '45 days',
      now()
    ),
    (
      user2_id,
      'user2@iot.local',
      'Jane Doe',
      'beta',
      now() - interval '30 days',
      now()
    )
  ON CONFLICT (user_id) DO UPDATE 
  SET email = EXCLUDED.email, 
      display_name = EXCLUDED.display_name, 
      role = EXCLUDED.role;

  -- ===========================================
  -- 3. INSERT PROJECTS (owned by admin)
  -- ===========================================

  INSERT INTO projects (project_id, project_name, project_type, ml_enabled, custom_fields, realtime_fields, user_id, created_at)
  VALUES 
    (
      'WP01', 
      'Water Tank System', 
      'water_pump', 
      true,
      '[
        {"name": "tank_shape", "type": "select", "label": "Tank Shape", "required": true, "options": ["rectangular", "cylindrical", "spherical"]},
        {"name": "height_cm", "type": "number", "label": "Height (cm)", "required": true},
        {"name": "width_cm", "type": "number", "label": "Width (cm)", "required": false},
        {"name": "length_cm", "type": "number", "label": "Length (cm)", "required": false},
        {"name": "radius_cm", "type": "number", "label": "Radius (cm)", "required": false},
        {"name": "material", "type": "text", "label": "Tank Material", "required": false},
        {"name": "capacity_liters", "type": "number", "label": "Capacity (L)", "required": false}
      ]'::jsonb,
      '[
        {"name": "pump_lower_threshold", "type": "number", "label": "Pump Lower Threshold (%)", "default": "15"},
        {"name": "pump_upper_threshold", "type": "number", "label": "Pump Upper Threshold (%)", "default": "95"},
        {"name": "manual_switch", "type": "checkbox", "label": "Manual Pump Override", "default": "false"},
        {"name": "max_flow_in", "type": "number", "label": "Max Flow In (L/min)", "default": "10"},
        {"name": "max_flow_out", "type": "number", "label": "Max Flow Out (L/min)", "default": "5"}
      ]'::jsonb,
      admin_user_id,
      now() - interval '30 days'
    ),
    (
      'SL01', 
      'Smart Light System', 
      'smart_light', 
      false,
      '[
        {"name": "max_brightness", "type": "number", "label": "Max Brightness (%)", "required": true},
        {"name": "color_support", "type": "checkbox", "label": "Color Support", "required": true},
        {"name": "location", "type": "text", "label": "Location", "required": false},
        {"name": "wattage", "type": "number", "label": "Wattage (W)", "required": false}
      ]'::jsonb,
      '[
        {"name": "brightness_level", "type": "number", "label": "Brightness Level (%)", "default": "50"},
        {"name": "auto_mode", "type": "checkbox", "label": "Auto Mode", "default": "true"},
        {"name": "color_temperature", "type": "number", "label": "Color Temperature (K)", "default": "3000"}
      ]'::jsonb,
      admin_user_id,
      now() - interval '20 days'
    )
  ON CONFLICT (project_id) DO NOTHING;

  -- ===========================================
  -- 4. INSERT DEVICES FOR WATER TANK SYSTEM
  -- ===========================================

  INSERT INTO devices (device_id, project_id, role, auto_update, custom_data, is_registered, first_connected_at, updated_at)
  VALUES 
    (
      'DEV-WP01-001', 
      'WP01', 
      'regular', 
      true,
      '{"tank_shape": "rectangular", "height_cm": 200, "width_cm": 150, "length_cm": 150, "material": "stainless steel", "capacity_liters": 4500}'::jsonb,
      true,
      now() - interval '25 days',
      now() - interval '5 hours'
    ),
    (
      'DEV-WP01-002', 
      'WP01', 
      'beta', 
      true,
      '{"tank_shape": "cylindrical", "height_cm": 250, "radius_cm": 80, "material": "plastic", "capacity_liters": 5000}'::jsonb,
      true,
      now() - interval '20 days',
      now() - interval '3 hours'
    ),
    (
      'DEV-WP01-003', 
      'WP01', 
      'regular', 
      false,
      '{"tank_shape": "rectangular", "height_cm": 180, "width_cm": 120, "length_cm": 120, "material": "concrete", "capacity_liters": 2600}'::jsonb,
      true,
      now() - interval '18 days',
      now() - interval '7 hours'
    ),
    (
      'DEV-WP01-004', 
      'WP01', 
      'regular', 
      true,
      '{"tank_shape": "cylindrical", "height_cm": 300, "radius_cm": 100, "material": "fiberglass", "capacity_liters": 9400}'::jsonb,
      true,
      now() - interval '15 days',
      now() - interval '2 hours'
    )
  ON CONFLICT (device_id) DO NOTHING;

  -- ===========================================
  -- 5. INSERT DEVICES FOR SMART LIGHT SYSTEM
  -- ===========================================

  INSERT INTO devices (device_id, project_id, role, auto_update, custom_data, is_registered, first_connected_at, updated_at)
  VALUES 
    (
      'DEV-SL01-001', 
      'SL01', 
      'regular', 
      true,
      '{"max_brightness": 100, "color_support": true, "location": "Living Room", "wattage": 12}'::jsonb,
      true,
      now() - interval '19 days',
      now() - interval '4 hours'
    ),
    (
      'DEV-SL01-002', 
      'SL01', 
      'beta', 
      true,
      '{"max_brightness": 80, "color_support": false, "location": "Kitchen", "wattage": 9}'::jsonb,
      true,
      now() - interval '17 days',
      now() - interval '6 hours'
    ),
    (
      'DEV-SL01-003', 
      'SL01', 
      'regular', 
      false,
      '{"max_brightness": 100, "color_support": true, "location": "Bedroom", "wattage": 15}'::jsonb,
      true,
      now() - interval '14 days',
      now() - interval '1 hour'
    )
  ON CONFLICT (device_id) DO NOTHING;

  -- ===========================================
  -- 6. ASSIGN DEVICES TO USERS
  -- ===========================================
  
  -- Admin gets all devices
  INSERT INTO device_users (device_id, user_id, assigned_at)
  VALUES 
    ('DEV-WP01-001', admin_user_id, now() - interval '25 days'),
    ('DEV-WP01-002', admin_user_id, now() - interval '20 days'),
    ('DEV-WP01-003', admin_user_id, now() - interval '18 days'),
    ('DEV-WP01-004', admin_user_id, now() - interval '15 days'),
    ('DEV-SL01-001', admin_user_id, now() - interval '19 days'),
    ('DEV-SL01-002', admin_user_id, now() - interval '17 days'),
    ('DEV-SL01-003', admin_user_id, now() - interval '14 days')
  ON CONFLICT (device_id, user_id) DO NOTHING;

  -- User 1 (John) gets WP devices 1, 2 and SL device 1
  INSERT INTO device_users (device_id, user_id, assigned_at)
  VALUES 
    ('DEV-WP01-001', user1_id, now() - interval '24 days'),
    ('DEV-WP01-002', user1_id, now() - interval '19 days'),
    ('DEV-SL01-001', user1_id, now() - interval '18 days')
  ON CONFLICT (device_id, user_id) DO NOTHING;

  -- User 2 (Jane) gets WP devices 3, 4 and SL devices 2, 3
  INSERT INTO device_users (device_id, user_id, assigned_at)
  VALUES 
    ('DEV-WP01-003', user2_id, now() - interval '17 days'),
    ('DEV-WP01-004', user2_id, now() - interval '14 days'),
    ('DEV-SL01-002', user2_id, now() - interval '16 days'),
    ('DEV-SL01-003', user2_id, now() - interval '13 days')
  ON CONFLICT (device_id, user_id) DO NOTHING;

  -- Shared device: DEV-WP01-002 is also assigned to User 2
  INSERT INTO device_users (device_id, user_id, assigned_at)
  VALUES 
    ('DEV-WP01-002', user2_id, now() - interval '10 days')
  ON CONFLICT (device_id, user_id) DO NOTHING;

  -- ===========================================
  -- 7. INSERT REALTIME DATA FOR ALL DEVICES
  -- ===========================================

  INSERT INTO realtime_data (device_id, project_id, data, updated_at)
  VALUES 
    (
      'DEV-WP01-001', 
      'WP01',
      '{"pump_lower_threshold": 15, "pump_upper_threshold": 95, "manual_switch": false, "max_flow_in": 10, "max_flow_out": 5}'::jsonb,
      now() - interval '1 hour'
    ),
    (
      'DEV-WP01-002', 
      'WP01',
      '{"pump_lower_threshold": 20, "pump_upper_threshold": 90, "manual_switch": false, "max_flow_in": 12, "max_flow_out": 6}'::jsonb,
      now() - interval '2 hours'
    ),
    (
      'DEV-WP01-003', 
      'WP01',
      '{"pump_lower_threshold": 10, "pump_upper_threshold": 95, "manual_switch": true, "max_flow_in": 8, "max_flow_out": 4}'::jsonb,
      now() - interval '30 minutes'
    ),
    (
      'DEV-WP01-004', 
      'WP01',
      '{"pump_lower_threshold": 15, "pump_upper_threshold": 92, "manual_switch": false, "max_flow_in": 15, "max_flow_out": 7}'::jsonb,
      now() - interval '45 minutes'
    ),
    (
      'DEV-SL01-001', 
      'SL01',
      '{"brightness_level": 75, "auto_mode": true, "color_temperature": 3200}'::jsonb,
      now() - interval '20 minutes'
    ),
    (
      'DEV-SL01-002', 
      'SL01',
      '{"brightness_level": 50, "auto_mode": false, "color_temperature": 2700}'::jsonb,
      now() - interval '35 minutes'
    ),
    (
      'DEV-SL01-003', 
      'SL01',
      '{"brightness_level": 100, "auto_mode": true, "color_temperature": 4000}'::jsonb,
      now() - interval '10 minutes'
    )
  ON CONFLICT DO NOTHING;

END $$;

-- ===========================================
-- 8. INSERT WATER PUMP TELEMETRY DATA
-- ===========================================

INSERT INTO wp_samples (project_id, device_id, ts_utc, level_pct, pump_on, flow_out_lpm, flow_in_lpm, net_flow_lpm)
SELECT 
  'WP01',
  device_id,
  now() - (interval '1 hour' * hour_offset),
  LEAST(100, GREATEST(0, ROUND((50 + 
    CASE 
      WHEN pump_on THEN (random() * 40)
      ELSE -(random() * 30)
    END
  )::numeric, 2))),
  pump_on,
  ROUND((random() * 5 + 2)::numeric, 2),
  CASE 
    WHEN pump_on THEN ROUND((random() * 8 + 7)::numeric, 2)
    ELSE 0
  END,
  CASE 
    WHEN pump_on THEN ROUND((random() * 8 + 7 - random() * 5 - 2)::numeric, 2)
    ELSE ROUND((-(random() * 5 + 2))::numeric, 2)
  END
FROM (
  SELECT 
    device_id,
    hour_offset,
    (random() > 0.4)::boolean as pump_on
  FROM (
    SELECT device_id FROM (
      VALUES ('DEV-WP01-001'), ('DEV-WP01-002'), ('DEV-WP01-003'), ('DEV-WP01-004')
    ) AS d(device_id)
  ) devices
  CROSS JOIN generate_series(0, 119) AS hour_offset
) data;

-- ===========================================
-- 9. INSERT SMART LIGHT TELEMETRY DATA
-- ===========================================

INSERT INTO sl_samples (project_id, device_id, ts_utc, brightness, power_w, color_temp)
SELECT 
  'SL01',
  device_id,
  now() - (interval '1 hour' * hour_offset),
  (30 + random() * 70)::integer,
  ROUND((5 + random() * 15)::numeric, 2),
  (2700 + (random() * 3800)::integer)
FROM (
  SELECT device_id FROM (
    VALUES ('DEV-SL01-001'), ('DEV-SL01-002'), ('DEV-SL01-003')
  ) AS d(device_id)
) devices
CROSS JOIN generate_series(0, 119) AS hour_offset;

-- ===========================================
-- 10. INSERT SAMPLE FIRMWARE VERSIONS
-- ===========================================

INSERT INTO firmware (version, filename, sha256, size_bytes, uploaded_at, file_path)
VALUES
  (
    'v1.0.0',
    'esp32_firmware_v1.0.0.bin',
    'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2',
    524288,
    now() - interval '30 days',
    '/firmware/esp32_firmware_v1.0.0.bin'
  ),
  (
    'v1.1.0',
    'esp32_firmware_v1.1.0.bin',
    'b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3',
    548864,
    now() - interval '15 days',
    '/firmware/esp32_firmware_v1.1.0.bin'
  ),
  (
    'v1.2.0',
    'esp32_firmware_v1.2.0.bin',
    'c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4',
    573440,
    now() - interval '5 days',
    '/firmware/esp32_firmware_v1.2.0.bin'
  )
ON CONFLICT DO NOTHING;