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
    created_at timestamptz DEFAULT now()
);

-- 3. Enable Row Level Security
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
-- Anyone can read approved resources
CREATE POLICY "Public can read approved resources"
ON resources FOR SELECT
USING (approved = true);

-- Anyone can submit
CREATE POLICY "Public can submit"
ON submissions FOR INSERT
WITH CHECK (true);

-- 5. RPC Functions for atomic vote/click increments
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

-- 6. Seed data — 19 interventions from the book
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

('Vitamin K2 (MK-7)', 'Directs calcium away from soft tissues (including Bruch''s membrane) and into bones. May prevent vascular calcification that contributes to choroidal blood flow impairment.', 'https://pubmed.ncbi.nlm.nih.gov/23375872', 'supplement', 'emerging', 3, 1, true);
