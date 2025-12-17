-- ============================================
-- SANCTUARY DATABASE SCHEMA
-- Supabase PostgreSQL
-- ============================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";  -- For advanced location queries

-- ============================================
-- PROFILES TABLE
-- Core user information
-- ============================================
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_number TEXT UNIQUE,
    display_name TEXT NOT NULL,
    avatar_url TEXT,
    emergency_message TEXT DEFAULT 'I need help. This is an emergency.',
    is_monitoring_enabled BOOLEAN DEFAULT FALSE,
    check_in_interval_minutes INTEGER DEFAULT 30,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Profiles policies: Users can only access their own profile
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- ============================================
-- CONTACT RELATIONS TABLE
-- Links trusted contacts to users
-- ============================================
CREATE TABLE contact_relations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    trusted_contact_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    relation_type TEXT NOT NULL CHECK (relation_type IN ('emergency', 'partner', 'friend', 'family')),
    is_active BOOLEAN DEFAULT TRUE,
    can_view_location BOOLEAN DEFAULT TRUE,
    can_receive_alerts BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Prevent duplicate relationships
    UNIQUE(user_id, trusted_contact_id)
);

-- Enable RLS
ALTER TABLE contact_relations ENABLE ROW LEVEL SECURITY;

-- Contact relations policies
CREATE POLICY "Users can view their contact relations"
    ON contact_relations FOR SELECT
    USING (auth.uid() = user_id OR auth.uid() = trusted_contact_id);

CREATE POLICY "Users can insert their contact relations"
    ON contact_relations FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their contact relations"
    ON contact_relations FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their contact relations"
    ON contact_relations FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- CONSENT AGREEMENTS TABLE
-- Stores boundary agreements between partners
-- ============================================
CREATE TABLE agreements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    initiator_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    partner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'expired', 'revoked')),
    boundaries JSONB NOT NULL DEFAULT '[]',
    -- boundaries format: [{"category": "photos", "consent": true, "note": "..."}, ...]
    expires_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    revoked_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Prevent duplicate active agreements between same pair
    UNIQUE(initiator_id, partner_id)
);

-- Enable RLS
ALTER TABLE agreements ENABLE ROW LEVEL SECURITY;

-- Agreements policies: Both parties can view, only initiator can create, either can revoke
CREATE POLICY "Parties can view their agreements"
    ON agreements FOR SELECT
    USING (auth.uid() = initiator_id OR auth.uid() = partner_id);

CREATE POLICY "Users can create agreements as initiator"
    ON agreements FOR INSERT
    WITH CHECK (auth.uid() = initiator_id);

CREATE POLICY "Parties can update their agreements"
    ON agreements FOR UPDATE
    USING (auth.uid() = initiator_id OR auth.uid() = partner_id)
    WITH CHECK (auth.uid() = initiator_id OR auth.uid() = partner_id);

-- ============================================
-- SAFETY ALERTS TABLE
-- Real-time panic/emergency broadcasts
-- ============================================
CREATE TABLE safety_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    alert_type TEXT NOT NULL CHECK (alert_type IN ('panic', 'dead_man_switch', 'check_in_missed', 'manual')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'false_alarm', 'escalated')),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    accuracy_meters DOUBLE PRECISION,
    altitude DOUBLE PRECISION,
    speed DOUBLE PRECISION,
    heading DOUBLE PRECISION,
    battery_level DOUBLE PRECISION,
    custom_message TEXT,
    location_history JSONB DEFAULT '[]',
    -- location_history format: [{"lat": x, "lng": y, "timestamp": "...", "accuracy": z}, ...]
    escalated_to_911 BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Enable RLS
ALTER TABLE safety_alerts ENABLE ROW LEVEL SECURITY;

-- Safety alerts policies
-- Users can see their own alerts
CREATE POLICY "Users can view own alerts"
    ON safety_alerts FOR SELECT
    USING (auth.uid() = user_id);

-- Trusted contacts can view alerts for users they're connected to
CREATE POLICY "Trusted contacts can view alerts"
    ON safety_alerts FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM contact_relations
            WHERE contact_relations.user_id = safety_alerts.user_id
            AND contact_relations.trusted_contact_id = auth.uid()
            AND contact_relations.is_active = TRUE
            AND contact_relations.can_receive_alerts = TRUE
        )
    );

CREATE POLICY "Users can create own alerts"
    ON safety_alerts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own alerts"
    ON safety_alerts FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- LOCATION UPDATES TABLE (for continuous tracking)
-- High-frequency location data during active monitoring
-- ============================================
CREATE TABLE location_updates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_id UUID REFERENCES safety_alerts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy_meters DOUBLE PRECISION,
    altitude DOUBLE PRECISION,
    speed DOUBLE PRECISION,
    heading DOUBLE PRECISION,
    battery_level DOUBLE PRECISION,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Enable RLS
ALTER TABLE location_updates ENABLE ROW LEVEL SECURITY;

-- Location updates policies (same as safety_alerts)
CREATE POLICY "Users can view own location updates"
    ON location_updates FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Trusted contacts can view location updates"
    ON location_updates FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM contact_relations
            WHERE contact_relations.user_id = location_updates.user_id
            AND contact_relations.trusted_contact_id = auth.uid()
            AND contact_relations.is_active = TRUE
            AND contact_relations.can_view_location = TRUE
        )
    );

CREATE POLICY "Users can insert own location updates"
    ON location_updates FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- LINKING CODES TABLE
-- For QR-based partner linking
-- ============================================
CREATE TABLE linking_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    code TEXT NOT NULL UNIQUE,
    purpose TEXT NOT NULL CHECK (purpose IN ('partner_link', 'emergency_contact')),
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,
    used_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Enable RLS
ALTER TABLE linking_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own linking codes"
    ON linking_codes FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own linking codes"
    ON linking_codes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Anyone authenticated can use a linking code"
    ON linking_codes FOR UPDATE
    USING (used_at IS NULL AND expires_at > NOW())
    WITH CHECK (auth.uid() = used_by);

-- ============================================
-- ENABLE REALTIME FOR SAFETY ALERTS
-- Critical for live location sharing
-- ============================================
ALTER PUBLICATION supabase_realtime ADD TABLE safety_alerts;
ALTER PUBLICATION supabase_realtime ADD TABLE location_updates;

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX idx_safety_alerts_user_status ON safety_alerts(user_id, status);
CREATE INDEX idx_safety_alerts_created_at ON safety_alerts(created_at DESC);
CREATE INDEX idx_location_updates_alert ON location_updates(alert_id, created_at DESC);
CREATE INDEX idx_contact_relations_user ON contact_relations(user_id, is_active);
CREATE INDEX idx_contact_relations_contact ON contact_relations(trusted_contact_id, is_active);
CREATE INDEX idx_agreements_parties ON agreements(initiator_id, partner_id, status);
CREATE INDEX idx_linking_codes_code ON linking_codes(code) WHERE used_at IS NULL;

-- ============================================
-- UPDATED_AT TRIGGERS
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contact_relations_updated_at
    BEFORE UPDATE ON contact_relations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_agreements_updated_at
    BEFORE UPDATE ON agreements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_safety_alerts_updated_at
    BEFORE UPDATE ON safety_alerts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- FUNCTIONS FOR COMMON OPERATIONS
-- ============================================

-- Function to get active trusted contacts for a user
CREATE OR REPLACE FUNCTION get_trusted_contacts(target_user_id UUID)
RETURNS TABLE (
    contact_id UUID,
    display_name TEXT,
    phone_number TEXT,
    relation_type TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.display_name,
        p.phone_number,
        cr.relation_type
    FROM contact_relations cr
    JOIN profiles p ON p.id = cr.trusted_contact_id
    WHERE cr.user_id = target_user_id
    AND cr.is_active = TRUE
    AND cr.can_receive_alerts = TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
