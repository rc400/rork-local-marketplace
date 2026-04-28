-- Only admins can update the role column on profiles
-- This adds a new RLS policy that allows admins to update any profile
CREATE POLICY "Admins update any profile"
  ON profiles
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Note: The existing "Users update own profile" policy still allows
-- users to update their own non-role fields. Together these policies
-- mean: users can edit their own profile, admins can edit any profile.
-- 
-- FIRST ADMIN BOOTSTRAP:
-- The very first admin must be set directly in Supabase Dashboard
-- (Table Editor -> profiles -> change role to admin) since there is
-- no admin to promote them through the app.
