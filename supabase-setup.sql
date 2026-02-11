-- ============================================
-- AMD Insight — Supabase Database Setup
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor → New query)
-- ============================================

-- 1. Create resources table
CREATE TABLE IF NOT EXISTS resources (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    description text NOT NULL,
    url text,
    category text NOT NULL,
    evidence_level text NOT NULL,
    votes integer DEFAULT 0,
    clicks integer DEFAULT 0,
    submitted_by text,
    approved boolean DEFAULT false,
    created_at timestamptz DEFAULT now()
);

-- 2. Create submissions table (moderation queue)
CREATE TABLE IF NOT EXISTS submissions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    description text NOT NULL,
    url text,
    category text NOT NULL,
    evidence_level text NOT NULL,
    submitted_by text,
    submitted_ip text,
    created_at timestamptz DEFAULT now()
);

-- 3. Create user_profiles table for admin role management
CREATE TABLE IF NOT EXISTS user_profiles (
    id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email text,
    is_admin boolean DEFAULT false,
    created_at timestamptz DEFAULT now()
);

-- 4. Create vote_tracking table for server-side vote tracking
CREATE TABLE IF NOT EXISTS vote_tracking (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id uuid REFERENCES resources(id) ON DELETE CASCADE,
    voter_hash text NOT NULL,
    created_at timestamptz DEFAULT now(),
    UNIQUE(resource_id, voter_hash)
);

-- 5. Enable Row Level Security
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vote_tracking ENABLE ROW LEVEL SECURITY;

-- 6. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_resources_category ON resources(category);
CREATE INDEX IF NOT EXISTS idx_resources_evidence ON resources(evidence_level);
CREATE INDEX IF NOT EXISTS idx_resources_approved ON resources(approved);
CREATE INDEX IF NOT EXISTS idx_resources_created ON resources(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_submissions_created ON submissions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_submissions_ip ON submissions(submitted_ip);
CREATE INDEX IF NOT EXISTS idx_vote_tracking_resource ON vote_tracking(resource_id);
CREATE INDEX IF NOT EXISTS idx_vote_tracking_hash ON vote_tracking(voter_hash);

-- 7. RLS Policies
-- Anyone can read approved resources
CREATE POLICY "Public can read approved resources"
ON resources FOR SELECT
USING (approved = true);

-- Anyone can submit
CREATE POLICY "Public can submit"
ON submissions FOR INSERT
WITH CHECK (true);

-- Users can read their own profile
CREATE POLICY "Users can read own profile"
ON user_profiles FOR SELECT
USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
ON user_profiles FOR INSERT
WITH CHECK (auth.uid() = id);

-- Vote tracking: allow inserts with proper voter_hash
CREATE POLICY "Public can track votes"
ON vote_tracking FOR INSERT
WITH CHECK (true);

-- 8. RPC Functions for atomic vote/click increments
CREATE OR REPLACE FUNCTION increment_vote(resource_id uuid)
RETURNS void AS $$
BEGIN
    UPDATE resources SET votes = votes + 1 WHERE id = resource_id AND approved = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION increment_click(resource_id uuid)
RETURNS void AS $$
BEGIN
    UPDATE resources SET clicks = clicks + 1 WHERE id = resource_id AND approved = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. RPC Function for submitting resources with rate limiting
CREATE OR REPLACE FUNCTION submit_resource(
    p_title text,
    p_description text,
    p_url text,
    p_category text,
    p_evidence_level text,
    p_submitted_by text DEFAULT NULL
)
RETURNS json AS $$
DECLARE
    v_ip text;
    v_recent_count integer;
BEGIN
    -- Get client IP (requires Supabase to pass X-Forwarded-For header)
    v_ip := current_setting('request.headers', true)::json->>'x-forwarded-for';
    
    -- Rate limit: max 5 submissions per IP per hour
    SELECT COUNT(*) INTO v_recent_count
    FROM submissions
    WHERE submitted_ip = v_ip
    AND created_at > NOW() - INTERVAL '1 hour';
    
    IF v_recent_count >= 5 THEN
        RETURN json_build_object('success', false, 'error', 'Rate limit exceeded. Please try again later.');
    END IF;
    
    -- Insert submission
    INSERT INTO submissions (title, description, url, category, evidence_level, submitted_by, submitted_ip)
    VALUES (p_title, p_description, p_url, p_category, p_evidence_level, p_submitted_by, v_ip);
    
    RETURN json_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. RPC Function for voting with duplicate prevention
CREATE OR REPLACE FUNCTION cast_vote(
    p_resource_id uuid,
    p_voter_hash text
)
RETURNS json AS $$
DECLARE
    v_exists boolean;
BEGIN
    -- Check if already voted
    SELECT EXISTS(SELECT 1 FROM vote_tracking WHERE resource_id = p_resource_id AND voter_hash = p_voter_hash)
    INTO v_exists;
    
    IF v_exists THEN
        RETURN json_build_object('success', false, 'error', 'Already voted');
    END IF;
    
    -- Record the vote
    INSERT INTO vote_tracking (resource_id, voter_hash)
    VALUES (p_resource_id, p_voter_hash);
    
    -- Increment vote count
    UPDATE resources SET votes = votes + 1 WHERE id = p_resource_id AND approved = true;
    
    RETURN json_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. RPC Function to check if user is admin
CREATE OR REPLACE FUNCTION is_user_admin()
RETURNS boolean AS $$
DECLARE
    v_is_admin boolean;
BEGIN
    SELECT is_admin INTO v_is_admin
    FROM user_profiles
    WHERE id = auth.uid();
    
    RETURN COALESCE(v_is_admin, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. View for resources with calculated trending score
CREATE OR REPLACE VIEW resources_with_score AS
SELECT *,
    (votes * 3 + clicks +
     CASE WHEN created_at > NOW() - INTERVAL '7 days' THEN 20
          WHEN created_at > NOW() - INTERVAL '30 days' THEN 10
          ELSE 0 END) as trending_score
FROM resources
WHERE approved = true;

-- 13. Trigger to create user profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO user_profiles (id, email, is_admin)
    VALUES (NEW.id, NEW.email, false);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 14. Seed data — 19 interventions from the book
INSERT INTO resources (title, description, url, category, evidence_level, votes, clicks, approved) VALUES
('Photobiomodulation (Red Light Therapy)', 'Near-infrared and red light therapy stimulates mitochondrial function in retinal cells. LIGHTSITE III trial showed significant improvement in visual acuity for dry AMD patients.', 'https://pubmed.ncbi.nlm.nih.gov/38227884', 'light_therapy', 'clinical_trials', 12, 8, true),

('AREDS2 Formula', 'The Age-Related Eye Disease Study 2 formula (lutein, zeaxanthin, zinc, vitamins C and E, copper) reduced progression to advanced AMD by ~25% in at-risk patients.', 'https://pubmed.ncbi.nlm.nih.gov/23644932', 'supplement', 'clinical_trials', 15, 10, true),

('DHA / Omega-3 Supplementation', 'DHA is the most abundant fatty acid in the retina. Marine-derived omega-3s support retinal cell membrane integrity and reduce inflammatory signaling.', 'https://pubmed.ncbi.nlm.nih.gov/18541848', 'supplement', 'peer_reviewed', 9, 6, true),

('NAD+ Precursors (NMN/NR)', 'Nicotinamide and NAD+ precursors rescue mitochondrial function in AMD cell models. Support cellular energy production in metabolically stressed retinal tissue.', 'https://pubmed.ncbi.nlm.nih.gov/28132833', 'supplement', 'peer_reviewed', 7, 5, true),

('Astaxanthin', 'A powerful carotenoid antioxidant that crosses the blood-retinal barrier. Protects photoreceptors from oxidative damage and blue light stress.', NULL, 'supplement', 'peer_reviewed', 6, 3, true),

('Resveratrol', 'Polyphenol shown to improve visual function in octogenarians with AMD. Acts as a sirtuin activator and anti-inflammatory agent in retinal tissue.', 'https://pubmed.ncbi.nlm.nih.gov/23736827', 'supplement', 'peer_reviewed', 5, 4, true),

('Buteyko / Nasal Breathing', 'Functional breathing techniques that increase CO2 tolerance and improve oxygen delivery to tissues via the Bohr effect. May enhance retinal blood flow.', NULL, 'breathing', 'emerging', 4, 2, true),

('Sauna / Heat Therapy', 'Regular sauna use reduces blood viscosity and improves vascular function. Heat exposure stimulates erythropoietin production and may enhance retinal oxygenation.', 'https://pubmed.ncbi.nlm.nih.gov/3741077', 'lifestyle', 'peer_reviewed', 5, 3, true),

('Senolytics (Dasatinib + Quercetin)', 'Senolytic drugs clear senescent cells that accumulate in aging retinal tissue. D+Q shown to alleviate lipofuscin-dependent retinal degeneration in preclinical models.', NULL, 'anti_aging', 'emerging', 3, 2, true),

('GLP-1 Receptor Agonists', 'Originally developed for diabetes, GLP-1 RAs show a 43% reduced risk of neovascular AMD in observational studies. Mechanism may involve metabolic and anti-inflammatory effects.', 'https://pubmed.ncbi.nlm.nih.gov/39863057', 'anti_aging', 'emerging', 4, 3, true),

('Melatonin', 'Retinal melatonin levels decline with age. Supplementation associated with reduced AMD risk in large cohort studies. Acts as mitochondrial antioxidant.', 'https://pubmed.ncbi.nlm.nih.gov/38842832', 'supplement', 'peer_reviewed', 6, 4, true),

('Mediterranean Diet', 'Dietary pattern rich in omega-3s, vegetables, and low in processed seed oils. Consistently associated with lower AMD risk in epidemiological studies.', NULL, 'diet', 'clinical_trials', 8, 5, true),

('Blue Light Filtering', 'Reducing blue light exposure from screens and LED lighting may decrease photooxidative stress on the retina, particularly when dietary DHA is inadequate.', 'https://pubmed.ncbi.nlm.nih.gov/28769003', 'device', 'peer_reviewed', 5, 4, true),

('TA-65 (Telomerase Activator)', 'Cycloastragenol-based supplement shown to improve visual acuity in early AMD patients in a pilot study. Works by activating telomerase in retinal cells.', 'https://pubmed.ncbi.nlm.nih.gov/26869760', 'anti_aging', 'emerging', 3, 2, true),

('Benfotiamine (Vitamin B1)', 'Fat-soluble form of thiamine that blocks hyperglycemic damage pathways. Prevents diabetic retinopathy in animal models and supports CO2 production via PDH enzyme.', 'https://pubmed.ncbi.nlm.nih.gov/12592403', 'supplement', 'peer_reviewed', 4, 2, true),

('Vigorous Exercise', 'Meta-analysis shows regular physical activity reduces AMD risk. Exercise improves blood flow, mobilizes stem cells, and reduces systemic inflammation.', 'https://pubmed.ncbi.nlm.nih.gov/28549846', 'lifestyle', 'clinical_trials', 10, 7, true),

('Fasting / Time-Restricted Eating', 'Prolonged fasting promotes autophagy and stem cell regeneration. May clear damaged cellular components in retinal tissue and reduce metabolic stress.', 'https://pubmed.ncbi.nlm.nih.gov/24905167', 'lifestyle', 'emerging', 4, 3, true),

('Lutein + Zeaxanthin', 'Macular pigment carotenoids that filter blue light and provide antioxidant protection. Part of the AREDS2 formula. Higher macular pigment density correlates with lower AMD risk.', 'https://pubmed.ncbi.nlm.nih.gov/26541886', 'supplement', 'clinical_trials', 11, 6, true),

('Vitamin K2 (MK-7)', 'Directs calcium away from soft tissues (including Bruch''s membrane) and into bones. May prevent vascular calcification that contributes to choroidal blood flow impairment.', 'https://pubmed.ncbi.nlm.nih.gov/23375872', 'supplement', 'emerging', 3, 1, true)
ON CONFLICT DO NOTHING;
