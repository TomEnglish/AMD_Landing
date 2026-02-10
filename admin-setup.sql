-- ============================================
-- AMD Insight — Admin Access Setup
-- Run this in Supabase SQL Editor AFTER the initial supabase-setup.sql
-- ============================================

-- Allow authenticated users to read submissions (for review)
CREATE POLICY "Authenticated can read submissions"
ON submissions FOR SELECT
TO authenticated
USING (true);

-- Allow authenticated users to delete submissions (after approval/rejection)
CREATE POLICY "Authenticated can delete submissions"
ON submissions FOR DELETE
TO authenticated
USING (true);

-- Allow authenticated users to insert resources (approve submissions)
CREATE POLICY "Authenticated can insert resources"
ON resources FOR INSERT
TO authenticated
WITH CHECK (true);

-- Allow authenticated users to update resources
CREATE POLICY "Authenticated can update resources"
ON resources FOR UPDATE
TO authenticated
USING (true);

-- Allow authenticated users to delete resources
CREATE POLICY "Authenticated can delete resources"
ON resources FOR DELETE
TO authenticated
USING (true);
